# frozen_string_literal: true
require 'mail/smtp_envelope'

module Mail
  # == Sending Email with SMTP
  #
  # Mail allows you to send emails using SMTP.  This is done by wrapping Net::SMTP in
  # an easy to use manner.
  #
  # === Sending via SMTP server on Localhost
  #
  # Sending locally (to a postfix or sendmail server running on localhost) requires
  # no special setup.  Just to Mail.deliver &block or message.deliver! and it will
  # be sent in this method.
  #
  # === Sending via MobileMe
  #
  #   Mail.defaults do
  #     delivery_method :smtp, { :address              => "smtp.me.com",
  #                              :port                 => 587,
  #                              :domain               => 'your.host.name',
  #                              :user_name            => '<username>',
  #                              :password             => '<password>',
  #                              :authentication       => 'plain',
  #                              :enable_starttls      => :auto  }
  #   end
  #
  # === Sending via GMail
  #
  #   Mail.defaults do
  #     delivery_method :smtp, { :address              => "smtp.gmail.com",
  #                              :port                 => 587,
  #                              :domain               => 'your.host.name',
  #                              :user_name            => '<username>',
  #                              :password             => '<password>',
  #                              :authentication       => 'plain',
  #                              :enable_starttls      => :auto  }
  #   end
  #
  # === Configuring TLS/SSL and STARTTLS
  #
  # A few remarks:
  # - when enabling `tls` (or `ssl`), setting (truthy values for) either `enable_starttls` or `enable_starttls_auto` will raise an ArgumentError as TLS and STARTTLS are mutually exclusive.
  # - to configure STARTTLS, use the `enable_starttls`-flag (instead of a combination of `enable_starttls` and `enable_starttls_auto`). Acceptable values are `:always`, `:auto` and `false`.
  # - when providing a truthy value for `enable_starttls`, the `enable_starttls_auto`-flag will be ignored.
  # - when none of `tls`, `ssl`, `enable_starttls` or `enable_starttls_auto` is set, the fallback will be `enable_starttls` `:auto`.
  #
  # === Certificate verification
  #
  # When using TLS, some mail servers provide certificates that are self-signed
  # or whose names do not exactly match the hostname given in the address.
  # OpenSSL will reject these by default. The best remedy is to use the correct
  # hostname or update the certificate authorities trusted by your ruby. If
  # that isn't possible, you can control this behavior with
  # an :openssl_verify_mode setting. Its value may be either an OpenSSL
  # verify mode constant (OpenSSL::SSL::VERIFY_NONE, OpenSSL::SSL::VERIFY_PEER),
  # or a string containing the name of an OpenSSL verify mode (none, peer).
  #
  # === Others
  #
  # Feel free to send me other examples that were tricky
  #
  # === Delivering the email
  #
  # Once you have the settings right, sending the email is done by:
  #
  #   Mail.deliver do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  # Or by calling deliver on a Mail message
  #
  #   mail = Mail.new do
  #     to 'mikel@test.lindsaar.net'
  #     from 'ada@test.lindsaar.net'
  #     subject 'testing sendmail'
  #     body 'testing sendmail'
  #   end
  #
  #   mail.deliver!
  class SMTP
    attr_accessor :settings

    DEFAULTS = {
      :address              => 'localhost',
      :port                 => 25,
      :domain               => 'localhost.localdomain',
      :user_name            => nil,
      :password             => nil,
      :authentication       => nil,
      :enable_starttls      => nil,
      :enable_starttls_auto => nil,
      :openssl_verify_mode  => nil,
      :ssl                  => nil,
      :tls                  => nil,
      :open_timeout         => 5,
      :read_timeout         => 5
    }

    def initialize(values)
      self.settings = DEFAULTS.merge(values)
    end

    def deliver!(mail)
      response = start_smtp_session do |smtp|
        Mail::SMTPConnection.new(:connection => smtp, :return_response => true).deliver!(mail)
      end

      settings[:return_response] ? response : self
    end

    private
      # `k` is said to be provided when `settings` has a non-nil value for `k`.
      def setting_provided?(k)
        !settings[k].nil?
      end

      # Yields one of `:always`, `:auto` or `false` based on `enable_starttls` and `enable_starttls_auto` flags.
      # Yields `false` when `smtp_tls?`.
      # Else defaults to `:auto` when neither `enable_starttls*` flag is provided.
      # Providing a truthy value for `enable_starttls` will ignore `enable_starttls_auto`.
      def smtp_starttls
        return false if smtp_tls?

        if setting_provided?(:enable_starttls) && settings[:enable_starttls]
          # enable_starttls: provided and truthy
          case settings[:enable_starttls]
          when :auto then :auto
          when :always then :always
          else
            :always
          end
        else
          # enable_starttls: not provided or false
          if setting_provided?(:enable_starttls_auto)
            settings[:enable_starttls_auto] ? :auto : false
          else
            # enable_starttls_auto: not provided
            # enable_starttls: when provided then false
            # use :auto when neither enable_starttls* provided
            setting_provided?(:enable_starttls) ? false : :auto
          end
        end
      end

      def smtp_tls?
        (setting_provided?(:tls) && settings[:tls]) || (setting_provided?(:ssl) && settings[:ssl])
      end

      def start_smtp_session(&block)
        build_smtp_session.start(settings[:domain], settings[:user_name], settings[:password], settings[:authentication], &block)
      end

      def build_smtp_session
        if smtp_tls? && (settings[:enable_starttls] || settings[:enable_starttls_auto])
          raise ArgumentError, ":enable_starttls and :tls are mutually exclusive. Set :tls if you're on an SMTPS connection. Set :enable_starttls if you're on an SMTP connection and using STARTTLS for secure TLS upgrade."
        end

        Net::SMTP.new(settings[:address], settings[:port]).tap do |smtp|
          if smtp_tls?
            smtp.disable_starttls
            smtp.enable_tls(ssl_context)
          else
            smtp.disable_tls

            case smtp_starttls
            when :always
              smtp.enable_starttls(ssl_context)
            when :auto
              smtp.enable_starttls_auto(ssl_context)
            else
              smtp.disable_starttls
            end
          end

          smtp.open_timeout = settings[:open_timeout] if settings[:open_timeout]
          smtp.read_timeout = settings[:read_timeout] if settings[:read_timeout]
        end
      end

      # Allow SSL context to be configured via settings, for Ruby >= 1.9
      # Just returns openssl verify mode for Ruby 1.8.x
      def ssl_context
        openssl_verify_mode = settings[:openssl_verify_mode]

        if openssl_verify_mode.kind_of?(String)
          openssl_verify_mode = OpenSSL::SSL.const_get("VERIFY_#{openssl_verify_mode.upcase}")
        end

        context = Net::SMTP.default_ssl_context
        context.verify_mode = openssl_verify_mode if openssl_verify_mode
        context.ca_path = settings[:ca_path] if settings[:ca_path]
        context.ca_file = settings[:ca_file] if settings[:ca_file]
        context
      end
  end
end
