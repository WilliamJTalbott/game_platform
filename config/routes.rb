Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  concern :turbo_fetch do
    patch :turbo_fetch, on: :collection
  end

  mount GoodJob::Engine => 'good_job'

  root 'games#index'

  resources :users, concerns: :turbo_fetch

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
