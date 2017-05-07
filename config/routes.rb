Rails.application.routes.draw do
  break if ARGV.join.include? 'assets:precompile'

  scope "(:locale)", shallow_path: "(:locale)", locale: /ja|en/ do
    root to: "static_pages#top"
    devise_for :users, :controllers => {
      :registrations => 'users/registrations'
    }
    resources :users

    resources :tournaments do
      get 'page/:page', action: :index, on: :collection
    end

    # players
    match 'tournaments/:id/players', to: 'tournaments#players', via: :get, as: :tournament_players
    match 'tournaments/:id/players/edit', to: 'tournaments#edit_players', via: :get, as: :tournament_edit_players
    match 'tournaments/:id/players', to: 'tournaments#update_players', via: :patch, as: :tournament_update_players

    # games
    match 'tournaments/:id/games', to: 'tournaments#games', via: :get, as: :tournament_games
    match 'tournaments/:id/games/edit', to: 'tournaments#edit_games', via: :get, as: :tournament_edit_games
    match 'tournaments/:id/games/edit/:round_num/:game_num', to: 'tournaments#edit_game', via: :get, as: :tournament_edit_game
    match 'tournaments/:id/games', to: 'tournaments#update_games', via: :patch, as: :tournament_update_games
    match 'tournaments/:id/games/:round_num/:game_num', to: 'tournaments#update_game', via: :patch, as: :tournament_update_game

    match 'tournaments/:id/raw', to: 'tournaments#raw', via: :get
    match 'tournaments/:id/upload', to: 'tournaments#upload', via: :get, as: :upload_tournament
    match 'tournaments/:id/upload_img', to: 'tournaments#upload_img', via: :post
    match 'tournaments/:id/photos', to: 'tournaments#photos', via: :get, as: :tournament_photos
    match 'tournaments/:id/(:title)', to: 'tournaments#show', via: :get, as: :pretty_tournament, constraints: {title: /[^\/]+/}
    match ':action', controller: :static_pages, via: :get

    scope :embed do
      get '/tournaments/:id' => redirect("https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/v2/index.html?id=%{id}&utm_campaign=embed&utm_medium=&utm_source=%{id}", status: 301)
    end
  end
end
