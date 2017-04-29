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

  before_create :initialize_teams_and_results
  # after_save :upload_json, :upload_img

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

  def initialize_teams_and_results
    teams = []
    for i in 1..self.size do
      teams << {name: "Player#{i}"}
    end

    results = []
    for i in 1..self.round_num do
      match_count = [(self.size / 2**i), 2].max
      arr = []
      for i in 1..match_count do
        arr << {score: [nil, nil], winner: nil, comment: nil, bye: false, finished: false}
      end
      results << arr
    end

    self.teams = teams.to_json
    self.results = results.to_json
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

  def de?
    self.type == 'DoubleElimination'
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

  def jqb_teams
    teams = []
    self.teams.each_with_index do |team, i|
      teams << [] if i%2 == 0
      teams.last << team
    end
    teams
  end

  def jqb_scores
    scores = []
    self.results.each.with_index(1) do |round, round_num|
      # round << round.map{|m| m['score']}
      round_scores = []
      round.each.with_index(1) do |game, game_num|
        score = game['score']
        # 同点ゲームの場合
        if game['winner'] && score[0]==score[1]
          s = score[game['winner']].to_i
          score[game['winner']] = s + 0.1
        end

        # Tooltip用の試合情報をセット
        match_data = "#{self.round_name(round: round_num)}#{self.game_name(round:round_num, game:game_num)}　"
        match_data += "#{self.winner_team(round_num, game_num, 0)['name']} - #{self.winner_team(round_num, game_num, 1)['name']} "
        match_data += "#{game['comment']}"
        score << match_data

        round_scores << score
      end
      scores << round_scores
    end
    scores
  end

  def update_bye_games
    self.teams.each.with_index(1) do |team, i|
      next if team.present?

      round_num = 1
      game_num = i.quo(2).ceil
      winner_index = i%2  # #3(i=3, i%2==1)がbyeなら、winnerは#4なので、winner_indexは1になる

      result = {
        score: [nil, nil],
        winner: winner_index,
        comment: nil,
        finished: true
      }
      self.results[round_num - 1][game_num - 1] = result
    end
    self.update({results: self.results.to_json})
  end

  def to_json
    {
      title: self.title,
      tournament_data: { teams: self.jqb_teams, results: self.jqb_scores },
      skip_secondary_final: (self.de?) ? !self.secondary_final : false,
      skip_consolation_round: !self.consolation_round,
      scoreless: self.scoreless?
    }.to_json
  end

  def upload_json(json)
    file_path = File.join(Rails.root, "/tmp/#{self.id}.json")
    File.write(file_path, json)

    TournamentUploader.new.store!( File.new(file_path) ) if Rails.env.production?
  end

  def upload_img
    return if Rails.env.development?
    return if self.user.id != 835 && self.user.admin?

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

  # 1回戦第2試合は、round_num=1, game_num=2, team_index=0or1
  def winner_team(round_num, game_num, team_index)
    # 1回戦まで来たら対応する参加者名を返す
    return self.teams[2 * game_num - (2-team_index)] || {"name" => '--'} if round_num == 1

    # 2回戦以降の場合は下のラウンドの勝者に遡る
    target_round_num = round_num - 1
    target_game_num = (game_num * 2) - (1 - team_index)

    # 3位決定戦のときは準決勝の2試合がtarget_game
    consolation_round = (round_num == self.round_num) && (game_num == 2)
    target_game_num = 1 - team_index if consolation_round

    target_game = self.results[target_round_num - 1][target_game_num - 1]

    # 前の試合結果が確定していない場合は(TBD)
    if !target_game['finished']
      {"name" => "(TBD)"}
    # 勝者がいる場合はそのteamを返す（通常winのケースとbyeのケースを両方含む）
    elsif target_game['winner'].present?
      winner_index = target_game['winner']
      winner_index = 1 - winner_index if consolation_round # 3位決定戦の場合はloserを返す

      self.winner_team(target_round_num, target_game_num, winner_index)
    # finishedだけどwinnerがいないケース = double bye
    else
      {"name" => '--'}
    end
  end
end
