# == Schema Information
#
# Table name: tournaments
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  size              :integer
#  type              :string(255)      default("SingleElimination")
#  title             :string(255)
#  place             :string(255)
#  detail            :text
#  created_at        :datetime
#  updated_at        :datetime
#  consolation_round :boolean          default(TRUE)
#  url               :string(255)
#  secondary_final   :boolean          default(FALSE)
#  scoreless         :boolean          default(FALSE)
#

class Tournament < ActiveRecord::Base
  acts_as_taggable

  belongs_to :user
  has_many :games, -> { order(bracket: :asc, round: :asc, match: :asc) }, dependent: :destroy
  has_many :players, -> { order(seed: :asc) }, dependent: :destroy

  accepts_nested_attributes_for :players
  accepts_nested_attributes_for :games

  validates_associated :games, on: :create
  validates_associated :players
  validates :user_id, presence: true
  validates :size, presence: true
  validate :tnmt_size_must_be_smaller_than_limit, on: :create
  validates :type, presence: true, inclusion: {in: ['SingleElimination', 'DoubleElimination']}
  validates :title, presence: true, length: {maximum: 100}, exclusion: {in: %w(index new edit players games)}
  validates :place, length: {maximum: 100}, allow_nil: true
  validates :detail, length: {maximum: 500}, allow_nil: true
  validates :url, format: URI::regexp(%w(http https)), allow_blank: true
  validates :consolation_round, presence: true, inclusion: {in: [true,false]}, allow_blank: true
  validates :secondary_final, presence: true, inclusion: {in: [true,false]}, allow_blank: true
  validates :scoreless, presence: true, inclusion: {in: [true,false]}, allow_blank: true

  def tnmt_size_must_be_smaller_than_limit
    errors.add(:size, "作成できるサイズ上限を越えています") unless self.user.creatable_sizes.has_value? size
  end

  default_scope {order(created_at: :desc)}
  scope :finished, -> { where(finished: true) }

  before_create :build_players, :build_winner_games, :build_third_place_game
  after_create :create_first_round_records
  after_save :upload_json, :upload_img

  def self.search_tournaments(params)
    if params[:q]
      tournaments = Tournament.where('title LIKE ? OR detail LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    elsif params[:tag]
      tournaments = Tournament.tagged_with(params[:tag])
    elsif params[:category]
      if params[:category] != 'others'
        tags = Category.where(category_name: params[:category]).map(&:tag_name)
        tournaments = Tournament.tagged_with(tags, any:true)
      else
        tags = Category.all.map(&:tag_name)
        tournaments = Tournament.tagged_with(tags, exclude:true)
      end
    else
      tournaments = Tournament.all
    end
    tournaments
  end

  def tournament_data
    teams = Array.new
    results = Array.new
    for i in 1..self.round_num
      round_res = Array.new  # create result array for each round
      results << round_res
      self.games.where(bracket: 1, round: i).each do |game|
        # Set team info
        teams << game.game_records.map{|r| (r.player.name.present?) ? r.player.name : '(BYE)'}.to_a  if i == 1

        # Set match Info
        res =  game.game_records.map{|r| r.score}.to_a
        # Bye Game
        if game.bye == true
          win_record = game.game_records.find_by(winner: true)
          if win_record.record_num == 1
            res[0] = 0.3
            res[1] = 0.2
          else
            res[0] = 0.2
            res[1] = 0.3
          end
        # Same Score Game
        elsif game.finished? && (game.game_records.first.score == game.game_records.last.score)
          win_record = game.game_records.find_by(winner: true)
          res[win_record.record_num-1] += 0.1
        # Unfinished Game
        elsif !game.finished?
          res[0] = res[1] = '--'
        end
        round_res << res
      end
    end
    tournament_data = {teams: teams, results: results}
  end

  def match_data
    match_data = Array.new
    match_data[1] = self.games.map{ |m| "#{self.round_name(bracket: m.bracket, round:m.round)} #{m.match_name}<br>#{m.game_records.map{|r| (r.player.name.present?) ? r.player.name : '(BYE)'}.join('-')}<br>#{m.comment}" }
    match_data
  end

  def build_players
    for i in 1..self.size do
      self.players.build(name: "Player#{i}", seed: i)
    end
  end

  def create_first_round_records
    self.games.where(bracket: 1, round: 1).each do |game|
      game_players = [
        self.players.find_by(seed: 2*(game.match)-1),
        self.players.find_by(seed: 2*(game.match))
      ]
      for i in 1..2
        game.game_records.create(player: game_players[i-1], record_num: i)
      end
    end
  end

  def round_num
    Math.log2(self.size).to_i  #=> return 3 rounds for 8 players (2**3=8)
  end

  def category
    self.tag_list.each do |tag|
      category = Category.find_by(tag_name: tag)
      return category if category.present?
    end
    return nil
  end

  def build_winner_games
    for i in 1..self.round_num do
      match_num = self.size / (2**i)
      match_num.times do |k|
        self.games.build(bracket:1, round:i, match:k+1)
      end
    end
  end

  def de?
    self.type == 'DoubleElimination'
  end

  def member_registered?
    self.players.first.name != 'Player1'
  end

  def result_registered?
    self.games.first.winner.present?
  end

  def encoded_title
    self.title.gsub(/　| |\//, '-')
  end

  def embed_url
    "https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/index.html?utm_campaign=embed&utm_medium=#{self.user.id.to_s}&utm_source=#{self.id.to_s}&width=100"
  end

  def embed_img_url
    "https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/image.html?utm_campaign=embed&utm_medium=#{self.user.id.to_s}&utm_source=#{self.id.to_s}&title=#{CGI.escape(self.title)}"
  end

  def to_json
    {
      title: self.title,
      tournament_data: self.tournament_data,
      skip_secondary_final: (self.de?) ? !self.secondary_final : false,
      skip_consolation_round: !self.consolation_round,
      countries: self.players.map{|p| p.country.try(:downcase)},
      match_data: self.match_data,
      scoreless: self.scoreless?
    }.to_json
  end

  def upload_json
    File.write("tmp/#{self.id}.json", self.to_json)
    src = File.join(Rails.root, "/tmp/#{self.id}.json")
    src_file = File.new(src)

    TournamentUploader.new.store!(src_file)
  end

  def upload_img
    if self.user.id == 835 || self.user.admin?
      File.open(File.join(Rails.root, "/tmp/#{self.id}.png"), 'wb') do |tmp|
        url = "https://the-tournament.jp/ja/tournaments/#{self.id}/raw"
        open("http://phantomjscloud.com/api/browser/v2/ak-b1hw7-66a8k-1wdyw-xhqh1-f2s4p/?request={url:%22#{url}%22,renderType:%22png%22}") do |f|
          f.each_line {|line| tmp.puts line}
        end
      end

      # Upload Image
      uploader = TournamentUploader.new
      src = File.join(Rails.root, "/tmp/#{self.id}.png")
      src_file = File.new(src)
      uploader.store!(src_file)
    end
  end

  def players_list
    if self.players
      players = self.players.pluck(:name)
    else
      players = []
      self.size.times do |i|
        players << "Player#{i}"
      end
    end
    players.join("\r\n")
  end
end
