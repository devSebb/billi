Rails.application.routes.draw do
  devise_for :users

  # Authenticated root path
  authenticated :user do
    root "home#index", as: :authenticated_root
  end

  # Non-authenticated root path
  root "home#landing"

  get "dashboard", to: "home#dashboard"
  get "landing", to: "home#landing"

  # Transactions routes
  resources :transactions, only: [] do
    collection do
      post "upload_csv"
      post "process_mapped_csv"
      delete "reset"
      post "load_test_data"
      get "chart_data"
      delete "analysis_sessions/:id", to: "transactions#destroy_analysis_session", as: :destroy_analysis_session
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Add Plaid routes
  post "plaid/create_link_token", to: "plaid#create_link_token"
  post "plaid/exchange_public_token", to: "plaid#exchange_public_token"
  post "plaid/link", to: "plaid#link", as: :plaid_link

  # Add user profile route
  get "profile", to: "user_profile#show", as: :user_profile
end
