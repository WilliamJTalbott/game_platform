Rails.application.routes.draw do
  get "pages/rules"
  root 'games#index'

  resources :pages, only: [:index]
  resources :games, only: [:index]
  
end
