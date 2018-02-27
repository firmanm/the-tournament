namespace :tasks do
  task :delete_unfinished_tournaments => :environment do
    Tournament.where(finished: false).where("created_at < ?", 1.month.ago).where.not(user_id: [835, 3314]).destroy_all
  end

  task :delete_nonactive_users => :environment do
    User.where("last_sign_in_at < ?", 1.year.ago).destroy_all
  end

  # 指定したトーナメントのHTMLを生成してGCSにアップロード
  # TOURNAMENT_ID=XXで、トーナメントIDを指定
  task :upload_html => :environment do
    tournament = Tournament.find(ENV['TOURNAMENT_ID'])
    file_path = File.join(Rails.root, "/tmp/#{tournament.id}.html")
    html = ActionController::Base.new.render_to_string(partial: 'tournaments/embed', locals: { tournament: tournament })
    File.write(file_path, html)

    TournamentUploader.new.store!( File.new(file_path) )
  end

  # XX分以内に更新されたトーナメントのHTMLを生成してGCSにアップロード
  # MINUTES=XXで、何分以内に更新されたトーナメントを対象にするか指定（デフォルト10分）
  task :upload_updated_htmls => :environment do
    range = ENV['MINUTES'] ? ENV['MINUTES'].to_i : 10
    tournaments = Tournament.where("updated_at > '#{Time.now - range.minutes}'").where.not(user_id: 1)

    tournaments.each do |tournament|
      file_path = File.join(Rails.root, "/tmp/#{tournament.id}.html")
      html = ActionController::Base.new.render_to_string(partial: 'tournaments/embed', locals: { tournament: tournament })
      File.write(file_path, html)

      TournamentUploader.new.store!( File.new(file_path) )
    end
  end

  task :guest_migrate => :environment do
    User.create(id: 1, email: 'guest@the-tournament.jp', password: SecureRandom.hex(8))
    Plan.find(1).update(user_id: 1, size: 32)
  end


  # 未完成で１ヶ月経過してアーカイブされたトーナメントをJSONから復元する
  # DBに手動で空のトーナメント（id,user_idのみ）を作成して、以下コマンドを実行
  # Heroku: heroku run rake tasks:restore_tournament_from_json TOURNAMENT_ID=XXX
  # Local: be foreman run rake tasks:restore_tournament_from_json TOURNAMENT_ID=XXX
  task :restore_tournament_from_json => :environment do
    json_file_path = "https://storage.googleapis.com/the-tournament/embed/v2/json/#{ENV['TOURNAMENT_ID']}.json"
    json_data = open(json_file_path) do |io|
      JSON.load(io)
    end

    teams = json_data['tournament_data']['teams'].flatten

    results = []
    results_json = json_data['tournament_data']['results']
    results_json.each do |round|
      arr = []
      round.each do |result|
        finished = result[0].present?

        if finished
          winner = (result[0] > result[1]) ? 0 : 1
          score = [result[0].floor, result[1].floor]
        else
          winner = nil
          score = [nil, nil]
        end

        arr << {score: score, winner: winner, comment:"", finished:finished}
      end
      results << arr
    end

    tnmt = Tournament.find(ENV['TOURNAMENT_ID'])
    tnmt.update(
      teams: teams,
      results: results,
      size: teams.size,
      title: json_data['title'],
      secondary_final: !json_data['skip_secondary_final'],
      consolation_round: !json_data['skip_consolation_round'],
      scoreless: json_data['scoreless'],
      created_at: Time.now
    )
  end


  # Firebaseへの移行タスク: tournaments
  task :transfer_tnmts_to_firebase  => :environment do
    require "google/cloud/datastore"
    project_id = "tournament-staging"
    datastore = Google::Cloud::Datastore.new project: project_id

    collection = "tournaments"

    Tournament.find_in_batches batch_size: 100 do |tournaments|
      documents = []
      tournaments.each do |tournament|
        # The name/ID for the new entity
        document_id = tournament.id.to_s

        # The Cloud Datastore key for the new entity
        document_key = datastore.key collection, document_id

        # Prepares the new entity
        document = datastore.entity document_key do |t|
          t['title'] = tournament.title
          t['userId'] = tournament.user_id.to_s
          t['detail'] = tournament.detail
          t['createdAt'] = tournament.created_at
          t['updatedAt'] = tournament.updated_at
          t['consolationRound'] = tournament.consolation_round
          t['scoreLess'] = tournament.scoreless
          t['private'] = tournament.private
          t['nameWidth'] = tournament.name_width
          t['scoreWidth'] = tournament.score_width
          t['noAds'] = tournament.no_ads
          t['profileImages'] = tournament.profile_images

          t['teams'] = datastore.entity do |teams_ent|
            tournament.teams.each_with_index do |team, index|
              teams_ent[index] = datastore.entity do |team_ent|
                team_ent['name'] = (team) ? team['name'] : ''
                team_ent['country'] = team['flag'] if team && team['flag'].present?
              end
            end
          end

          t['results'] = datastore.entity do |results_ent|
            tournament.results.each_with_index do |round, round_index|
              results_ent[round_index] = []
              round.each_with_index do |match, match_index|
                results_ent[round_index][match_index] = datastore.entity do |match_ent|
                  match_ent['comment'] = match['comment']
                  match_ent['winner'] = match['winner']
                  match_ent['score'] = datastore.entity do |score_ent|
                    score_ent[0] = match['score'][0]
                    score_ent[1] = match['score'][1]
                  end

                  match_ent['bye'] = false
                  if round_index == 0 && (!tournament.teams[match_index*2] || !tournament.teams[match_index*2 + 1])
                    match_ent['bye'] = true
                  end
                end
              end
            end
          end
        end
        documents << document
      end
      # Saves the entity
      datastore.save documents

      #FIXME: tmp limitation for debugging
      break
    end
  end


  # Firebaseへの移行タスク: users
  # CSV出力して、取り込みはFirebase adminSDKでauth:importする
  task :transfer_users_to_firebase  => :environment do
    require 'csv'

    @users = User.all
    CSV.open('users.csv', 'w') do |csv|
      @users.each do |user|
        csv_column_values = [
          user.id,
          user.email,
          nil,
          [*1..9, *'A'..'Z', *'a'..'z'].sample(8).join,
          [*1..9, *'A'..'Z', *'a'..'z'].sample(8).join,
          user.name
        ]
        csv << csv_column_values
      end
    end
  end
end
