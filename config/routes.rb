Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root to: "pages#authenticated_root", as: :authenticated_root
  end

  root "pages#home"

  get "dashboard", to: "dashboard#show"
  resources :onboarding, only: %i[show update]
  resource :profile, only: %i[show edit update]
  resources :training_blocks, path: "plans", only: %i[index create] do
    collection do
      get :status
    end
    member do
      post :regenerate
      post :complete
    end
  end
  get "calendar", to: "calendar#show"
  resources :weekly_plans, path: "plan" do
    resources :planned_sessions, path: "session", only: %i[show update] do
      member do
        patch :update_exercises
      end
    end
  end
  resources :exercise_library_entries, path: "library", only: %i[index show]
  resources :session_logs, path: "log" do
    post :parse, on: :collection
  end
  resources :benchmarks, only: [ :index, :update ]
  get "progress", to: "progress#show"
  resources :coaches, only: %i[index show]

  namespace :coach_portal do
    get "dashboard", to: "dashboard#show"
    resources :athletes, only: %i[show edit update]
  end

  namespace :admin do
    get "ai_usage", to: "ai_usage#index"
    resources :plans, only: %i[index show]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
