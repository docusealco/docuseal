# frozen_string_literal: true

module Aws
  # A credential provider that executes a given process and attempts
  # to read its stdout to receive a JSON payload containing the credentials.
  #
  #     credentials = Aws::ProcessCredentials.new(['/usr/bin/credential_proc'])
  #     ec2 = Aws::EC2::Client.new(credentials: credentials)
  #
  # Arguments should be provided as strings in the array, for example:
  #
  #     process = ['/usr/bin/credential_proc', 'arg1', 'arg2']
  #     credentials = Aws::ProcessCredentials.new(process)
  #     ec2 = Aws::EC2::Client.new(credentials: credentials)
  #
  # Automatically handles refreshing credentials if an Expiration time is
  # provided in the credentials payload.
  #
  # @see https://docs.aws.amazon.com/cli/latest/topic/config-vars.html#sourcing-credentials-from-external-processes
  class ProcessCredentials

    include CredentialProvider
    include RefreshingCredentials

    # Creates a new ProcessCredentials object, which allows an
    # external process to be used as a credential provider.
    #
    # @param [Array<String>, String] process An array of strings including
    #  the process name and its arguments to execute, or a single string to be
    #  executed by the shell (deprecated and insecure).
    def initialize(process)
      if process.is_a?(String)
        warn('Passing a single string to Aws::ProcessCredentials.new '\
             'is insecure, please use use an array of system arguments instead')
      end
      @process = process
      @credentials = credentials_from_process
      @async_refresh = false
      @metrics = ['CREDENTIALS_PROCESS']
      super
    end

    private

    def credentials_from_process
      r, w = IO.pipe
      success = system(*@process, out: w)
      w.close
      raw_out = r.read
      r.close

      unless success
        raise Errors::InvalidProcessCredentialsPayload.new(
          'credential_process provider failure, the credential process had '\
          'non zero exit status and failed to provide credentials'
        )
      end

      begin
        creds_json = Aws::Json.load(raw_out)
      rescue Aws::Json::ParseError
        raise Errors::InvalidProcessCredentialsPayload.new('Invalid JSON response')
      end

      payload_version = creds_json['Version']
      return _parse_payload_format_v1(creds_json) if payload_version == 1

      raise Errors::InvalidProcessCredentialsPayload.new(
        "Invalid version #{payload_version} for credentials payload"
      )
    end

    def _parse_payload_format_v1(creds_json)
      creds = Credentials.new(
        creds_json['AccessKeyId'],
        creds_json['SecretAccessKey'],
        creds_json['SessionToken'],
        account_id: creds_json['AccountId']
      )

      @expiration = creds_json['Expiration'] ? Time.iso8601(creds_json['Expiration']) : nil
      return creds if creds.set?

      raise Errors::InvalidProcessCredentialsPayload.new(
        'Invalid payload for JSON credentials version 1'
      )
    end

    def refresh
      @credentials = credentials_from_process
    end

    def near_expiration?(expiration_length)
      # are we within 5 minutes of expiration?
      @expiration && (Time.now.to_i + expiration_length) > @expiration.to_i
    end
  end
end
