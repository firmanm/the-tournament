namespace :tasks do
  task :delete_unfinished_tournaments => :environment do
    Tournament.where(finished: false).where("created_at < ?", 1.month.ago).destroy_all
  end

  task :delete_nonactive_users => :environment do
    User.where("last_sign_in_at < ?", 1.year.ago).destroy_all
  end

  task :guest_migrate => :environment do
    User.create(id: 1, email: 'guest@the-tournament.jp', password: SecureRandom.hex(8))
    Plan.find(1).update(user_id: 1, size: 32)
  end
end
