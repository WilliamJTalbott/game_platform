Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  root 'games#index'

  resources :users

  mount GoodJob::Engine => 'good_job'

  resources :games do
    resources :participants, only: [:create, :show]
    resources :turns, only: [:create]

    member do
      post :start
    end
  end

  resources :stats, only: [:index]
  resources :history, only: [:index]
  resources :rules, only: [:index]

end
