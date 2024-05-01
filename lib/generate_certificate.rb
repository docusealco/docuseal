# frozen_string_literal: true

module GenerateCertificate
  SIZE = 2**11

  Pkcs12Struct = Struct.new(:certificate, :ca_certs, keyword_init: true)

  module_function

  def call(name = Docuseal.product_name)
    root_cert, root_key = generate_root_ca(name)

    sub_cert, sub_key = generate_sub_ca(name, root_cert, root_key)
    cert, key = generate_certificate(name, sub_cert, sub_key)

    {
      cert:,
      key:,
      root_ca: root_cert,
      root_key:,
      sub_ca: sub_cert,
      sub_key:
    }
  end

  def generate_root_ca(name)
    key = OpenSSL::PKey::RSA.new(SIZE)

    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.parse("/C=AT/O=#{name}/CN=#{name} Root CA")
    cert.issuer = cert.subject
    cert.not_before = Time.current
    cert.not_after = 100.years.from_now
    cert.public_key = key.public_key
    cert.serial = OpenSSL::BN.rand(160)

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
    cert.add_extension(ef.create_extension('keyUsage', 'Certificate Sign, CRL Sign', true))
    cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
    cert.sign(key, OpenSSL::Digest.new('SHA256'))

    [cert, key]
  end

  def generate_sub_ca(name, root_ca_cert, root_ca_key)
    key = OpenSSL::PKey::RSA.new(SIZE)

    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.parse("/C=AT/O=#{name}/CN=#{name} Sub-CA")
    cert.issuer = root_ca_cert.subject
    cert.not_before = Time.current
    cert.not_after = 100.years.from_now
    cert.public_key = key.public_key
    cert.serial = OpenSSL::BN.rand(160)

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = root_ca_cert
    cert.add_extension(ef.create_extension('basicConstraints', 'CA:TRUE', true))
    cert.add_extension(ef.create_extension('keyUsage', 'Certificate Sign, CRL Sign', true))
    cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
    cert.sign(root_ca_key, OpenSSL::Digest.new('SHA256'))

    [cert, key]
  end

  def generate_certificate(name, ca_cert, ca_key)
    key = OpenSSL::PKey::RSA.new(SIZE)

    cert = OpenSSL::X509::Certificate.new
    cert.subject = OpenSSL::X509::Name.parse("/C=AT/O=#{name}/CN=#{name}")
    cert.issuer = ca_cert.subject
    cert.not_before = Time.current
    cert.not_after = 100.years.from_now
    cert.public_key = key.public_key
    cert.serial = OpenSSL::BN.rand(160)

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert
    cert.add_extension(ef.create_extension('basicConstraints', 'CA:FALSE', true))
    cert.add_extension(ef.create_extension('keyUsage', 'Digital Signature', true))
    cert.add_extension(ef.create_extension('subjectKeyIdentifier', 'hash', false))
    cert.sign(ca_key, OpenSSL::Digest.new('SHA256'))

    [cert, key]
  end

  def load_pkcs(cert_data)
    cert = OpenSSL::X509::Certificate.new(cert_data['cert'])
    key = OpenSSL::PKey::RSA.new(cert_data['key']) if cert_data['key'].present?
    sub_ca = OpenSSL::X509::Certificate.new(cert_data['sub_ca'])
    root_ca = OpenSSL::X509::Certificate.new(cert_data['root_ca'])

    return Pkcs12Struct.new(certificate: cert, ca_certs: [sub_ca, root_ca]) unless key

    OpenSSL::PKCS12.create(
      '',
      '',
      key,
      cert,
      [sub_ca, root_ca]
    )
  end
end
