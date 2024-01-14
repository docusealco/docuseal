# frozen_string_literal: true

Rails.application.config.filter_parameters += %i[password token otp_attempt passw secret token _key crypt salt
                                                 certificate otp ssn file]
