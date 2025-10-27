# frozen_string_literal: true

module Templates
  module CloneToAccount
    module_function

    # Clone a partnership template to a specific account
    # Supports both direct target_account and external_account_id with authorization
    def call(original_template, author:, target_account: nil, external_account_id: nil, current_user: nil,
             external_id: nil, name: nil, folder_name: nil)
      validation_result = validate_inputs(original_template, target_account, external_account_id, current_user)
      raise validation_result[:error_class], validation_result[:message] if validation_result[:error]

      resolved_target_account = validation_result[:target_account]

      template = Templates::Clone.call(
        original_template,
        author: author,
        external_id: external_id,
        name: name,
        folder_name: folder_name,
        target_account: resolved_target_account
      )

      # Clear template_accesses since partnership templates shouldn't copy user accesses
      template.template_accesses.clear

      template
    end

    def validate_inputs(original_template, target_account, external_account_id, current_user)
      # Check template type
      if original_template.partnership_id.blank?
        return { error: true, error_class: ArgumentError, message: 'Template must be a partnership template' }
      end

      # Resolve target account
      if target_account.present?
        { error: false, target_account: target_account }
      elsif external_account_id.present?
        unless current_user
          return { error: true, error_class: ArgumentError,
                   message: 'current_user required when using external_account_id' }
        end

        account = Account.find_by(external_account_id: external_account_id)
        return { error: true, error_class: ActiveRecord::RecordNotFound, message: 'Account not found' } unless account

        unless current_user.account_id == account.id
          return { error: true, error_class: ArgumentError, message: 'Unauthorized access to target account' }
        end

        { error: false, target_account: account }
      else
        {
          error: true,
          error_class: ArgumentError,
          message: 'Either target_account or external_account_id must be provided'
        }
      end
    end
  end
end
