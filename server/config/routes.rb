Rails.application.routes.draw do
  root "dashboard#show"

  resource :component, only: [:show]

  resources :users, only: [:index, :show] do
    resources :notes, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :messages
  resources :conversations, only: [:index, :show, :new, :create] do
    resources :messages, only: [:create], module: :conversations
    resource :closure, only: [:create], controller: "conversation_closures"
  end

  namespace :api do
    namespace :v1 do
      resources :messages, only: [:index, :show]
      resources :conversations, only: [:index, :show, :create, :update] do
        resources :messages, only: [:index, :create], controller: "conversations/messages"
      end

      resources :tasks, only: [:index, :show, :create] do
        resource :assignment, only: [:update], controller: "task_assignments"
        resource :completion, only: [:create], controller: "task_completions"
        resource :cancellation, only: [:create], controller: "task_cancellations"
      end
    end
  end

  resource :session
  match "/auth/:provider/callback", to: "sessions#create", via: [:get, :post], as: :login
  match "/logout", to: "sessions#destroy", via: [:post, :delete], as: :logout
  resources :passwords, param: :token
  use_doorkeeper
  get "up" => "rails/health#show", :as => :rails_health_check
  get "manifest" => "rails/pwa#manifest", :as => :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", :as => :pwa_service_worker
end
