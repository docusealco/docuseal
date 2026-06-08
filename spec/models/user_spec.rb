# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  describe '.from_clerk_oidc' do
    let!(:account) { create(:account) }

    def auth_for(email, name: 'Jane Doe')
      OmniAuth::AuthHash.new(
        provider: 'clerk_oidc',
        info: { email:, name:, first_name: nil, last_name: nil }
      )
    end

    before do
      stub_const('Docuseal::CLERK_ALLOWED_EMAIL_DOMAINS', ['bloombilt.com'])
      stub_const('Docuseal::CLERK_ADMIN_EMAIL_DOMAINS', ['bloombilt.com'])
    end

    it 'returns nil for a blank email' do
      expect(described_class.from_clerk_oidc(auth_for(''))).to be_nil
    end

    it 'rejects an email whose domain is not on the allowlist' do
      expect { described_class.from_clerk_oidc(auth_for('intruder@evil.com')) }
        .not_to change(described_class, :count)
      expect(described_class.from_clerk_oidc(auth_for('intruder@evil.com'))).to be_nil
    end

    it 'provisions a first-time admin-allowlisted user as admin' do
      user = described_class.from_clerk_oidc(auth_for('founder@bloombilt.com'))

      expect(user).to be_persisted
      expect(user.role).to eq(User::ADMIN_ROLE)
      expect(user.email).to eq('founder@bloombilt.com')
    end

    it 'refuses to provision an allowed-but-not-admin user instead of minting an admin' do
      stub_const('Docuseal::CLERK_ADMIN_EMAIL_DOMAINS', ['admins.bloombilt.com'])

      expect { described_class.from_clerk_oidc(auth_for('staff@bloombilt.com')) }
        .not_to change(described_class, :count)
      expect(described_class.from_clerk_oidc(auth_for('staff@bloombilt.com'))).to be_nil
    end

    it 'returns an existing active user without creating a new one' do
      existing = create(:user, account:, email: 'founder@bloombilt.com', role: User::ADMIN_ROLE)

      expect { described_class.from_clerk_oidc(auth_for('FOUNDER@bloombilt.com')) }
        .not_to change(described_class, :count)
      expect(described_class.from_clerk_oidc(auth_for('FOUNDER@bloombilt.com'))).to eq(existing)
    end
  end

  describe '.provision_clerk_admin' do
    before { stub_const('Docuseal::CLERK_ADMIN_EMAIL_DOMAINS', ['bloombilt.com']) }

    it 'creates an admin for an admin-allowlisted email' do
      account = create(:account)
      user = described_class.provision_clerk_admin(
        email: 'Founder@Bloombilt.com', first_name: 'Founder', last_name: 'One'
      )

      expect(user).to be_persisted
      expect(user.role).to eq(User::ADMIN_ROLE)
      expect(user.email).to eq('founder@bloombilt.com')
      expect(user.account).to eq(account)
    end

    it 'refuses to provision an email that is not admin-allowlisted' do
      create(:account)
      expect { described_class.provision_clerk_admin(email: 'rando@evil.com', first_name: 'R', last_name: 'O') }
        .not_to change(described_class, :count)
    end

    it 'returns nil when no account exists' do
      expect(described_class.provision_clerk_admin(email: 'founder@bloombilt.com', first_name: 'F', last_name: 'O'))
        .to be_nil
    end
  end

  describe '.clerk_email_allowed? (via Docuseal)' do
    it 'fails closed when the allowlist is empty' do
      stub_const('Docuseal::CLERK_ALLOWED_EMAIL_DOMAINS', [])
      expect(Docuseal.clerk_email_allowed?('anyone@anywhere.com')).to be(false)
    end

    it 'allows a listed domain and rejects an unlisted one' do
      stub_const('Docuseal::CLERK_ALLOWED_EMAIL_DOMAINS', ['bloombilt.com'])
      expect(Docuseal.clerk_email_allowed?('a@bloombilt.com')).to be(true)
      expect(Docuseal.clerk_email_allowed?('a@evil.com')).to be(false)
    end
  end

  describe '.clerk_email_admin? (via Docuseal)' do
    it 'grants no one when the admin allowlist is empty' do
      stub_const('Docuseal::CLERK_ADMIN_EMAIL_DOMAINS', [])
      expect(Docuseal.clerk_email_admin?('founder@bloombilt.com')).to be(false)
    end

    it 'grants only listed domains' do
      stub_const('Docuseal::CLERK_ADMIN_EMAIL_DOMAINS', ['bloombilt.com'])
      expect(Docuseal.clerk_email_admin?('founder@bloombilt.com')).to be(true)
      expect(Docuseal.clerk_email_admin?('founder@other.com')).to be(false)
    end
  end
end
