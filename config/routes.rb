# frozen_string_literal: true

Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  if !Docuseal.multitenant? && defined?(Sidekiq::Web)
    authenticated :user, ->(u) { u.sidekiq? } do
      mount Sidekiq::Web => '/jobs'
    end
  end

  root 'dashboard#index'

  get 'up' => 'rails/health#show'

  devise_for :users,
             path: '/', only: %i[sessions passwords omniauth_callbacks],
             controllers: begin
               options = { sessions: 'sessions', passwords: 'passwords' }
               options[:omniauth_callbacks] = 'omniauth_callbacks' if User.devise_modules.include?(:omniauthable)
               options
             end

  devise_scope :user do
    resource :invitation, only: %i[update] do
      get '' => :edit
    end
  end

  namespace :api, defaults: { format: :json } do
    resource :user, only: %i[show]
    resources :attachments, only: %i[create]
    resources :submitter_email_clicks, only: %i[create]
    resources :submitter_form_views, only: %i[create]
    resources :submitters, only: %i[index show update]
    resources :submissions, only: %i[index show create destroy] do
      collection do
        resources :init, only: %i[create], controller: 'submissions'
        resources :emails, only: %i[create], controller: 'submissions', as: :submissions_emails
      end
    end
    resources :templates, only: %i[update show index destroy] do
      resources :clone, only: %i[create], controller: 'templates_clone'
      resources :submissions, only: %i[index create]
    end
    resources :tools, only: %i[] do
      post :merge, on: :collection
    end
    scope 'events' do
      resources :form_events, only: %i[index], path: 'form/:type'
    end
  end

  resources :verify_pdf_signature, only: %i[create]
  resource :mfa_setup, only: %i[show new edit create destroy], controller: 'mfa_setup'
  resources :account_configs, only: %i[create]
  resources :user_configs, only: %i[create]
  resources :encrypted_user_configs, only: %i[destroy]
  resources :timestamp_server, only: %i[create]
  resources :dashboard, only: %i[index]
  resources :setup, only: %i[index create]
  resource :newsletter, only: %i[show update]
  resources :enquiries, only: %i[create]
  resources :users, only: %i[new create edit update destroy]
  resource :user_signature, only: %i[edit update destroy]
  resource :user_initials, only: %i[edit update destroy]
  resources :submissions_archived, only: %i[index], path: 'submissions/archived'
  resources :submissions, only: %i[index], controller: 'submissions_dashboard'
  resources :submissions, only: %i[show destroy]
  resources :console_redirect, only: %i[index]
  resources :upgrade, only: %i[index], controller: 'console_redirect'
  resources :manage, only: %i[index], controller: 'console_redirect'
  resource :testing_account, only: %i[show destroy]
  resources :testing_api_settings, only: %i[index]
  resources :submitters_autocomplete, only: %i[index]
  resources :template_folders_autocomplete, only: %i[index]
  resources :webhook_preferences, only: %i[create]
  resource :templates_upload, only: %i[create]
  authenticated do
    resource :templates_upload, only: %i[show], path: 'new'
  end
  resources :templates_archived, only: %i[index], path: 'templates/archived'
  resources :folders, only: %i[show edit update destroy], controller: 'template_folders'
  resources :template_sharings_testing, only: %i[create]
  resources :templates, only: %i[index], controller: 'templates_dashboard'
  resources :templates, only: %i[new create edit update show destroy] do
    resource :debug, only: %i[show], controller: 'templates_debug' if Rails.env.development?
    resources :documents, only: %i[create], controller: 'template_documents'
    resources :restore, only: %i[create], controller: 'templates_restore'
    resources :archived, only: %i[index], controller: 'templates_archived_submissions'
    resources :submissions, only: %i[new create]
    resource :folder, only: %i[edit update], controller: 'templates_folders'
    resource :preview, only: %i[show], controller: 'templates_preview'
    resource :form, only: %i[show], controller: 'templates_form_preview'
    resource :code_modal, only: %i[show], controller: 'templates_code_modal'
    resource :preferences, only: %i[show create], controller: 'templates_preferences'
    resources :submissions_export, only: %i[index new]
  end
  resources :preview_document_page, only: %i[show], path: '/preview/:signed_uuid'
  resource :blobs_proxy, only: %i[show], path: '/file/:signed_uuid/*filename',
                         controller: 'api/active_storage_blobs_proxy'
  resource :blobs_proxy, only: %i[show], path: '/blobs_proxy/:signed_uuid/*filename',
                         controller: 'api/active_storage_blobs_proxy'

  if Docuseal.multitenant?
    resource :blobs_proxy_legacy, only: %i[show],
                                  path: '/blobs/proxy/:signed_id/*filename',
                                  controller: 'api/active_storage_blobs_proxy_legacy',
                                  as: :rails_blob
    get '/disk/:encoded_key/*filename' => 'active_storage/disk#show', as: :rails_disk_service
    put '/disk/:encoded_token' => 'active_storage/disk#update', as: :update_rails_disk_service
    post '/direct_uploads' => 'active_storage/direct_uploads#create', as: :rails_direct_uploads
  end

  resources :start_form, only: %i[show update], path: 'd', param: 'slug' do
    get :completed
  end

  resources :submit_form, only: %i[], path: '' do
    get :success, on: :collection
  end

  resources :submit_form, only: %i[show update], path: 's', param: 'slug' do
    resources :values, only: %i[index], controller: 'submit_form_values'
    get :completed
  end

  resources :submit_form_draw_signature, only: %i[show], path: 'p', param: 'slug'

  resources :submissions_preview, only: %i[show], path: 'e', param: 'slug' do
    get :completed
  end

  resources :send_submission_email, only: %i[create] do
    get :success, on: :collection
  end

  resources :submitters, only: %i[], param: 'slug' do
    resources :download, only: %i[index], controller: 'submissions_download'
    resources :send_email, only: %i[create], controller: 'submitters_send_email'
    resources :debug, only: %i[index], controller: 'submissions_debug' if Rails.env.development?
  end

  scope '/settings', as: :settings do
    unless Docuseal.multitenant?
      resources :storage, only: %i[index create], controller: 'storage_settings'
      resources :email, only: %i[index create], controller: 'email_smtp_settings'
      resources :sms, only: %i[index], controller: 'sms_settings'
    end
    resources :sso, only: %i[index], controller: 'sso_settings'
    resources :notifications, only: %i[index create], controller: 'notifications_settings'
    resource :esign, only: %i[show create new update destroy], controller: 'esign_settings'
    resources :users, only: %i[index]
    resources :archived_users, only: %i[index], path: 'users/:status', controller: 'users',
                               defaults: { status: :archived }
    resource :personalization, only: %i[show create], controller: 'personalization_settings'
    resources :api, only: %i[index create], controller: 'api_settings'
    resource :webhooks, only: %i[show create update], controller: 'webhook_settings'
    resource :account, only: %i[show update destroy]
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
