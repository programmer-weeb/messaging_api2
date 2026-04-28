Rails.application.routes.draw do
  devise_for :users,
             path: "",
             path_names: {
               sign_in: "login",
               sign_out: "logout",
               registration: "signup" },
             controllers: {
               sessions: "users/sessions",
               registrations: "users/registrations"
             },
             defaults: { format: :json }

  devise_scope :user do
    post "auth/google", to: "users/google_sessions#create", defaults: { format: :json }
  end

  get :me, to: "users#me", defaults: { format: :json }

  resources :users, only: [ :index, :show ], defaults: { format: :json }

  resources :messages, only: [ :index, :show, :create, :destroy ], defaults: { format: :json } do
    collection do
      get :sent
      get :received
      get :conversations
      get "conversation/:user_id", action: :conversation, as: :conversation
    end
  end

  resources :friendships, only: [ :index, :show, :create, :destroy ], defaults: { format: :json } do
    member do
      patch :accept
      patch :block
      patch :decline
    end
  end
end
