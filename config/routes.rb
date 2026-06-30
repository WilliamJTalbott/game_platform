Rails.application.routes.draw do

  root 'games#index'
  get 'games/history', to: 'games#history'
  get "stats/index"
  get "pages/rules"

  resources :pages, only: [:index]
  resources :games, only: [:index]
  resources :stats, only: [:index]

  
end
