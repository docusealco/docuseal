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
  get 'manifest' => 'pwa#manifest'

  devise_for :users, path: '/', only: %i[sessions passwords],
                     controllers: { sessions: 'sessions', passwords: 'passwords' }

  # SSO login endpoint
  get 'sso/login', to: 'sso_login#login', as: :sso_login

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
      resources :documents, only: %i[index], controller: 'submission_documents'
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
      post :verify, on: :collection
    end
    scope 'events' do
      resources :form_events, only: %i[index], path: 'form/:type'
      resources :submission_events, only: %i[index], path: 'submission/:type'
    end
  end

  resources :verify_pdf_signature, only: %i[create]
  resource :mfa_setup, only: %i[show new edit create destroy], controller: 'mfa_setup'
  resources :account_configs, only: %i[create destroy]
  resources :user_configs, only: %i[create]
  resources :encrypted_user_configs, only: %i[destroy]
  resources :timestamp_server, only: %i[create]
  resources :dashboard, only: %i[index]
  resources :setup, only: %i[index create]
  resource :newsletter, only: %i[show update]
  resources :enquiries, only: %i[create]
  resources :users, only: %i[new create edit update destroy] do
    resource :send_reset_password, only: %i[update], controller: 'users_send_reset_password'
  end
  resource :user_signature, only: %i[edit update destroy]
  resource :user_initials, only: %i[edit update destroy]
  resources :submissions_archived, only: %i[index], path: 'submissions/archived'
  resources :submissions, only: %i[index], controller: 'submissions_dashboard'
  resources :submissions, only: %i[show destroy] do
    resources :unarchive, only: %i[create], controller: 'submissions_unarchive'
    resources :events, only: %i[index], controller: 'submission_events'
  end
  resources :submitters, only: %i[edit update]
  resources :console_redirect, only: %i[index]
  resources :upgrade, only: %i[index], controller: 'console_redirect'
  resources :manage, only: %i[index], controller: 'console_redirect'
  resource :testing_account, only: %i[show destroy]
  resources :testing_api_settings, only: %i[index]
  resources :submitters_autocomplete, only: %i[index]
  resources :submitters_resubmit, only: %i[update]
  resources :template_folders_autocomplete, only: %i[index]
  resources :webhook_secret, only: %i[show update]
  resources :webhook_preferences, only: %i[update]
  resource :templates_upload, only: %i[create]
  authenticated do
    resource :templates_upload, only: %i[show], path: 'new'
  end
  resources :templates_archived, only: %i[index], path: 'templates/archived'
  resources :folders, only: %i[show edit update destroy], controller: 'template_folders'
  resources :template_sharings_testing, only: %i[create]
  resources :templates, only: %i[index], controller: 'templates_dashboard'
  resources :submissions_filters, only: %i[show], param: 'name'
  resources :templates, only: %i[new create edit update show destroy] do
    resources :clone, only: %i[new create], controller: 'templates_clone'
    resource :debug, only: %i[show], controller: 'templates_debug' if Rails.env.development?
    resources :documents, only: %i[index create], controller: 'template_documents'
    resources :clone_and_replace, only: %i[create], controller: 'templates_clone_and_replace'
    resources :detect_fields, only: %i[create], controller: 'templates_detect_fields' unless Docuseal.multitenant?
    resources :restore, only: %i[create], controller: 'templates_restore'
    resources :archived, only: %i[index], controller: 'templates_archived_submissions'
    resources :submissions, only: %i[new create]
    resource :folder, only: %i[edit update], controller: 'templates_folders'
    resource :preview, only: %i[show], controller: 'templates_preview'
    resource :form, only: %i[show], controller: 'templates_form_preview'
    resource :code_modal, only: %i[show], controller: 'templates_code_modal'
    resource :preferences, only: %i[show create destroy], controller: 'templates_preferences'
    resource :share_link, only: %i[show create], controller: 'templates_share_link'
    resources :recipients, only: %i[create], controller: 'templates_recipients'
    resources :prefillable_fields, only: %i[create], controller: 'templates_prefillable_fields'
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

    ActiveSupport.run_load_hooks(:multitenant_routes, self)
  end

  resources :start_form, only: %i[show update], path: 'd', param: 'slug' do
    get :completed
  end

  resource :resubmit_form, controller: 'start_form', only: :update
  resource :submit_form_email_2fa, only: %i[create update]
  resources :start_form_email_2fa_send, only: :create

  resources :submit_form, only: %i[], path: '' do
    get :success, on: :collection
  end

  resources :submit_form, only: %i[show update], path: 's', param: 'slug' do
    resources :values, only: %i[index], controller: 'submit_form_values'
    resources :download, only: %i[index], controller: 'submit_form_download'
    resources :decline, only: %i[create], controller: 'submit_form_decline'
    resources :invite, only: %i[create], controller: 'submit_form_invite'
    get :completed
  end

  resources :submit_form_draw_signature, only: %i[show], path: 'p', param: 'slug'

  resources :submissions_preview, only: %i[show], path: 'e', param: 'slug' do
    get :completed
  end

  resources :send_submission_email, only: %i[create]

  resources :submitters, only: %i[], param: 'slug' do
    resources :download, only: %i[index], controller: 'submissions_download'
    resources :send_email, only: %i[create], controller: 'submitters_send_email'
    resources :debug, only: %i[index], controller: 'submissions_debug' if Rails.env.development?
  end

  scope '/settings', as: :settings do
    unless Docuseal.multitenant?
      resources :storage, only: %i[index create], controller: 'storage_settings'
      resources :search_entries_reindex, only: %i[create]
      resources :sms, only: %i[index], controller: 'sms_settings'
    end
    if Docuseal.demo? || !Docuseal.multitenant?
      resources :api, only: %i[index create], controller: 'api_settings'
      resource :reveal_access_token, only: %i[show create], controller: 'reveal_access_token'
    end
    resources :email, only: %i[index create], controller: 'email_smtp_settings'
    resources :sso, only: %i[index], controller: 'sso_settings'
    resources :notifications, only: %i[index create], controller: 'notifications_settings'
    resource :esign, only: %i[show create new update destroy], controller: 'esign_settings'
    resources :users, only: %i[index]
    resources :archived_users, only: %i[index], path: 'users/:status', controller: 'users',
                               defaults: { status: :archived }
    resources :integration_users, only: %i[index], path: 'users/:status', controller: 'users',
                                  defaults: { status: :integration }
    resource :personalization, only: %i[show create], controller: 'personalization_settings'
    resources :webhooks, only: %i[index show new create update destroy], controller: 'webhook_settings' do
      post :resend

      resources :events, only: %i[show], controller: 'webhook_events' do
        post :resend, on: :member
        post :refresh, on: :member
      end
    end
    resource :account, only: %i[show update destroy]
    resources :profile, only: %i[index] do
      collection do
        patch :update_contact
        patch :update_password
        patch :update_app_url
      end
    end
  end

  get '/js/:filename', to: 'embed_scripts#show', as: :embed_script

  ActiveSupport.run_load_hooks(:routes, self)
end
