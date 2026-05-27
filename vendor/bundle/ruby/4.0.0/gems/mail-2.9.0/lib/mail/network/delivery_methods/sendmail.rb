# frozen_string_literal: true
require 'mail/smtp_envelope'

module Mail
  # A delivery method implementation which sends via sendmail.
  #
  # To use this, first find out where the sendmail binary is on your computer,
  # if you are on a mac or unix box, it is usually in /usr/sbin/sendmail, this will
  # be your sendmail location.
  #
  #   Mail.defaults do
  #     delivery_method :sendmail
  #   end
  #
  # Or if your sendmail binary is not at '/usr/sbin/sendmail'
  #
  #   Mail.defaults do
  #     delivery_method :sendmail, :location => '/absolute/path/to/your/sendmail'
  #   end
  #
  # Then just deliver the email as normal:
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
  class Sendmail
    DEFAULTS = {
      :location   => '/usr/sbin/sendmail',
      :arguments  => %w[ -i ]
    }

    attr_accessor :settings

    class DeliveryError < StandardError
    end

    def initialize(values)
      self.settings = self.class::DEFAULTS.merge(values)
      raise ArgumentError, ":arguments expected to be an Array of individual string args" if settings[:arguments].is_a?(String)
    end

    def destinations_for(envelope)
      envelope.to
    end

    def deliver!(mail)
      envelope = Mail::SmtpEnvelope.new(mail)

      command = [settings[:location]]
      command.concat Array(settings[:arguments])
      command.concat [ '-f', envelope.from ] if envelope.from

      if destinations = destinations_for(envelope)
        command.push '--'
        command.concat destinations
      end

      popen(command) do |io|
        io.puts ::Mail::Utilities.binary_unsafe_to_lf(envelope.message)
        io.flush
      end
    end

    private
      def popen(command, &block)
        IO.popen(command, 'w+', :err => :out, &block).tap do
          if $?.exitstatus != 0
            raise DeliveryError, "Delivery failed with exitstatus #{$?.exitstatus}: #{command.inspect}"
          end
        end
      end
  end
end
