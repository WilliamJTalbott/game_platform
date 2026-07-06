Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root 'games#index'

  resources :users

  resources :games do
    resources :participants, only: [:create, :show]
  end

  resources :stats, only: [:index]
  resources :history, only: [:index]
  resources :rules, only: [:index]

end
