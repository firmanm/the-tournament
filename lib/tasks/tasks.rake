namespace :tasks do
  task :check_finished_tournaments => :environment do
    Tournament.all.each do |tnmt|
      tnmt.update(finished: true) if tnmt.is_finished?
    end
  end

  task :delete_unfinished_tournaments => :environment do
    Tournament.where(finished: false).where("created_at < ?", 1.month.ago).destroy_all
  end

  task :delete_nonactive_users => :environment do
    User.where("last_sign_in_at < ?", 1.year.ago).destroy_all
  end

  task :upload_json => :environment do
    Tournament.all.each do |tnmt|
      tnmt.upload_json
    end
  end

  task :migrate_games_and_players => :environment do
    Tournament.all.each do |tnmt|
      teams = Array.new
      results = Array.new
      for i in 1..tnmt.round_num
        round_res = Array.new  # create result array for each round
        results << round_res
        tnmt.games.where(bracket: 1, round: i).each do |game|
          # Set team info
          if i == 1
            game.game_records.each do |r|
              if r.player.name.present?
                team = {name: r.player.name, flag: r.player.country}
              else
                team = nil
              end
              teams << team
            end
          end

          # Set match Info
          res = {score:[nil,nil], comment:nil, winner:nil, finished:false}
          res[:comment] = game.comment

          # Bye Game
          if game.bye == true
            win_record = game.game_records.find_by(winner: true)
            res[:score] = [nil, nil]
            res[:winner] = win_record.record_num - 1
            res[:finished] = true
          # Finished Game
          elsif game.finished?
            res[:score] = game.game_records.map{|r| r.score}.to_a
            win_record = game.game_records.find_by(winner: true)
            res[:winner] = win_record.record_num - 1
            res[:finished] = true
          # Unfinished Game
          else
            res[:score] = [nil, nil]
            res[:winner] = nil
            res[:finished] = false
          end
          round_res << res
        end
      end
      tnmt.update({
        teams: teams.to_json,
        results: results.to_json
      })
    end
  end
end
