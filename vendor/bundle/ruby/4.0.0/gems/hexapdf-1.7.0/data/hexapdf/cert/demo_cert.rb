require 'hexapdf'
require 'openssl'

DemoCertData = Struct.new(:key, :cert, :sub_ca, :root_ca)

module HexaPDF

  class << self
    attr_reader :demo_cert
  end

  cert_file = File.join(__dir__, 'signing.crt')
  key_file = File.join(__dir__, 'signing.key')
  sub_ca_cert_file = File.join(__dir__, 'sub-ca.crt')
  root_ca_cert_file = File.join(__dir__, 'root-ca.crt')

  @demo_cert = DemoCertData.new(OpenSSL::PKey::RSA.new(File.read(key_file)),
                                OpenSSL::X509::Certificate.new(File.read(cert_file)),
                                OpenSSL::X509::Certificate.new(File.read(sub_ca_cert_file)),
                                OpenSSL::X509::Certificate.new(File.read(root_ca_cert_file)))

end
