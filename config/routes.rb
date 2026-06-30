Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root 'games#index'
  get 'games/history', to: 'games#history'
  get "stats/index"
  get "pages/rules"

  resources :pages, only: [:index]
  resources :games, only: [:index]
  resources :stats, only: [:index]

  resources :user, only: [:new, :create]
  
end
