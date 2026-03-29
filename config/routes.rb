Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "dashboard#show", as: :authenticated_root
  end

  root "pages#home"

  get "dashboard", to: "dashboard#show"
  resources :onboarding, only: %i[show update]
  resource :profile, only: %i[show edit update]
  resources :weekly_plans, path: "plan"
  resources :session_logs, path: "log" do
    post :parse, on: :collection
  end
  get "progress", to: "progress#show"
  resources :coaches, only: %i[index show]

  namespace :coach do
    get "dashboard", to: "dashboard#show"
    resources :athletes, only: %i[show edit update]
  end

  namespace :admin do
    get "ai_usage", to: "ai_usage#index"
    resources :plans, only: %i[index show]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
