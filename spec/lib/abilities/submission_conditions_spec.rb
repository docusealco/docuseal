# frozen_string_literal: true

describe Abilities::SubmissionConditions do
  describe '.collection' do
    context 'when user has no account_id' do
      let(:user) { build(:user, account_id: nil) }

      it 'returns empty array' do
        result = described_class.collection(user)
        expect(result).to eq([])
      end
    end

    context 'when user has account_id' do
      let(:account) { create(:account) }
      let(:user) { create(:user, account: account) }

      it 'returns submissions for the user account' do
        # Create submissions for this account
        template = create(:template, account: account, author: user)
        submission1 = create(:submission, template: template)
        submission2 = create(:submission, template: template)

        # Create submission for different account (should not be included)
        other_account = create(:account)
        other_user = create(:user, account: other_account)
        other_template = create(:template, account: other_account, author: other_user)
        create(:submission, template: other_template)

        result = described_class.collection(user)
        expect(result).to include(submission1, submission2)
        expect(result.count).to eq(2)
      end

      context 'with global partnership templates' do
        let(:partnership) { create(:partnership) }

        before do
          allow(ExportLocation).to receive(:global_partnership_id).and_return(partnership.id)
        end

        it 'includes submissions from global partnership templates' do
          # Create account submission
          account_template = create(:template, account: account, author: user)
          account_submission = create(:submission, template: account_template)

          # Create global partnership submission
          partnership_template = create(:template, :partnership_template, partnership: partnership)
          partnership_submission = create(:submission, template: partnership_template, account: account)

          result = described_class.collection(user)
          expect(result).to include(account_submission, partnership_submission)
        end
      end

      context 'with partnership context' do
        let(:partnership) { create(:partnership, external_partnership_id: 123) }

        it 'includes submissions from accessible partnership templates' do
          # Create account submission
          account_template = create(:template, account: account, author: user)
          account_submission = create(:submission, template: account_template)

          # Create partnership submission
          partnership_template = create(:template, :partnership_template, partnership: partnership)
          partnership_submission = create(:submission, template: partnership_template, account: account)

          request_context = { accessible_partnership_ids: [123] }
          result = described_class.collection(user, request_context: request_context)

          expect(result).to include(account_submission, partnership_submission)
        end
      end
    end
  end

  describe '.entity' do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }

    context 'with account submission' do
      let(:template) { create(:template, account: account, author: user) }
      let(:submission) { create(:submission, template: template) }

      it 'allows access for account owner' do
        result = described_class.entity(submission, user: user)
        expect(result).to be true
      end
    end

    context 'with different account submission' do
      let(:other_account) { create(:account) }
      let(:other_user) { create(:user, account: other_account) }
      let(:template) { create(:template, account: other_account, author: other_user) }
      let(:submission) { create(:submission, template: template) }

      it 'denies access for different account user' do
        result = described_class.entity(submission, user: user)
        expect(result).to be false
      end
    end

    context 'with global partnership submission' do
      let(:partnership) { create(:partnership) }
      let(:template) { create(:template, :partnership_template, partnership: partnership) }
      let(:other_account) { create(:account) }
      let(:submission) { create(:submission, template: template, account: other_account) }

      context 'when global partnership' do
        before do
          allow(ExportLocation).to receive(:global_partnership_id).and_return(partnership.id)
        end

        it 'allows access to global partnership submissions' do
          result = described_class.entity(submission, user: user)
          expect(result).to be true
        end
      end

      context 'when not global partnership' do
        before do
          allow(ExportLocation).to receive(:global_partnership_id).and_return(nil)
        end

        it 'denies access to non-global partnership submissions' do
          result = described_class.entity(submission, user: user)
          expect(result).to be false
        end
      end
    end

    context 'with partnership context submission' do
      let(:partnership) { create(:partnership, external_partnership_id: 456) }
      let(:template) { create(:template, :partnership_template, partnership: partnership) }
      let(:other_account) { create(:account) }
      let(:submission) { create(:submission, template: template, account: other_account) }

      it 'allows access via partnership context' do
        request_context = { accessible_partnership_ids: [456] }
        result = described_class.entity(submission, user: user, request_context: request_context)
        expect(result).to be true
      end

      it 'denies access without partnership context' do
        result = described_class.entity(submission, user: user)
        expect(result).to be false
      end

      it 'handles integer comparison in partnership context' do
        partnership = create(:partnership, external_partnership_id: 789)
        template = create(:template, :partnership_template, partnership: partnership)
        submission = create(:submission, template: template, account: other_account)

        # accessible_partnership_ids are converted to integers by PartnershipContext concern
        request_context = { accessible_partnership_ids: [789] }
        result = described_class.entity(submission, user: user, request_context: request_context)
        expect(result).to be true
      end
    end

    context 'with user without account' do
      let(:template_author) { create(:user, account: account) }
      let(:user) { build(:user, account_id: nil) }
      let(:template) { create(:template, account: account, author: template_author) }
      let(:submission) { create(:submission, template: template) }

      it 'denies access' do
        result = described_class.entity(submission, user: user)
        expect(result).to be false
      end
    end
  end
end
