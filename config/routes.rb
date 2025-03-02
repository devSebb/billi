Rails.application.routes.draw do
  devise_for :users

  root to: "home#index"
  get "dashboard", to: "home#dashboard"

  # Transactions routes
  resources :transactions, only: [] do
    collection do
      post "upload_csv"
      post "process_mapped_csv"
      delete "reset"
      post "load_test_data"
      get "chart_data"
    end
  end
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
