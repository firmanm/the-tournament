# == Schema Information
#
# Table name: tournaments
#
#  id                :integer          not null, primary key
#  user_id           :integer
#  size              :integer
#  title             :string(255)
#  place             :string(255)
#  detail            :text
#  created_at        :datetime
#  updated_at        :datetime
#  consolation_round :boolean          default(TRUE)
#  url               :string(255)
#  secondary_final   :boolean          default(FALSE)
#  scoreless         :boolean          default(FALSE)
#  finished          :boolean          default(FALSE)
#  facebook_album_id :string(255)
#  teams             :json
#  results           :json
#  token             :string(255)
#  double_mountain   :boolean          default(FALSE)
#  private           :boolean          default(FALSE)
#  name_width        :string(255)
#  score_width       :string(255)
#  no_ads            :boolean          default(FALSE)
#  profile_images    :boolean          default(FALSE)
#

class Tournament < ApplicationRecord
  acts_as_taggable

  belongs_to :user

  validates :user_id, presence: true
  validates :size, presence: true
  validate :tnmt_size_must_be_smaller_than_limit
  validate :teams_count_must_be_equal_to_tnmt_size, on: :update
  validate :not_allow_double_bye, on: :update, if: 'self.size.present?'
  validates :title, presence: true, length: {maximum: 100}, exclusion: {in: %w(index new edit players games)}
  validates :place, length: {maximum: 100}, allow_nil: true
  validates :detail, length: {maximum: 500}, allow_nil: true
  validates :url, format: URI::regexp(%w(http https)), allow_blank: true
  validates :consolation_round, inclusion: {in: [true,false]}, allow_blank: true
  validates :secondary_final, inclusion: {in: [true,false]}, allow_blank: true
  validates :scoreless, inclusion: {in: [true,false]}, allow_blank: true
  validates :double_mountain, inclusion: {in: [true,false]}, allow_blank: true
  validates :private, inclusion: {in: [true,false]}, allow_blank: true
  validates :name_width, numericality: {only_integer: true, greater_than_or_equal_to: 100}, allow_blank: true
  validates :score_width, numericality: {only_integer: true, greater_than_or_equal_to: 40}, allow_blank: true
  validates :no_ads, inclusion: {in: [true,false]}, allow_blank: true
  validates :profile_images, inclusion: {in: [true,false]}, allow_blank: true

  def tnmt_size_must_be_smaller_than_limit
    errors.add(:size, "作成できるサイズ上限を越えています") unless self.user.creatable_sizes.has_value? size
  end

  def teams_count_must_be_equal_to_tnmt_size
    errors[:base] << "参加者数がトーナメントのサイズと一致しないようです…。もう一度登録内容をご確認ください。" if teams.count != self.size
  end

  def not_allow_double_bye
    0.step(self.size-1, 2) do |i|
      errors[:base] << "二回戦シードはまだ未対応です。シード（空欄）同士が一回戦で当たらないように設定してください。" if teams[i].nil? && teams[i+1].nil?
    end
  end

  default_scope {order(created_at: :desc)}

  before_create :initialize_teams_and_results
  before_create :auto_tagging
  # after_save :upload_html if !Rails.env.development? && ENV['FOG_DIRECTORY'] != 'the-tournament-stg'  # 本番でのみ実行
  before_validation :change_tournament_size, if: '!self.new_record? && self.size.present? && self.size_changed?'

  def self.search_tournaments(params)
    if params[:q]
      tournaments = Tournament.where('title LIKE ? OR detail LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%")
    elsif params[:tag]
      tournaments = Tournament.tagged_with(params[:tag])
    else
      tournaments = Tournament.all
    end
    tournaments.where(private: false)
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

    self.teams = teams
    self.results = results
  end

  def round_num
    Math.log2(self.size).to_i  #=> return 3 rounds for 8 players (2**3=8)
  end

  def category
    self.tag_list.first
  end

  def encoded_title
    self.title.gsub(/　| |\//, '-')
  end

  def embed_html_url
    "https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/v3/#{self.id.to_s}.html?utm_campaign=embed&utm_medium=#{self.user.id.to_s}&utm_source=#{self.id.to_s}"
  end

  def embed_height
    self.size / 2 * 65 + 150
  end

  def match_info(round_num, game_num, game)
    match_data = "【"
    match_data += "#{self.round_name(round: round_num)}" if round_num != self.round_num   #決勝戦・3位決定戦はgame_nameのみ
    match_data += "#{self.game_name(round:round_num, game:game_num)}】　"
    match_data += "#{self.winner_team(round_num, game_num, 0)['name']} - #{self.winner_team(round_num, game_num, 1)['name']} "
    match_data += "#{game['comment']}"
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
    self.update({results: self.results})
  end

  def to_json
    {
      title: self.title,
      tournament_data: { teams: self.jqb_teams, results: self.jqb_scores },
      skip_secondary_final: false,
      skip_consolation_round: !self.consolation_round,
      scoreless: self.scoreless?
    }.to_json
  end

  def upload_html
    file_path = File.join(Rails.root, "/tmp/#{self.id}.html")
    html = ActionController::Base.new.render_to_string(partial: 'tournaments/embed', locals: { tournament: self })
    File.write(file_path, html)

    TournamentUploader.new.store!( File.new(file_path) )
  end

  # 1回戦第2試合は、round_num=1, game_num=2, team_index=0or1
  def winner_team(round_num, game_num, team_index)
    # 1回戦まで来たら対応する参加者名を返す
    if round_num == 1
      team_id = 2 * game_num - (2-team_index)
      team = self.teams[team_id] || {"name" => '--'}
      team['id'] = team_id + 1  # teamidは1スタート
      return team
    end

    # 2回戦以降の場合は下のラウンドの勝者に遡る
    target_round_num = round_num - 1
    target_game_num = (game_num * 2) - (1 - team_index)

    # 3位決定戦のときは準決勝の2試合がtarget_game
    consolation_round = (round_num == self.round_num) && (game_num == 2)
    target_game_num = 1 + team_index if consolation_round

    target_game = self.results[target_round_num - 1][target_game_num - 1]

    # 勝者がいる場合はそのteamを返す（通常winのケースとbyeのケースを両方含む）
    if target_game['winner'].present?
      winner_index = target_game['winner']
      winner_index = 1 - winner_index if consolation_round # 3位決定戦の場合はloserを返す

      self.winner_team(target_round_num, target_game_num, winner_index)
    # BYE or TBD
    else
      {"name" => '--'}
    end
  end

  # 優勝/準優勝チーム (rank = 1 or 2)
  def final_team(rank)
    final = self.results[self.round_num - 1][0]
    if final['winner'].present?
      team_index = (rank == 1) ? final['winner'] : 1 - final['winner']
      self.winner_team(self.round_num, 1, team_index)
    else
      {"name" => "(TBD)"}
    end
  end

  # 優勝/準優勝ハイライトの対象match(ラウンドごと)  e.g. 優勝者ID=13の場合、round:1 →（ 13 / 2**1 ).ceil = 7
  def highlight_match(round_num, rank)
    target_team = self.final_team(rank)
    target_team['id'].quo(2 ** round_num).ceil  if target_team['id']
  end


  def round_name(args)
    round = args[:round]

    if round == self.round_num
      I18n.t('tournament.round_name.final_round')
    elsif round == self.round_num - 1
      I18n.t('tournament.round_name.semi-final_round')
    else
      I18n.t('tournament.round_name.numbered_round', round: round)
    end
  end

  def game_name(args)
    round_num = args[:round]
    game_num = args[:game]

    if round_num == self.round_num
      game_name = (game_num==1) ? '決勝戦' : '3位決定戦'
    else
      game_name = "第#{game_num}試合"
    end
  end

  def match_name(args)
    round_num = args[:round]
    game_num = args[:game]

    round_name = self.round_name(round: round_num)
    game_name = self.game_name(round: round_num, game: game_num)

    # 決勝戦・3位決定戦のときはgame_nameのみ
    (round_num == self.round_num) ? game_name : "#{round_name} #{game_name}"
  end

  # タイトルをもとに自動タグ付け
  def auto_tagging
    tags = %w(将棋 ラグビー ホッケー バドミントン ソフトボール バレーボール  ドッヂボール フットサル フェンシング バスケットボール ビリヤード 柔道 剣道 野球 卓球 サッカー テニス シャドウバース シャドバ スプラトゥーン クラッシュ・ロワイヤル クラロワ オーバーウォッチ Overwatch スマッシュブラザーズ スマブラ 遊戯王 人狼 雪合戦 麻雀 Shardbound)
    match = self.title.match(/#{tags.join('|')}/)
    return if !match

    # 表記ゆれ対応
    if match[0] == 'シャドバ'
      tag = 'シャドウバース'
    elsif match[0] == 'クラロワ'
      tag = 'クラッシュ・ロワイヤル'
    elsif match[0] == 'Overwatch'
      tag = 'オーバーウォッチ'
    elsif match[0] == 'スマブラ'
      tag = 'スマッシュブラザーズ'
    else
      tag = match[0]
    end

    self.tag_list.add(tag)
  end

  def text_url_to_link(text)
    URI.extract(text, ['http', 'https']).uniq.sort{|a, b| b.size <=> a.size}.each do |url|
      tmp_url = url.gsub('http', 'HTTP')
      sub_text = "<a href='#{tmp_url}' target='_blank'>#{tmp_url}</a>"
      text.gsub!(url, sub_text)
    end
    text.gsub!('HTTP', 'http')
    text
  end

  def change_tournament_size
    # トーナメントを大きくするとき
    if self.size > self.size_was
      # プレイヤー追加
      for i in self.size_was+1..self.size do
        self.teams << {"name"=>"Player#{i}"}
      end

      # 試合結果追加
      old_round_num = Math.log2(self.size_was).to_i  #=> return 3 rounds for 8 players (2**3=8)
      for i in 1..self.round_num do
        match_count = [(self.size_was / 2**i), 2].max
        new_match_count = [(self.size / 2**i), 2].max
        if i > old_round_num
          arr = []
          for j in 1..new_match_count do
            arr << {"score"=>[nil, nil], "winner"=>nil, "comment"=>nil, "bye"=>false, "finished"=>false}
          end
          self.results << arr
        else
          for j in match_count+1..new_match_count do
            self.results[i-1] << {"score"=>[nil, nil], "winner"=>nil, "comment"=>nil, "bye"=>false, "finished"=>false}
          end
        end
      end
      # ３位決定戦が入力されてるとサイズ変更時に他の試合の結果になってしまうため消しておく
      self.results[old_round_num-1][1] = {"score"=>[nil, nil], "winner"=>nil, "comment"=>nil, "bye"=>false, "finished"=>false}

    # 小さくするとき
    elsif self.size < self.size_was
      # プレイヤー削除
      self.teams = self.teams.slice(0, self.size)

      # 試合結果削除
      for i in 1..self.round_num do
        match_count = [(self.size / 2**i), 2].max
        self.results[i-1] = self.results[i-1].slice(0, match_count) #ラウンド内の不要なmatchを削除
      end
      self.results = self.results.slice(0, self.round_num)  # 不要になったラウンドを削除

      # ３位決定戦に変更前の他の試合結果が入るのを防ぐ
      self.results[self.round_num-1][1] = {"score"=>[nil, nil], "winner"=>nil, "comment"=>nil, "bye"=>false, "finished"=>false}
    end
  end

  # 試合登録結果のリセット
  def reset_game(round_num, game_num)
    g = game_num
    for r in round_num..self.round_num
      self.results[r - 1][g - 1] = {score: [nil, nil], winner: nil, comment: nil, bye: false, finished: false}
      g = g.quo(2).ceil
    end

    # 3位決定戦は必ずリセット
    self.results[self.round_num - 1][1] = {score: [nil, nil], winner: nil, comment: nil, bye: false, finished: false}

    self.update({results: self.results})
  end
end
