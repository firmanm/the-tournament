namespace :tasks do
  task :delete_unfinished_tournaments => :environment do
    Tournament.where(finished: false).where("created_at < ?", 1.month.ago).destroy_all
  end

  task :delete_nonactive_users => :environment do
    User.where("last_sign_in_at < ?", 1.year.ago).destroy_all
  end

  task :truncate_tags_and_taggings => :environment do
    ActiveRecord::Base.connection.execute('TRUNCATE TABLE tags, taggings RESTART IDENTITY;')
  end

  task :add_tags => :environment do
    Tournament.skip_callback(:save, :before, :auto_tagging)
    Tournament.all.each do |tournament|
      tournament.auto_tagging
      tournament.save if tournament.tag_list.present?
    end
    Tournament.set_callback(:save, :before, :auto_tagging)
  end
end
