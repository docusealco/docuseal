# Plan: Logo Upload + Editor/Viewer Roles

## Context

This is a self-hosted fork of DocuSeal for the City of Rayne. Three features are needed:
1. Admin can upload an org logo displayed site-wide
2. A new **Editor** role: full document lifecycle (upload, field edit, send) except delete
3. A new **Viewer** role: read-only access + download signed documents

The codebase uses Devise for auth, CanCanCan for authorization (`lib/ability.rb`), and ActiveStorage for file attachments. The Editor/Viewer role options already exist in the UI but are disabled and not in `User::ROLES`. The logo feature is gated behind a Pro paywall placeholder — the ActiveStorage exemption for `logo` attachments is already in place on the blob proxy controllers.

---

## Feature 1: Logo Upload

### What to change

**1. `app/models/account.rb`**
Add ActiveStorage attachment:
```ruby
has_one_attached :logo
```

**2. New controller: `app/controllers/logo_settings_controller.rb`**
```ruby
class LogoSettingsController < ApplicationController
  def update
    authorize!(:manage, current_account)
    current_account.logo.attach(params[:logo]) if params[:logo].present?
    current_account.logo.purge if params[:remove_logo] == '1'
    redirect_to settings_personalization_path, notice: t('settings_have_been_saved')
  end
end
```

**3. `config/routes.rb`**
```ruby
resource :logo_settings, only: [:update], path: 'settings/logo'
```

**4. `app/views/personalization_settings/_logo_form.html.erb`** (replace placeholder reference)
Replace the locked placeholder with a real upload form:
```erb
<%= form_with url: logo_settings_path, method: :patch, multipart: true do |f| %>
  <% if current_account.logo.attached? %>
    <%= image_tag url_for(current_account.logo), class: 'h-16 mb-4' %>
    <%= f.hidden_field :remove_logo, value: '0' %>
    <%= f.submit t('remove_logo'), name: 'remove_logo', value: '1', class: 'btn btn-sm btn-ghost' %>
  <% end %>
  <%= f.file_field :logo, accept: 'image/*', class: 'file-input file-input-bordered' %>
  <%= f.submit t('save'), class: 'btn btn-primary btn-sm' %>
<% end %>
```

**5. `app/views/personalization_settings/show.html.erb`**
Remove the placeholder partial reference; `_logo_form.html.erb` now contains the real form (already referenced there via `_logo_form`).

**6. Display logo site-wide**
In `app/views/layouts/application.html.erb` (or equivalent nav partial), replace the static logo/name with:
```erb
<% if current_account&.logo&.attached? %>
  <%= image_tag url_for(current_account.logo), class: 'h-8' %>
<% else %>
  DocuSeal <!-- or existing static content -->
<% end %>
```

The blob proxy already exempts `logo` from auth checks (both proxy controllers check `attachment.name == 'logo'`), so logo images will serve publicly to unauthenticated signers as well.

---

## Feature 2 & 3: Editor and Viewer Roles

### Step 1 — Register the roles

**`app/models/user.rb`**
```ruby
ROLES = [
  ADMIN_ROLE  = 'admin',
  EDITOR_ROLE = 'editor',
  VIEWER_ROLE = 'viewer'
].freeze
```
Add helper predicates:
```ruby
def admin?  = role == ADMIN_ROLE
def editor? = role == EDITOR_ROLE
def viewer? = role == VIEWER_ROLE
```

### Step 2 — Enable role select UI

**`app/views/users/_role_select.html.erb`**
- Remove `disabled` from editor and viewer options
- Remove the "unlock with Pro" upgrade link block (it's a self-hosted fork)

### Step 3 — Rewrite `lib/ability.rb`

Replace the single flat ability block with role-branched logic:

```ruby
class Ability
  include CanCan::Ability

  def initialize(user)
    case user.role
    when User::ADMIN_ROLE
      admin_abilities(user)
    when User::EDITOR_ROLE
      editor_abilities(user)
    when User::VIEWER_ROLE
      viewer_abilities(user)
    end
  end

  private

  def admin_abilities(user)
    # Existing full-access block — unchanged
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |t|
      Abilities::TemplateConditions.entity(t, user:, ability: 'manage')
    end
    can :destroy, Template, account_id: user.account_id
    can :manage, TemplateFolder,   account_id: user.account_id
    can :manage, TemplateSharing,  template: { account_id: user.account_id }
    can :manage, Submission,       account_id: user.account_id
    can :manage, Submitter,        account_id: user.account_id
    can :manage, User,             account_id: user.account_id
    can :manage, EncryptedConfig,  account_id: user.account_id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, AccountConfig,    account_id: user.account_id
    can :manage, UserConfig,       user_id: user.id
    can :manage, Account,          id: user.account_id
    can :manage, AccessToken,      user_id: user.id
    can :manage, McpToken,         user_id: user.id
    can :manage, WebhookUrl,       account_id: user.account_id
    can :manage, :mcp
  end

  def editor_abilities(user)
    # Full template lifecycle EXCEPT destroy
    can %i[read create update], Template, Abilities::TemplateConditions.collection(user) do |t|
      Abilities::TemplateConditions.entity(t, user:, ability: 'manage')
    end
    can :manage, TemplateFolder,  account_id: user.account_id
    can :manage, TemplateSharing, template: { account_id: user.account_id }
    can :manage, Submission,      account_id: user.account_id
    can :manage, Submitter,       account_id: user.account_id
    # Own profile only
    can %i[read update], User,    id: user.id
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig,      user_id: user.id
    can :manage, AccessToken,     user_id: user.id
    can :read,   Account,         id: user.account_id
    # No: destroy Template, manage AccountConfig, manage WebhookUrl, manage all Users
  end

  def viewer_abilities(user)
    can :read, Template,   account_id: user.account_id
    can :read, Submission, account_id: user.account_id
    can :read, Submitter,  account_id: user.account_id
    can %i[read update], User, id: user.id   # own profile (password reset etc.)
    can :manage, EncryptedUserConfig, user_id: user.id
    can :manage, UserConfig,  user_id: user.id
    can :read, Account,       id: user.account_id
    # Download permission: submitters download their own completed docs via public route
    # No create/update/destroy on any resource
  end
end
```

### Step 4 — Guard admin-only UI routes

**`app/controllers/application_controller.rb`** (or a new `before_action` concern)

Add a helper:
```ruby
def require_admin!
  redirect_to root_path, alert: t('access_denied') unless current_user.admin?
end
```

Apply it in:
- `PersonalizationSettingsController` — `before_action :require_admin!`
- `UsersController` — `before_action :require_admin!` (editors/viewers can't manage other users)
- `WebhookUrlsController` — `before_action :require_admin!`
- Any other settings-only controllers

### Step 5 — Hide delete UI for editors

In `app/views/templates/_template_actions.html.erb` (or wherever the delete button is rendered), wrap it:
```erb
<% if current_user.admin? %>
  <%= link_to t('delete'), template_path(@template), method: :delete, ... %>
<% end %>
```

CanCan already blocks the actual destroy action at the authorization layer — this is just UI polish.

### Step 6 — Migration (no schema change needed)

The `role` column is already a plain string column. No migration required — new roles are stored as `'editor'` or `'viewer'` strings. The `ROLES` constant update in step 1 makes them valid through `role_valid?` in `UsersController`.

---

## Viewer: Signed Document Download

Viewers can already `:read` Submission and Submitter records. DocuSeal's existing download route for completed documents goes through `SubmittersController` or a dedicated download route — CanCan's `:read` on Submitter should cover it. Verify after implementation that `authorize! :read, @submitter` is satisfied for viewer-role users; if any download action uses `:manage`, change it to `:read` in the relevant controller.

---

## Verification

1. **Logo**: Log in as admin → Settings → Personalization → upload a PNG → confirm it appears in the nav. Browse to the logo URL while logged out — should serve without redirect.
2. **Editor role**: Create an editor user → log in → confirm can upload a doc, add fields, send for signature → confirm Delete button is absent → try `DELETE /templates/:id` directly → expect 403.
3. **Viewer role**: Create a viewer user → log in → confirm can browse templates and submissions → confirm no create/edit/delete buttons → confirm can download a completed signed document → try `POST /templates` directly → expect 403.
4. **Admin unchanged**: Confirm admin user retains all existing capabilities.
5. **User management**: Log in as editor → try to visit `/settings/users` → expect redirect with access denied.

---

## Files Modified

| File | Change |
|------|--------|
| `app/models/user.rb` | Add EDITOR_ROLE, VIEWER_ROLE to ROLES; add predicate methods |
| `app/models/account.rb` | Add `has_one_attached :logo` |
| `lib/ability.rb` | Role-branched ability definitions |
| `app/controllers/logo_settings_controller.rb` | New — handles logo upload/removal |
| `app/controllers/application_controller.rb` | Add `require_admin!` helper |
| `app/controllers/personalization_settings_controller.rb` | Add `before_action :require_admin!` |
| `app/controllers/users_controller.rb` | Add `before_action :require_admin!` |
| `app/views/personalization_settings/_logo_form.html.erb` | Replace Pro placeholder with real upload form |
| `app/views/users/_role_select.html.erb` | Enable editor/viewer options, remove upgrade link |
| `app/views/templates/_template_actions.html.erb` (or equiv) | Wrap delete button in admin-only check |
| `app/views/layouts/application.html.erb` (or nav partial) | Conditionally render logo |
| `config/routes.rb` | Add logo_settings route |
