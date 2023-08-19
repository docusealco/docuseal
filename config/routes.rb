# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
  mount Sidekiq::Web => '/sidekiq' if defined?(Sidekiq)

  root 'dashboard#index'

  devise_for :users,
             path: '/', only: %i[sessions passwords omniauth_callbacks],
             controllers: begin
               options = { sessions: 'sessions' }
               options[:omniauth_callbacks] = 'omniauth_callbacks' if Docuseal.multitenant?
               options
             end

  devise_scope :user do
    if Docuseal.multitenant?
      resource :registration, only: %i[show], path: 'sign_up'
      resource :registration, only: %i[create], path: 'new' do
        get '' => :new, as: :new
      end
    end

    resource :invitation, only: %i[update] do
      get '' => :edit
    end
  end

  namespace :api, defaults: { format: :json } do
    resources :attachments, only: %i[create]
    resources :submissions, only: %i[create]
    resources :templates, only: %i[update show index] do
      resources :submissions, only: %i[create]
      resources :documents, only: %i[create], controller: 'templates_documents'
    end
  end

  resources :dashboard, only: %i[index]
  resources :setup, only: %i[index create]
  resource :newsletter, only: %i[show update]
  resources :users, only: %i[new create edit update destroy]
  resources :submissions, only: %i[show destroy]
  resources :console_redirect, only: %i[index]
  resources :templates, only: %i[new create edit show destroy] do
    resources :submissions, only: %i[new create]
  end

  resources :start_form, only: %i[show update], path: 'd', param: 'slug' do
    get :completed
  end

  resources :submit_form, only: %i[show update], path: 's', param: 'slug' do
    get :completed
  end

  resources :send_submission_email, only: %i[create] do
    get :success, on: :collection
  end

  resources :submitters, only: %i[], param: 'slug' do
    resources :download, only: %i[index], controller: 'submissions_download'
    resources :debug, only: %i[index], controller: 'submissions_debug' if Rails.env.development?
  end

  scope '/settings', as: :settings do
    unless Docuseal.multitenant?
      resources :storage, only: %i[index create], controller: 'storage_settings'
      resources :email, only: %i[index create], controller: 'email_settings'
    end
    resources :esign, only: %i[index create], controller: 'esign_settings'
    resources :users, only: %i[index]
    resource :personalization, only: %i[show create], controller: 'personalization_settings'
    if !Docuseal.multitenant? || Docuseal.demo?
      resources :api, only: %i[index], controller: 'api_settings'
      resource :webhooks, only: %i[show create update], controller: 'webhook_settings'
    end
    resource :account, only: %i[show update]
    resources :profile, only: %i[index] do
      collection do
        patch :update_contact
        patch :update_password
        patch :update_app_url
      end
    end
  end

  ActiveSupport.run_load_hooks(:routes, self)
end
