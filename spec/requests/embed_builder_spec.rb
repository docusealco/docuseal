# frozen_string_literal: true

require 'jwt'

describe 'Embed builder' do
  let(:account) { create(:account) }
  # Eager so the account always has a user — Account#default_template_folder
  # picks author_id from account.users.minimum(:id) when creating templates.
  let!(:user) { create(:user, account:) }
  let(:api_key) { user.access_token.token }

  def token(claims = {})
    JWT.encode({ user_email: user.email, exp: 5.minutes.from_now.to_i }.merge(claims), api_key, 'HS256')
  end

  describe 'GET /embed/builder' do
    it 'signs the owner in and redirects to /new for a fresh template' do
      get embed_builder_path, params: {
        token: token(document_urls: ['https://example.com/doc.pdf'], name: 'Consent Form', external_id: 'ext-123')
      }

      expect(response).to have_http_status(:found)
      expect(response.location).to include('/new')
      expect(response.location).to include('external_id=ext-123')
      expect(response.location).to include('Consent_Form.pdf')
    end

    it 'redirects to the editor for an existing owned template' do
      template = create(:template, account:, author: user, external_id: 'ext-xyz')

      get embed_builder_path, params: { token: token(template_id: template.id) }

      expect(response).to redirect_to(edit_template_path(template))
    end

    it 'never opens a template the account does not own — falls back to create' do
      other_account = create(:account)
      other = create(:template, account: other_account, author: create(:user, account: other_account),
                                external_id: 'foreign')

      get embed_builder_path, params: { token: token(template_id: other.id) }

      expect(response.location).to include('/new')
      expect(response.location).not_to include("/templates/#{other.id}")
    end

    it 'rejects a token signed with the wrong key' do
      bad = JWT.encode({ user_email: user.email, exp: 5.minutes.from_now.to_i }, 'not-the-key', 'HS256')

      get embed_builder_path, params: { token: bad }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects an expired token' do
      get embed_builder_path, params: { token: token(exp: 1.minute.ago.to_i) }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects a token with no exp claim' do
      bare = JWT.encode({ user_email: user.email }, api_key, 'HS256')

      get embed_builder_path, params: { token: bare }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects a token whose lifetime exceeds the cap' do
      get embed_builder_path, params: { token: token(exp: 1.hour.from_now.to_i) }

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'rejects a token for an unknown owner' do
      foreign = JWT.encode({ user_email: 'nobody@example.com', exp: 5.minutes.from_now.to_i }, api_key, 'HS256')

      get embed_builder_path, params: { token: foreign }

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe 'scope enforcement (EmbedScoped)' do
    it 'confines the embed session to its own template' do
      mine = create(:template, account:, author: user, external_id: 'mine')
      theirs = create(:template, account:, author: user, external_id: 'theirs')

      get embed_builder_path, params: { token: token(template_id: mine.id) }
      expect(response).to redirect_to(edit_template_path(mine))

      # Cookies persist across requests within a request spec, so the next
      # calls ride the embed session established above. The guard runs as a
      # before_action — a blocked request 403s BEFORE the view renders, so
      # reaching the builder view (which needs compiled webpack assets, absent
      # in this env) proves the in-scope template was allowed through.
      begin
        get edit_template_path(mine)
        expect(response).not_to have_http_status(:forbidden)
      rescue ActionView::Template::Error, Shakapacker::Manifest::MissingEntryError
        # Reached view rendering => the scope guard allowed the in-scope template.
      end

      get edit_template_path(theirs)
      expect(response).to have_http_status(:forbidden)
    end

    it 'refuses template enumeration even with a valid embed session' do
      mine = create(:template, account:, author: user, external_id: 'mine')

      get embed_builder_path, params: { token: token(template_id: mine.id) }
      get '/templates'

      expect(response).to have_http_status(:forbidden)
    end
  end
end
