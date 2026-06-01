# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'digest/md5'
require 'hexapdf/error'
require 'hexapdf/dictionary'
require 'hexapdf/stream'

module HexaPDF
  module Encryption

    # Base class for all encryption dictionaries.
    #
    # Contains entries common to all encryption dictionaries. If a specific security handler
    # needs further fields it should derive a new subclass and add the new fields there.
    #
    # See: PDF2.0 s7.6.2
    class EncryptionDictionary < Dictionary

      define_field :Filter,    type: Symbol, required: true
      define_field :SubFilter, type: Symbol, version: '1.3'
      define_field :V,         type: Integer, required: true, allowed_values: [0, 1, 2, 3, 4, 5]
      define_field :Lenth,     type: Integer, default: 40, version: '1.4'
      define_field :CF,        type: Dictionary, version: '1.5'
      define_field :StmF,      type: Symbol, default: :Identity, version: '1.5'
      define_field :StrF,      type: Symbol, default: :Identity, version: '1.5'
      define_field :EFF,       type: Symbol, version: '1.6'

      # Returns +true+ because some PDF readers stumble when encountering a non-indirect encryption
      # dictionary.
      def must_be_indirect?
        true
      end

      private

      # Ensures that the encryption dictionary's content is valid.
      def perform_validation
        super
        length = self[:Length]
        if self[:V] == 2 && (!key?(:Length) || length < 40 || length > 128 || length % 8 != 0)
          yield("Invalid value for /Length field when /V is 2", false)
        end
      end

    end

    # Base class for all security handlers.
    #
    # == Creating SecurityHandler Instances
    #
    # The base class provides two class methods for this:
    #
    # * The method ::set_up_encryption is used when a security handler instance should be created
    #   that populates the document's encryption dictionary.
    #
    # * The method ::set_up_decryption is used when a security handler should be created from the
    #   document's encryption dictionary.
    #
    # It is *not* recommended to create security handlers manually but only with those two methods
    # listed above.
    #
    #
    # == Using SecurityHandler Instances
    #
    # The SecurityHandler base class provides the methods for decrypting an indirect object and for
    # encrypting strings and streams:
    #
    # * #decrypt
    # * #encrypt_string
    # * #encrypt_stream
    #
    # How the decryption/encryption key is actually computed is deferred to a sub class, as per the
    # PDF specification.
    #
    # Additionally, the #encryption_key_valid? method can be used to check whether the
    # SecurityHandler instance is built from/built for the current version of the encryption
    # dictionary.
    #
    # Note that any manual changes to the encryption dictionary will invalidate the key and lead to
    # an error!
    #
    #
    # == Implementing a SecurityHandler Class
    #
    # Each security handler has to implement the following methods:
    #
    # prepare_encryption(**options)::
    #   Prepares the security handler for use in encrypting the document.
    #
    #   See the #set_up_encryption documentation for information on which options are passed on to
    #   this method.
    #
    #   Returns the encryption key as well as the names of the string, stream and embedded file
    #   algorithms.
    #
    # prepare_decryption(**options)::
    #   Prepares the security handler for decryption by using the information from the document's
    #   encryption dictionary as well as the provided arguments.
    #
    #   See the #set_up_decryption documentation for additional information.
    #
    #   Returns the encryption key that should be used for decryption.
    #
    # Additionally, the following methods can be overridden to provide a more specific meaning:
    #
    # encryption_dictionary_class::
    #   Returns the class that is used for the encryption dictionary. Should be derived from the
    #   EncryptionDictionary class.
    class SecurityHandler

      # Provides additional encryption specific information for HexaPDF::StreamData objects.
      class EncryptedStreamData < StreamData

        # The encryption key.
        attr_reader :key

        # The encryption algorithm.
        attr_reader :algorithm

        # Creates a new encrypted stream data object by utilizing the given stream data object +obj+
        # as template. The arguments +key+ and +algorithm+ are used for decrypting purposes.
        def initialize(obj, key, algorithm, &error_block)
          obj.instance_variables.each {|v| instance_variable_set(v, obj.instance_variable_get(v)) }
          @key = key
          @algorithm = algorithm
          @error_block = error_block
        end

        alias undecrypted_fiber fiber

        # Returns a fiber like HexaPDF::StreamData#fiber, but one wrapped in a decrypting fiber.
        def fiber(*args)
          @algorithm.decryption_fiber(@key, super(*args), &@error_block)
        end

      end

      # :call-seq:
      #   SecurityHandler.set_up_encryption(document, handler_name, **options)   -> handler
      #
      # Sets up and returns the security handler with the specified name for the document and
      # modifies then document's encryption dictionary accordingly.
      #
      # The +encryption_opts+ can contain any encryption options for the specific security handler
      # and the common encryption options.
      #
      # See: #set_up_encryption (for the common encryption options).
      def self.set_up_encryption(document, handler_name, **options)
        handler = document.config.constantize('encryption.filter_map', handler_name) do
          document.config.constantize('encryption.sub_filter_map', handler_name) do
            raise HexaPDF::EncryptionError, "Could not find the specified security handler"
          end
        end

        handler = handler.new(document)
        document.trailer[:Encrypt] = handler.set_up_encryption(**options)
        handler.freeze
      end

      # :call-seq:
      #   SecurityHandler.set_up_decryption(document, **options)   -> handler
      #
      # Sets up and returns the security handler that is used for decrypting the given document and
      # modifies the document's object loader so that the decryption is handled automatically behind
      # the scenes.
      #
      # The +decryption_opts+ has to contain decryption options specific to the security handler
      # that is used by the PDF file.
      #
      # See: #set_up_decryption
      def self.set_up_decryption(document, **options)
        dict = document.trailer[:Encrypt]
        if dict.nil?
          raise HexaPDF::EncryptionError, "No /Encrypt dictionary found"
        end
        handler = document.config.constantize('encryption.filter_map', dict[:Filter]) do
          document.config.constantize('encryption.sub_filter_map', dict[:SubFilter]) do
            raise HexaPDF::EncryptionError, "Could not find a suitable security handler"
          end
        end

        handler = handler.new(document)
        dict = document.trailer[:Encrypt] = handler.set_up_decryption(dict, **options)
        HexaPDF::Object.make_direct(dict.value, document)
        document.revisions.current.update(dict)
        document.revisions.each do |r|
          loader = r.loader
          r.loader = lambda do |xref_entry|
            obj = loader.call(xref_entry)
            xref_entry.compressed? ? obj : handler.decrypt(obj)
          end
        end

        handler.freeze
      end

      # A hash containing information about the used encryption. This information is only
      # available once the security handler has been set up for decryption or encryption.
      #
      # Available keys:
      #
      # :version::
      #    The version of the security handler in use.
      # :string_algorithm::
      #    The algorithm used for encrypting/decrypting strings.
      # :stream_algorithm::
      #    The algorithm used for encrypting/decrypting streams.
      # :embedded_file_algorithm::
      #    The algorithm used for encrypting/decrypting embedded files.
      # :key_length::
      #    The key length in bits.
      attr_reader :encryption_details

      # Creates a new SecurityHandler for the given document.
      def initialize(document)
        @document = document
        @encrypt_dict_hash = nil
        @encryption_details = {}

        @is_encrypt_dict = document.revisions.each.with_object({}) do |rev, hash|
          hash[rev.trailer[:Encrypt]] = true
        end
      end

      # Checks if the encryption key computed by this security handler is derived from the
      # document's encryption dictionary.
      def encryption_key_valid?
        document.unwrap(document.trailer[:Encrypt]).hash == @encrypt_dict_hash
      end

      # Decrypts the strings and the possibly attached stream of the given indirect object in
      # place.
      #
      # See: PDF2.0 s7.6.3
      def decrypt(obj)
        return obj if @is_encrypt_dict[obj] || obj.type == :XRef

        error_proc = proc {|msg| document.config['encryption.on_decryption_error'].call(obj, msg) }
        key = object_key(obj.oid, obj.gen, string_algorithm)
        each_string_in_object(obj.value) do |str|
          next if str.empty? || (obj.type == :Sig && obj[:Contents].equal?(str))
          str.replace(string_algorithm.decrypt(key, str, &error_proc))
        end

        if obj.kind_of?(HexaPDF::Stream) && obj.raw_stream.filter[0] != :Crypt
          unless string_algorithm == stream_algorithm
            key = object_key(obj.oid, obj.gen, stream_algorithm)
          end
          obj.data.stream = EncryptedStreamData.new(obj.raw_stream, key, stream_algorithm, &error_proc)
        end

        obj
      rescue EncryptionError => e
        e.pdf_object = obj
        raise
      end

      # Returns the encrypted version of the string that resides in the given indirect object.
      #
      # Note that some strings won't be encrypted as per the specification. The returned string,
      # however, is always a different object.
      #
      # See: PDF2.0 s7.6.3
      def encrypt_string(str, obj)
        return str.dup if str.empty? || obj == document.trailer[:Encrypt] || obj.type == :XRef ||
          (obj.type == :Sig && obj[:Contents].equal?(str))

        key = object_key(obj.oid, obj.gen, string_algorithm)
        string_algorithm.encrypt(key, str)
      end

      # Returns a Fiber that encrypts the contents of the given stream object.
      #
      # Note that some streams *must not be* encrypted. For those, their standard stream encoding
      # fiber is returned.
      def encrypt_stream(obj)
        return obj.stream_encoder if obj.type == :XRef

        key = object_key(obj.oid, obj.gen, stream_algorithm)
        source = obj.stream_source
        result = obj.stream_encoder(source)
        if result == source && obj.raw_stream.kind_of?(EncryptedStreamData) &&
            obj.raw_stream.key == key && obj.raw_stream.algorithm == stream_algorithm
          obj.raw_stream.undecrypted_fiber
        else
          filter = obj[:Filter]
          if filter == :Crypt || (filter.kind_of?(PDFArray) && filter[0] == :Crypt)
            result
          else
            stream_algorithm.encryption_fiber(key, result)
          end
        end
      end

      # Computes the encryption key, sets up the algorithms for encrypting the document based on the
      # given options, and returns the corresponding encryption dictionary.
      #
      # The security handler specific +options+ as well as the +algorithm+ argument are passed on to
      # the #prepare_encryption method.
      #
      # Options for all security handlers:
      #
      # key_length::
      #   The key length in bits. Possible values are in the range of 40 to 128 and 256 and it
      #   needs to be divisible by 8.
      #
      # algorithm::
      #   The encryption algorithm. Possible values are :arc4 for ARC4 encryption with key lengths
      #   of 40 to 128 bit or :aes for AES encryption with key lengths of 128 or 256 bit.
      #
      # force_v4::
      #   Forces the use of protocol version 4 when key_length=128 and algorithm=:arc4.
      #
      # See: PDF2.0 s7.6.2
      def set_up_encryption(key_length: 128, algorithm: :aes, force_v4: false, **options)
        @dict = document.wrap({}, type: encryption_dictionary_class)

        dict[:V] =
          case key_length
          when 40
            1
          when 48, 56, 64, 72, 80, 88, 96, 104, 112, 120
            2
          when 128
            (algorithm == :aes || force_v4 ? 4 : 2)
          when 256
            5
          else
            raise(HexaPDF::UnsupportedEncryptionError,
                  "Invalid key length #{key_length} specified")
          end
        # /Length should only be set for V=2 as per the spec. However, software like Adobe Reader
        # fails if this is not set for V=5 or V=4.
        dict[:Length] = key_length if dict[:V] == 5 || dict[:V] == 4 || dict[:V] == 2

        if ![:aes, :arc4].include?(algorithm)
          raise(HexaPDF::UnsupportedEncryptionError,
                "Unsupported encryption algorithm: #{algorithm}")
        elsif key_length < 128 && algorithm == :aes
          raise(HexaPDF::UnsupportedEncryptionError,
                "AES algorithm needs a key length of 128 or 256 bit")
        elsif key_length == 256 && algorithm == :arc4
          raise(HexaPDF::UnsupportedEncryptionError,
                "ARC4 algorithm can only be used with key lengths between 40 and 128 bit")
        end

        result = prepare_encryption(algorithm: algorithm, **options)
        @encrypt_dict_hash = document.unwrap(dict).hash
        set_up_security_handler(*result)
        @dict
      end

      # Uses the given encryption dictionary to set up the security handler for decrypting the
      # document.
      #
      # The security handler specific +options+ are passed on to the #prepare_decryption method.
      #
      # See: PDF2.0 s7.6.2
      def set_up_decryption(dictionary, **options)
        @dict = document.wrap(dictionary, type: encryption_dictionary_class)
        @dict.validate do |msg, correctable, obj|
          next if correctable
          raise HexaPDF::Error, "Validation error for encryption dictionary (#{obj.oid},#{obj.gen}): #{msg}"
        end

        case dict[:V]
        when 1, 2
          strf = stmf = eff = :arc4
        when 4, 5
          strf, stmf, eff = [:StrF, :StmF, :EFF].map do |alg|
            if dict[:CF] && (cf_dict = dict[:CF][dict[alg]])
              case cf_dict[:CFM]
              when :V2 then :arc4
              when :AESV2, :AESV3 then :aes
              when :None then :identity
              else
                raise(HexaPDF::UnsupportedEncryptionError,
                      "Unsupported encryption method: #{cf_dict[:CFM]}")
              end
            else
              :identity
            end
          end
          eff = stmf unless dict[:EFF]
        else
          raise HexaPDF::UnsupportedEncryptionError, "Unsupported encryption version #{dict[:V]}"
        end

        set_up_security_handler(prepare_decryption(**options), strf, stmf, eff)
        @encrypt_dict_hash = document.unwrap(@dict).hash

        @dict
      end

      private

      # Returns the associated PDF document.
      #
      # Subclasses should use this method to access the document.
      def document
        @document
      end

      # Returns the encryption dictionary used by this security handler.
      #
      # Subclasses should use this dictionary to read and set values.
      def dict
        @dict
      end

      # Returns the encryption key that is used for encryption/decryption.
      #
      # Only available after decryption or encryption has been set up.
      def encryption_key
        @encryption_key
      end

      # Returns the algorithm class that is used for encrypting/decrypting strings.
      #
      # Only available after decryption or encryption has been set up.
      def string_algorithm
        @string_algorithm
      end

      # Returns the algorithm class that is used for encrypting/decrypting streams.
      #
      # Only available after decryption or encryption has been set up.
      def stream_algorithm
        @stream_algorithm
      end

      # Returns the algorithm class that is used for encrypting/decrypting embedded files.
      #
      # Only available after decryption or encryption has been set up.
      def embedded_file_algorithm
        @embedded_file_algorithm
      end

      # Assigns all necessary attributes so that encryption/decryption works correctly.
      #
      # The assigned values can be retrieved via the #encryption_key, #string_algorithm,
      # #stream_algorithm and #embedded_file_algorithm methods.
      def set_up_security_handler(key, strf, stmf, eff)
        @encryption_key = key
        @string_algorithm = send("#{strf}_algorithm")
        @stream_algorithm = send("#{stmf}_algorithm")
        @embedded_file_algorithm = send("#{eff}_algorithm")
        @encryption_details = {
          version: dict[:V],
          string_algorithm: strf,
          stream_algorithm: stmf,
          embedded_file_algorithm: eff,
          key_length: key_length * 8,
        }
      end

      # Returns the class that is used for ARC4 encryption.
      def arc4_algorithm
        @arc4_algorithm ||= document.config.constantize('encryption.arc4')
      end

      # Returns the class that is used for AES encryption.
      def aes_algorithm
        @aes_algorithm ||= document.config.constantize('encryption.aes')
      end

      # Returns the class that is used for the identity algorithm which passes back the data as is
      # without encrypting or decrypting it.
      def identity_algorithm
        Identity
      end

      # Computes the key for decrypting the indirect object with the given algorithm.
      #
      # See: PDF2.0 s7.6.3.2 (algorithm 1), PDF2.0 s7.6.3.3 (algorithm 1.A)
      def object_key(oid, gen, algorithm)
        key = encryption_key
        return key if dict[:V] == 5

        key += [oid, gen].pack('VXv')
        key << "sAlT" if algorithm.ancestors.include?(AES)
        n_plus_5 = key_length + 5
        Digest::MD5.digest(key)[0, (n_plus_5 > 16 ? 16 : n_plus_5)]
      end

      # Returns the length of the encryption key in bytes based on the security handlers version.
      #
      # See: PDF2.0 s7.6.2
      def key_length
        case dict[:V]
        when 1 then 5
        when 2 then dict[:Length] / 8
        when 4 then 16 # PDF2.0 s7.6.2 specifies that a /V of 4 is equal to length of 128bit
        when 5 then 32 # PDF2.0 s7.6.2 specifies that a /V of 5 is equal to length of 256bit
        end
      end

      # Returns the class used as wrapper for the encryption dictionary.
      def encryption_dictionary_class
        EncryptionDictionary
      end

      # Returns +n+ random bytes.
      def random_bytes(n)
        aes_algorithm.random_bytes(n)
      end

      # Finds all strings in the given object and yields them.
      #
      # Note: Decryption happens directly after parsing and loading an object, before it can be
      # touched by anthing else. Therefore we only have to contend with the basic data structures.
      def each_string_in_object(obj, &block) # :yields: str
        case obj
        when Hash
          obj.each_value {|val| each_string_in_object(val, &block) }
        when Array
          obj.each {|inner_o| each_string_in_object(inner_o, &block) }
        when String
          yield(obj)
        end
      end

    end

  end
end
