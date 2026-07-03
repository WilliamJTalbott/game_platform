Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root 'games#index'
  get 'games/history', to: 'games#history'
  get "stats/index"
  get "pages/rules"

  resources :pages, only: [:index]
  resources :stats, only: [:index]

  resources :games do
    resources :players, only: [:create, :show]
  end

  resources :history, only: [:index]
  resources :users

end
