Rails.application.routes.draw do
  break if ARGV.join.include? 'assets:precompile'

  scope "(:locale)", shallow_path: "(:locale)", locale: /ja|en/ do
    root to: "static_pages#top"
    devise_for :users, :controllers => {
      :sessions => 'users/sessions',
      :registrations => 'users/registrations'
    }
    resources :users

    resources :tournaments do
      get 'page/:page', action: :index, on: :collection
    end

    match '/tokens/:token', to: 'users#token_auth', via: :get, as: :token

    scope :tournaments do
      # players
      match '/:id/players', to: 'tournaments#players', via: :get, as: :tournament_players
      match '/:id/players/edit', to: 'tournaments#edit_players', via: :get, as: :tournament_edit_players
      match '/:id/players', to: 'tournaments#update_players', via: :patch, as: :tournament_update_players

      # games
      match '/:id/games', to: 'tournaments#games', via: :get, as: :tournament_games
      match '/:id/games/edit', to: 'tournaments#edit_games', via: :get, as: :tournament_edit_games
      match '/:id/games/edit/:round_num/:game_num', to: 'tournaments#edit_game', via: :get, as: :tournament_edit_game
      match '/:id/games', to: 'tournaments#update_games', via: :patch, as: :tournament_update_games
      match '/:id/games/:round_num/:game_num', to: 'tournaments#update_game', via: :patch, as: :tournament_update_game

      match '/:id/raw', to: 'tournaments#raw', via: :get
      match '/:id/photos', to: 'tournaments#photos', via: :get, as: :tournament_photos

      match '/:id/(:title)', to: 'tournaments#show', via: :get, as: :pretty_tournament, constraints: {title: /[^\/]+/}
    end

    match '/docs', to: 'documents#index', via: :get, as: :docs
    match '/docs/:category_id/:document_id', to: 'documents#show', via: :get, as: :doc, constraints: {title: /[^\/]+/}

    match ':action', controller: :static_pages, via: :get
  end
end
