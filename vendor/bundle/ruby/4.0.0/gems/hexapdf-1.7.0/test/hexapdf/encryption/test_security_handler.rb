# -*- encoding: utf-8 -*-

require 'test_helper'
require 'hexapdf/encryption/security_handler'
require 'hexapdf/document'
require 'hexapdf/stream'

describe HexaPDF::Encryption::EncryptionDictionary do
  before do
    @document = HexaPDF::Document.new
    @dict = HexaPDF::Encryption::EncryptionDictionary.new({}, document: @document)
    @dict[:Filter] = :Standard
    @dict[:V] = 1
  end

  it "must be an indirect object" do
    assert(@dict.must_be_indirect?)
  end

  it "validates the /Length field when /V=2" do
    @dict[:V] = 2
    refute(@dict.validate)

    @dict[:Length] = 32
    refute(@dict.validate)
    @dict[:Length] = 136
    refute(@dict.validate)
    @dict[:Length] = 55
    refute(@dict.validate)

    @dict[:Length] = 120
    assert(@dict.validate)
  end
end

describe HexaPDF::Encryption::SecurityHandler do
  class TestHandler < HexaPDF::Encryption::SecurityHandler

    attr_accessor :strf, :myopt
    public :dict

    def prepare_encryption(**_options)
      dict[:Filter] = :Test
      @key = "a" * key_length
      @strf ||= :aes
      @stmf ||= :arc4
      @eff ||= :identity
      [@key, @strf, @stmf, @eff]
    end

    def prepare_decryption(myopt: nil)
      @myopt = myopt
      @key = "a" * key_length
    end

  end

  before do
    @document = HexaPDF::Document.new
    @obj = @document.add({})
    @handler = TestHandler.new(@document)
  end

  describe "class methods" do
    before do
      @document.config['encryption.filter_map'][:Test] = TestHandler
    end

    describe "set_up_encryption" do
      it "fails if the requested security handler cannot be found" do
        assert_raises(HexaPDF::EncryptionError) do
          HexaPDF::Encryption::SecurityHandler.set_up_encryption(@document, :non_standard)
        end
      end

      it "updates the trailer's /Encrypt entry to be wrapped by an encryption dictionary" do
        HexaPDF::Encryption::SecurityHandler.set_up_encryption(@document, :Test)
        assert_kind_of(HexaPDF::Encryption::EncryptionDictionary, @document.trailer[:Encrypt])
      end

      it "returns the frozen security handler" do
        handler = HexaPDF::Encryption::SecurityHandler.set_up_encryption(@document, :Test)
        assert(handler.frozen?)
      end
    end

    describe "set_up_decryption" do
      it "fails if the document has no /Encrypt dictionary" do
        exp = assert_raises(HexaPDF::EncryptionError) do
          HexaPDF::Encryption::SecurityHandler.set_up_decryption(@document)
        end
        assert_match(/No \/Encrypt/i, exp.message)
      end

      it "fails if the requested security handler cannot be found" do
        @document.trailer[:Encrypt] = {Filter: :NonStandard}
        assert_raises(HexaPDF::EncryptionError) do
          HexaPDF::Encryption::SecurityHandler.set_up_decryption(@document)
        end
      end

      it "updates the trailer's /Encrypt entry to be wrapped by an encryption dictionary" do
        @document.trailer[:Encrypt] = {Filter: :Test,
                                       V: HexaPDF::Object.new(1, oid: 1, document: @document)}
        HexaPDF::Encryption::SecurityHandler.set_up_decryption(@document)
        assert_kind_of(HexaPDF::Encryption::EncryptionDictionary, @document.trailer[:Encrypt])
        assert_equal({Filter: :Test, V: 1}, @document.trailer[:Encrypt].value)
      end

      it "returns the frozen security handler" do
        @document.trailer[:Encrypt] = {Filter: :Test, V: 1}
        handler = HexaPDF::Encryption::SecurityHandler.set_up_decryption(@document)
        assert(handler.frozen?)
      end
    end
  end

  it "doesn't have a valid encryption key directly after creation" do
    refute(@handler.encryption_key_valid?)
  end

  describe "set_up_encryption" do
    it "sets the correct /V value for the given key length and algorithm" do
      [[40, :arc4, 1], [128, :arc4, 2], [128, :arc4, 4],
       [128, :aes, 4], [256, :aes, 5]].each do |length, algorithm, version|
        @handler.set_up_encryption(key_length: length, algorithm: algorithm, force_v4: version == 4)
        assert_equal(version, @handler.dict[:V])
      end
    end

    it "sets the correct /Length value for the given key length" do
      [[40, nil], [48, 48], [128, 128]].each do |key_length, result|
        @handler.set_up_encryption(key_length: key_length, algorithm: :arc4)
        result.nil? ? assert_nil(@handler.dict[:Length]) : assert_equal(result, @handler.dict[:Length])
      end

      # Work-around for buggy software needing the /Length key
      @handler.set_up_encryption(key_length: 128, algorithm: :aes)
      assert_equal(4, @handler.dict[:V])
      assert_equal(128, @handler.dict[:Length])
      @handler.set_up_encryption(key_length: 256, algorithm: :aes)
      assert_equal(5, @handler.dict[:V])
      assert_equal(256, @handler.dict[:Length])
    end

    it "calls the prepare_encryption method" do
      @handler.set_up_encryption
      assert_equal(:Test, @handler.dict[:Filter])
    end

    it "returns the generated encryption dictionary wrapped in an encryption class" do
      dict = @handler.set_up_encryption
      assert_kind_of(HexaPDF::Encryption::EncryptionDictionary, dict)
    end

    it "set's up the handler for encryption" do
      [:arc4, :aes].each do |algorithm|
        @handler.set_up_encryption(key_length: 128, algorithm: algorithm)
        @obj[:X] = @handler.encrypt_string('data', @obj)
        assert_equal('data', @handler.decrypt(@obj)[:X])
      end
    end

    it "generates a valid encryption key" do
      @document.trailer[:Encrypt] = @handler.set_up_encryption
      assert(@handler.encryption_key_valid?)
    end

    it "provides correct encryption details" do
      @handler.set_up_encryption
      assert_equal({version: 4, string_algorithm: :aes, stream_algorithm: :arc4,
                    embedded_file_algorithm: :identity, key_length: 128},
                   @handler.encryption_details)
      assert_equal(HexaPDF::Encryption::Identity, @handler.send(:embedded_file_algorithm))
      assert_equal(HexaPDF::Encryption::FastAES, @handler.send(:string_algorithm))
      assert_equal(HexaPDF::Encryption::FastARC4, @handler.send(:stream_algorithm))
    end

    it "fails for unsupported encryption key lengths" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_encryption(key_length: 43)
      end
      assert_match(/Invalid key length/i, exp.message)
    end

    it "fails for unsupported encryption algorithms" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_encryption(algorithm: :test)
      end
      assert_match(/Unsupported encryption algorithm/i, exp.message)
    end

    it "fails for the aes algorithm with key lengths != 128 or 256" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_encryption(algorithm: :aes, key_length: 40)
      end
      assert_match(/AES algorithm.*key length/i, exp.message)
    end

    it "fails for the arc4 algorithm with a key length of 256" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_encryption(algorithm: :arc4, key_length: 256)
      end
      assert_match(/ARC4 algorithm.*key length/i, exp.message)
    end
  end

  describe "set_up_decryption" do
    it "wraps the given hash in an encryption dictionary class, uses it for its dict, returns it" do
      dict = @handler.set_up_decryption({Filter: :test, V: 1})
      assert_equal(dict, @handler.dict)
      assert_kind_of(HexaPDF::Encryption::EncryptionDictionary, @handler.dict)
      assert_equal({Filter: :test, V: 1}, @handler.dict.value)
    end

    it "doesn't modify the trailer's /Encrypt dictionary" do
      @handler.set_up_decryption({Filter: :test, V: 4, Length: 128})
      assert_nil(@document.trailer[:Encrypt])
    end

    it "calls prepare_decryption" do
      @handler.set_up_decryption({Filter: :test, V: 4, Length: 128}, myopt: 5)
      assert_equal(5, @handler.myopt)
    end

    it "selects the correct algorithm based on the /V and /CF values" do
      @enc = @handler.dup

      [
        [:arc4, 40, {V: 1}],
        [:arc4, 80, {V: 2, Length: 80}],
        [:arc4, 128, {V: 4, StrF: :Mine, CF: {Mine: {CFM: :V2}}}],
        [:aes, 128, {V: 4, StrF: :Mine, CF: {Mine: {CFM: :AESV2}}}],
        [:aes, 256, {V: 5, StrF: :Mine, CF: {Mine: {CFM: :AESV3}}}],
        [:identity, 128, {V: 4, StrF: :Mine, CF: {Mine: {CFM: :None}}}],
        [:identity, 128, {V: 4, CF: {Mine: {CFM: :AESV2}}}],
      ].each do |alg, length, dict|
        dict[:Filter] = :Test
        @enc.strf = alg
        @enc.set_up_encryption(key_length: length, algorithm: (alg == :identity ? :aes : alg))
        @obj[:X] = @enc.encrypt_string(+'data', @obj)
        @handler.set_up_decryption(dict)
        assert_equal('data', @handler.decrypt(@obj)[:X])
      end
    end

    it "selects the correct algorithm for string, stream and embedded file decryption" do
      @handler.set_up_decryption({Filter: :Test, V: 4, StrF: :Mine, StmF: :Mine, EFF: :Mine,
                                  CF: {Mine: {CFM: :V2}}})
      assert_equal(HexaPDF::Encryption::FastARC4, @handler.send(:embedded_file_algorithm))
      assert_equal(HexaPDF::Encryption::FastARC4, @handler.send(:string_algorithm))
      assert_equal(HexaPDF::Encryption::FastARC4, @handler.send(:stream_algorithm))
    end

    it "provides correct encryption details" do
      @handler.set_up_decryption({Filter: :test, V: 2, Length: 128}, myopt: 5)
      assert_equal({version: 2, string_algorithm: :arc4, stream_algorithm: :arc4,
                    embedded_file_algorithm: :arc4, key_length: 128},
                   @handler.encryption_details)
    end

    it "fails if the encryption dictionary is not valid" do
      exp = assert_raises(HexaPDF::Error) do
        @handler.set_up_decryption({V: 5})
      end
      assert_match(/Validation error for encryption dictionary.*Required field Filter/i, exp.message)
    end

    it "fails for unsupported /V values in the dict" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_decryption({Filter: :Text, V: 3})
      end
      assert_match(/Unsupported encryption version/i, exp.message)
    end

    it "fails for unsupported crypt filter encryption methods" do
      exp = assert_raises(HexaPDF::UnsupportedEncryptionError) do
        @handler.set_up_decryption({Filter: :Test, V: 4, StrF: :Mine, CF: {Mine: {CFM: :Unknown}}})
      end
      assert_match(/Unsupported encryption method/i, exp.message)
    end
  end

  describe "decrypt" do
    before do
      @handler.set_up_decryption({Filter: :Test, V: 1})
      @encrypted = @handler.encrypt_string('string', @obj)
      @obj.value = {Key: @encrypted.dup, Array: [@encrypted.dup], Hash: {Another: @encrypted.dup}}
    end

    it "decrypts all strings in an object" do
      @handler.decrypt(@obj)
      assert_equal('string', @obj[:Key])
      assert_equal('string', @obj[:Array][0])
      assert_equal('string', @obj[:Hash][:Another])
    end

    it "decrypts the content of a stream object" do
      data = HexaPDF::StreamData.new(proc { @encrypted })
      obj = @document.wrap({}, oid: @obj.oid, stream: data)
      @handler.decrypt(obj)
      assert_equal('string', obj.stream)
    end

    it "doesn't decrypt a document's Encrypt dictionaries" do
      @document = HexaPDF::Document.new
      @document.trailer[:Encrypt] = @document.add({Key: "Something"})
      @document.revisions.add
      @document.trailer[:Encrypt] = @document.add({Key: "Otherthing"})
      @handler = TestHandler.new(@document)

      assert_equal("Something",
                   @handler.decrypt(@document.revisions.all[0].trailer[:Encrypt])[:Key])
      assert_equal("Otherthing",
                   @handler.decrypt(@document.revisions.all[1].trailer[:Encrypt])[:Key])
    end

    it "defers handling encryption to a Crypt filter is specified" do
      data = HexaPDF::StreamData.new(proc { 'mydata' }, filter: :Crypt)
      obj = @document.wrap({}, oid: 1, stream: data)
      @handler.decrypt(obj)
      assert_equal('mydata', obj.stream)
    end

    it "doesn't decrypt XRef streams" do
      @obj[:Type] = :XRef
      assert_equal(@encrypted, @handler.decrypt(@obj)[:Key])
    end

    it "doesn't decrypt the /Contents of a signature dictionary" do
      @obj[:Type] = :Sig
      @obj[:Contents] = "test"
      assert_equal("test", @handler.decrypt(@obj)[:Contents])
    end

    it "enhances a thrown EncryptionError by setting the PDF object" do
      @document.config['encryption.on_decryption_error'] = proc { true }
      @handler.set_up_encryption(key_length: 256)
      error = assert_raises(HexaPDF::EncryptionError) { @handler.decrypt(@obj) }
      assert_match(/Object \(1,0\):/, error.message)
    end

    it "uses the encryption.on_decryption_error configuration option" do
      @handler.set_up_encryption(key_length: 256)
      @handler.decrypt(@obj)
      assert_equal('', @obj[:Key])

      @obj[:Key] = @encrypted
      called = false
      @document.config['encryption.on_decryption_error'] = proc do |obj, msg|
        assert_same(@obj, obj)
        assert_match(/32 \+ 16/, msg)
        called = true
      end
      assert_raises(HexaPDF::EncryptionError) { @handler.decrypt(@obj) }
      assert(called)
    end

    it "fails if V < 5 and the object number changes" do
      @obj.oid = 55
      @handler.decrypt(@obj)
      refute_equal('string', @obj[:Key])
    end
  end

  describe "encryption" do
    before do
      @handler.set_up_encryption(key_length: 128, algorithm: :arc4)
      @stream = @document.wrap({}, oid: 1, stream: HexaPDF::StreamData.new(proc { "string" }))
    end

    it "encrypts strings of indirect objects" do
      @obj[:Key] = @handler.encrypt_string('string', @obj)
      assert_equal('string', @handler.decrypt(@obj)[:Key])
    end

    it "encrypts streams" do
      result = collector(@handler.encrypt_stream(@stream))
      @stream.stream = HexaPDF::StreamData.new(proc { result })
      assert_equal('string', @handler.decrypt(@stream).stream)
    end

    it "doesn't encrypt strings in a document's Encrypt dictionary" do
      @document.trailer[:Encrypt] = @handler.dict
      str = 'string'
      result = @handler.encrypt_string(str, @document.trailer[:Encrypt])
      assert_equal('string', result)
      refute_same(str, result)
    end

    it "doesn't encrypt XRef streams" do
      @stream[:Type] = :XRef
      assert_equal('string', @handler.encrypt_stream(@stream).resume)
    end

    it "defers encrypting to a Crypt filter if specified" do
      @stream.set_filter(:Crypt)
      assert_equal('string', @handler.encrypt_stream(@stream).resume)

      @stream.set_filter([:Crypt])
      assert_equal('string', @handler.encrypt_stream(@stream).resume)
    end

    it "doesn't encrypt the /Contents key of signature dictionaries" do
      @obj[:Type] = :Sig
      @obj[:Contents] = "test"
      refute_equal('test', @handler.encrypt_string("test", @obj))
      assert_equal('test', @handler.encrypt_string(@obj[:Contents], @obj))
    end
  end

  it "works correctly with different decryption and encryption handlers" do
    test_file = File.join(TEST_DATA_DIR, 'standard-security-handler', 'nopwd-arc4-40bit-V1.pdf')
    doc = HexaPDF::Document.new(io: StringIO.new(File.binread(test_file)))
    doc.encrypt(algorithm: :aes, password: 'test')
    out = StringIO.new(''.b)
    doc.write(out, update_fields: false)

    assert_raises(HexaPDF::EncryptionError) { HexaPDF::Document.new(io: out) }
    doc = HexaPDF::Document.new(io: out, decryption_opts: {password: 'test'})
    assert_equal('D:20150409164600', doc.trailer[:Info].value[:ModDate])
  end
end
