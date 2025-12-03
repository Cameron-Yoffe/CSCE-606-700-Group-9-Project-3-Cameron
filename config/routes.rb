Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :movies, only: %i[index show]
  resources :movies do
    resources :tags, only: %i[create destroy]
  end
  resources :favorites, only: %i[index create destroy] do
    member do
      patch :set_top_position
      delete :remove_top_position
    end
  end
  resources :watchlists, only: %i[create destroy]
  resources :ratings, only: %i[create update destroy]
  resources :review_reactions, only: %i[create]
  resources :diary_entries

  # Follow system
  resources :follows, only: %i[destroy] do
    member do
      patch :accept
      delete :reject
    end
  end
  post "users/:user_id/follow", to: "follows#create", as: :follow_user

  # Notifications
  resources :notifications, only: %i[index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
      delete :destroy_all
      get :unread_count
    end
  end

  # Authentication routes
  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  get "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  resources :users, only: [ :create ]
  get "dashboard", to: "dashboards#show"
  get "users/search", to: "dashboards#search", as: :search_users
  get "profile", to: "profiles#show"
  post "profile/import_letterboxd", to: "profiles#import_letterboxd", as: :profile_import_letterboxd
  post "profile/import_letterboxd_ratings", to: "profiles#import_letterboxd_ratings", as: :profile_import_letterboxd_ratings
  get "profile/edit", to: "profiles#edit", as: :profile_edit
  patch "profile", to: "profiles#update"

  # User profiles (for viewing other users)
  get "users/:id", to: "profiles#show", as: :user_profile
  get "users/:id/followers", to: "profiles#followers", as: :user_followers
  get "users/:id/following", to: "profiles#following", as: :user_following

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"
end
