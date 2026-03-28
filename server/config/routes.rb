Rails.application.routes.draw do
  root "dashboard#show"

  resource :component, only: [:show]

  resources :conversations, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create], module: :conversations
    resource :acceptance, only: [:create], controller: "conversation_acceptances"
    resource :rejection, only: [:create], controller: "conversation_rejections"
    resource :closure, only: [:new, :create], controller: "conversation_closures"
  end

  resources :messages, only: [:index]

  resource :session
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post], as: :login
  match "/logout", to: "sessions#destroy", via: [:get, :post], as: :logout
  resources :passwords, param: :token
  use_doorkeeper
  get "up" => "rails/health#show", :as => :rails_health_check
end
