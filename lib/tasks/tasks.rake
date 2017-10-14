namespace :tasks do
  task :delete_unfinished_tournaments => :environment do
    Tournament.where(finished: false).where("created_at < ?", 1.month.ago).where.not(user_id: [835, 3314]).destroy_all
  end

  task :delete_nonactive_users => :environment do
    User.where("last_sign_in_at < ?", 1.year.ago).destroy_all
  end

  task :upload_html => :environment do
    tournament = Tournament.find(ENV['TOURNAMENT_ID'])
    file_path = File.join(Rails.root, "/tmp/#{tournament.id}.html")
    html = ActionController::Base.new.render_to_string(partial: 'tournaments/embed', locals: { tournament: tournament })
    File.write(file_path, html)

    TournamentUploader.new.store!( File.new(file_path) )
  end

  task :upload_updated_htmls => :environment do
    tournaments = Tournament.where(updated_at > Time.now - 10.minutes)

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
end
