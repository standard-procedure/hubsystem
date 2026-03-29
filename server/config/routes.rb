Rails.application.routes.draw do
  root "dashboard#show"

  resource :component, only: [:show]

  resources :users, only: [:index, :show] do
    resources :notes, only: [:new, :create, :edit, :update, :destroy]
    resources :conversations, only: [:new, :create], controller: "user_conversations"
  end

  resources :conversations, only: [:index, :show, :new] do
    resources :messages, only: [:create], module: :conversations
    resource :acceptance, only: [:create], controller: "conversation_acceptances"
    resource :rejection, only: [:create], controller: "conversation_rejections"
    resource :closure, only: [:new, :create], controller: "conversation_closures"
  end

  resources :tasks, only: [:index, :show, :new, :create] do
    resource :assignment, only: [:update], controller: "task_assignments"
    resource :completion, only: [:create], controller: "task_completions"
    resource :cancellation, only: [:create], controller: "task_cancellations"
  end

  resources :messages, only: [:index]

  namespace :api do
    namespace :v1 do
      resources :conversations, only: [:index, :show, :create] do
        resources :messages, only: [:index, :create], controller: "conversations/messages"
        resource :acceptance, only: [:create], controller: "conversation_acceptances"
        resource :rejection, only: [:create], controller: "conversation_rejections"
        resource :closure, only: [:create], controller: "conversation_closures"
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
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
