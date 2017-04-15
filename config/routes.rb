TheTournament::Application.routes.draw do
  break if ARGV.join.include? 'assets:precompile'

  scope "(:locale)", shallow_path: "(:locale)", locale: /ja|en/ do
    root to: "static_pages#top"
    devise_for :users, :controllers => {
      :registrations => 'users/registrations'
    }
    resources :users

    resources :tournaments, shallow: true do
      get 'page/:page', action: :index, on: :collection
      resources :games
      match 'games/edit', to: 'games#edit_all', via: :get, as: :edit_games
    end

    # players
    match 'tournaments/:id/players', to: 'tournaments#players', via: :get, as: :tournament_players
    match 'tournaments/:id/players/edit', to: 'tournaments#edit_players', via: :get, as: :tournament_edit_players
    match 'tournaments/:id/players', to: 'tournaments#update_players', via: :post, as: :tournament_update_players

    match 'tournaments/:id/raw', to: 'tournaments#raw', via: :get
    match 'tournaments/:id/upload', to: 'tournaments#upload', via: :get, as: :upload_tournament
    match 'tournaments/:id/upload_img', to: 'tournaments#upload_img', via: :post
    match 'tournaments/:id/photos', to: 'tournaments#photos', via: :get, as: :tournament_photos
    match 'tournaments/:id/(:title)', to: 'tournaments#show', via: :get, as: :pretty_tournament, constraints: {title: /[^\/]+/}
    match ':action', controller: :static_pages, via: :get

    scope :embed do
      get '/tournaments/:id' => redirect("https://#{ENV['FOG_DIRECTORY']}.storage.googleapis.com/embed/index.html?id=%{id}&utm_campaign=embed&utm_medium=&utm_source=%{id}", status: 301)
    end
  end
end
