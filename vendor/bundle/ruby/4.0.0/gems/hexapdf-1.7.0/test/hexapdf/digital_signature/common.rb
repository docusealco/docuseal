require 'openssl'

module HexaPDF
  module TestUtils

    class Certificates

      def ca_key
        @ca_key ||= OpenSSL::PKey::RSA.new(2048)
      end

      def ca_certificate
        @ca_certificate ||=
          begin
            cert = create_cert(name: '/C=AT/O=HexaPDF/CN=HexaPDF Test Root CA', serial: 0,
                               public_key: ca_key)
            add_extensions(cert, cert, ca_key, is_ca: true, key_usage: 'cRLSign,keyCertSign')
            cert
          end
      end

      def signer_key
        @signer_key ||= OpenSSL::PKey::RSA.new(2048)
      end

      def signer_certificate
        @signer_certificate ||=
          begin
            cert = create_cert(name: '/CN=RSA signer/DC=gettalong', serial: 2,
                               public_key: signer_key, issuer: ca_certificate)
            add_extensions(cert, ca_certificate, ca_key, key_usage: 'digitalSignature')
            cert
          end
      end

      def non_repudiation_signer_certificate
        @non_repudiation_signer_certificate ||=
          begin
            cert = create_cert(name: '/CN=Non repudiation signer/DC=gettalong', serial: 2,
                               public_key: signer_key, issuer: ca_certificate)
            add_extensions(cert, ca_certificate, ca_key, key_usage: 'nonRepudiation')
            cert
          end
      end

      def dsa_signer_key
        @dsa_signer_key ||= OpenSSL::PKey::DSA.new(2048)
      end

      def dsa_signer_certificate
        @dsa_signer_certificate ||=
          begin
            cert = create_cert(name: '/CN=DSA signer/DC=gettalong', serial: 3,
                               public_key: dsa_signer_key, issuer: ca_certificate)
            add_extensions(cert, ca_certificate, ca_key, key_usage: 'digitalSignature')
            cert
          end
      end

      def ecdsa_signer_key
        @ecdsa_signer_key ||= OpenSSL::PKey::EC.generate('sect163k1')
      end

      def ecdsa_signer_certificate
        @ecdsa_signer_certificate ||=
          begin
            cert = create_cert(name: '/CN=ECDSA signer/DC=gettalong', serial: 4,
                               public_key: ecdsa_signer_key, issuer: ca_certificate)
            add_extensions(cert, ca_certificate, ca_key, key_usage: 'digitalSignature')
            cert
          end
      end

      def timestamp_certificate
        @timestamp_certificate ||=
          begin
            cert = create_cert(name: '/CN=timestamp/DC=gettalong', serial: 3,
                               public_key: signer_key, issuer: ca_certificate)
            add_extensions(cert, ca_certificate, ca_key, key_usage: 'digitalSignature',
                           extended_key_usage: 'timeStamping')
            cert
          end
      end

      def create_cert(name:, serial:, public_key:, issuer: nil)
        name = OpenSSL::X509::Name.parse(name)
        cert = OpenSSL::X509::Certificate.new
        cert.serial = serial
        cert.version = 2
        cert.not_before = Time.now - 86400
        cert.not_after = Time.now + 86400
        cert.public_key = public_key
        cert.subject = name
        cert.issuer = (issuer ? issuer.subject : name)
        cert
      end

      def add_extensions(subject_cert, issuer_cert, signing_key, is_ca: false, key_usage: nil,
                         extended_key_usage: nil)
        extension_factory = OpenSSL::X509::ExtensionFactory.new
        extension_factory.subject_certificate = subject_cert
        extension_factory.issuer_certificate = issuer_cert
        subject_cert.add_extension(extension_factory.create_extension('subjectKeyIdentifier', 'hash'))
        if is_ca
          subject_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:TRUE', true))
        else
          subject_cert.add_extension(extension_factory.create_extension('basicConstraints', 'CA:FALSE'))
        end
        if key_usage
          subject_cert.add_extension(extension_factory.create_extension('keyUsage', key_usage, true))
        end
        if extended_key_usage
          subject_cert.add_extension(extension_factory.create_extension('extendedKeyUsage',
                                                                        extended_key_usage, true))
        end
        subject_cert.sign(signing_key, OpenSSL::Digest.new('SHA1'))
      end
      private :add_extensions

      def start_tsa_server
        return if defined?(@tsa_server)
        require 'webrick'
        port = 34567
        @tsa_server = WEBrick::HTTPServer.new(Port: port, BindAddress: '127.0.0.1',
                                              Logger: WEBrick::Log.new(StringIO.new), AccessLog: [])
        @tsa_server.mount_proc('/') do |request, response|
          @tsr = OpenSSL::Timestamp::Request.new(request.body)
          case @tsr.policy_id || '1.2.3.4.0'
          when '1.2.3.4.0', '1.2.3.4.2', '1.2.3.4.3'
            if @tsr.policy_id == '1.2.3.4.3'
              WEBrick::HTTPAuth.basic_auth(request, response, 'HexaPDF Auth') do |username, password|
                username == 'hexatest' && password == 'hexapwd'
              end
            end
            fac = OpenSSL::Timestamp::Factory.new
            fac.gen_time = Time.now
            fac.serial_number = 1
            fac.default_policy_id = '1.2.3.4.5'
            fac.allowed_digests = ["sha256", "sha512"]
            tsr = fac.create_timestamp(CERTIFICATES.signer_key, CERTIFICATES.timestamp_certificate,
                                       @tsr)
            response.body = tsr.to_der
          when '1.2.3.4.1'
            response.status = 403
            response.body = "Invalid"
          end
        end
        Thread.new { @tsa_server.start }
      end

    end

  end
end

CERTIFICATES = HexaPDF::TestUtils::Certificates.new
