Rails.application.routes.draw do
  resources :participants, only: [:index, :show] do
    resources :messages, only: [:create, :index]
  end

  resources :conversations, only: [:create] do
    get :messages, on: :member
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
