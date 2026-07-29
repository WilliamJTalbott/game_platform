Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  concern :turbo_fetch do
    patch :turbo_fetch, on: :collection
  end

  mount GoodJob::Engine => "good_job"
  mount ActionCable.server => "/cable"

  root "games#index"

  resources :users, concerns: :turbo_fetch

  resources :games do
    resources :participants, only: [ :create, :show ]
    resources :turns, only: [ :create ]

    member do
      post :start
    end
  end

  resources :stats, only: [ :index ]
  resources :history, only: [ :index ]
  resources :rules, only: [ :index ]
  resources :leaderboard, only: [ :index ]

  resources :offline, only: [ :index ]
end
