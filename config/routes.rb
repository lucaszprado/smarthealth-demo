Rails.application.routes.draw do
  devise_for :users
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "pages#home"
  get "about", to: "pages#about"
  get "/welcome", to: "pages#welcome"
  get "/testxlspx", to:"pages#testxlspx"
  get "/tailwind", to:"pages#tailwind"


  # Web Routes
  resources :humans, only: [:show] do
    resources :biomarkers, only: [:index, :show] do
      resources :measures, only: [:index]

      # get 'search', on: :collection, to: 'biomarkers#search'

      # get 'blood', on: :collection, to: 'biomarkers#blood'
      # get 'blood/search', on: :collection, to: 'biomarkers#blood_search'

      # # get 'blood', on: :collection, to: 'biomarkers#blood' do
      # #   get 'search', on: :collection, to: 'biomarkers#blood_search'
      # # end

      # get 'bioimpedance', on: :collection, to: 'biomarkers#bioimpedance'
      # get 'bioimpedance/search', on: :collection, to: 'biomarkers#bioimpedance_search'
    end

    resources :measures, only: [:index]
    resources :imaging_reports, only: [:index, :show] # url_helper: human_imaging_report_path(human_id: @human.id, id: @imaging_report.id)
  end

  # Integration Routes
  namespace :integrations do
    namespace :twilio do
      # Messaging API (SMS/WhatsApp inbound via Messaging Service)
      post 'messaging_webhook',     to: 'messaging_webhooks#create'

      # Conversations API (conversation events)
      post 'conversations_webhook', to: 'conversations_webhooks#create'

      # Media API (media files)
      get 'media/:id', to: 'media#show', as: :media
    end
  end

  # Admin Routes
  namespace :admin do
    resources :conversations, only: [:index, :show, :update] do
      resources :messages, only: [:create]
    end

    # Mount mission_control-jobs under admin namespace
    mount MissionControl::Jobs::Engine, at: "/jobs"
  end

  # Mount action cable
  mount ActionCable.server => '/cable'
end
