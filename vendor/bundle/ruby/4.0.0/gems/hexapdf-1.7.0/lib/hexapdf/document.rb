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

require 'stringio'
require 'hexapdf/error'
require 'hexapdf/data_dir'
require 'hexapdf/content'
require 'hexapdf/configuration'
require 'hexapdf/reference'
require 'hexapdf/object'
require 'hexapdf/pdf_array'
require 'hexapdf/stream'
require 'hexapdf/name_tree_node'
require 'hexapdf/number_tree_node'
require 'hexapdf/revisions'
require 'hexapdf/type'
require 'hexapdf/task'
require 'hexapdf/encryption'
require 'hexapdf/writer'
require 'hexapdf/importer'
require 'hexapdf/image_loader'
require 'hexapdf/font_loader'
require 'hexapdf/layout'
require 'hexapdf/digital_signature'
require 'hexapdf/utils'

begin
  require 'hexapdf/cext'
rescue LoadError
  # ignore error because the C-extension only makes things faster
end

# == HexaPDF API Documentation
#
# Here are some pointers to more in depth information:
#
# * HexaPDF::CLI has information about the accompanying command line application.
# * HexaPDF::Document provides information about how to work with a PDF file.
# * HexaPDF::Composer is the main class for easily creating PDF documents from scratch.
# * HexaPDF::Content::Canvas provides the canvas API for drawing/writing on a page or form XObject
# * HexaPDF::Type::AcroForm::Form is the entry point for working with interactive forms.
# * HexaPDF::Type::Outline has information on working with outlines/bookmarks.
# * HexaPDF::Encryption provides information on how encryption works.
# * HexaPDF::DigitalSignature is the entry point for working with digital signaturs.
module HexaPDF

  autoload(:Composer, 'hexapdf/composer')

  # == HexaPDF::Document
  #
  # Represents a PDF document.
  #
  # A PDF document essentially consists of (indirect) objects, so the main job of this class is to
  # provide methods for working with these objects. However, since a PDF document may also be
  # incrementally updated and can therefore contain one or more revisions, there are also methods
  # for working with these revisions (see Revisions for details).
  #
  # Additionally, there are many convenience methods for easily accessing the most important PDF
  # functionality, like encrypting a document (#encrypt), working with digital signatures
  # (#signatures), accessing the interactive form data (#acro_form), working with the pages
  # (#pages), fonts (#fonts) and images (#images).
  #
  # Note: This class provides the basis for working with a PDF document. The higher PDF
  # functionality is *not* implemented here but either in the appropriate PDF type classes or in
  # special convenience classes. All this functionality can be accessed via the convenience methods
  # described above.
  #
  # == Available Message Hooks
  #
  # The document object provides a basic message dispatch system via #register_listener and
  # #dispatch_message.
  #
  # Following messages are used by HexaPDF itself:
  #
  # :complete_objects::
  #      This message is called before the first step of writing a document. Listeners should
  #      complete PDF objects that are missing some information.
  #
  #      For example, the font system uses this message to complete the font objects with
  #      information that is only available once all the used glyphs are known.
  #
  # :before_write::
  #      This message is called before a document is actually serialized and written.
  class Document

    autoload(:Pages, 'hexapdf/document/pages')
    autoload(:Fonts, 'hexapdf/document/fonts')
    autoload(:Images, 'hexapdf/document/images')
    autoload(:Files, 'hexapdf/document/files')
    autoload(:Destinations, 'hexapdf/document/destinations')
    autoload(:Layout, 'hexapdf/document/layout')
    autoload(:Metadata, 'hexapdf/document/metadata')
    autoload(:Annotations, 'hexapdf/document/annotations')

    # :call-seq:
    #   Document.open(filename, **docargs)                   -> doc
    #   Document.open(filename, **docargs) {|doc| block}     -> obj
    #
    # Creates a new PDF Document object for the given file.
    #
    # Depending on whether a block is provided, the functionality is different:
    #
    # * If no block is provided, the whole file is instantly read into memory and the PDF Document
    #   created for it is returned.
    #
    # * If a block is provided, the file is opened and a PDF Document is created for it. The
    #   created document is passed as an argument to the block and when the block returns the
    #   associated file object is closed. The value of the block will be returned.
    #
    # The block version is useful, for example, when you are dealing with a large file and you
    # only need a small portion of it.
    #
    # The provided keyword arguments (except +io+) are passed on unchanged to Document.new.
    def self.open(filename, **kwargs)
      if block_given?
        File.open(filename, 'rb') do |file|
          yield(new(**kwargs, io: file))
        end
      else
        new(**kwargs, io: StringIO.new(File.binread(filename)))
      end
    end

    # The configuration object for the document.
    #
    # See Configuration for details.
    attr_reader :config

    # The revisions of the document.
    #
    # See Revisions.
    attr_reader :revisions

    # Creates a new PDF document, either an empty one or one read from the provided +io+.
    #
    # When an IO object is provided and it contains an encrypted PDF file, it is automatically
    # decrypted behind the scenes. The +decryption_opts+ argument has to be set appropriately in
    # this case. In case this is not wanted, the configuration option 'document.auto_decrypt' needs
    # to be used.
    #
    # Options:
    #
    # io::
    #     If an IO object is provided, then this document can read PDF objects from this IO object,
    #     otherwise it can only contain created PDF objects.
    #
    # decryption_opts::
    #     A hash with options for decrypting the PDF objects loaded from the IO. The PDF standard
    #     security handler expects a :password key to be set to either the user or owner password of
    #     the PDF file.
    #
    # config::
    #     A hash with configuration options that is deep-merged into the default configuration (see
    #     HexaPDF::DefaultDocumentConfiguration[../index.html#DefaultDocumentConfiguration], meaning
    #     that direct sub-hashes are merged instead of overwritten.
    def initialize(io: nil, decryption_opts: {}, config: {})
      @config = Configuration.with_defaults(config)
      @version = '1.2'
      @cache = Hash.new {|h, k| h[k] = {} }
      @listeners = {}

      @revisions = Revisions.from_io(self, io)
      @security_handler = if encrypted? && @config['document.auto_decrypt']
                            Encryption::SecurityHandler.set_up_decryption(self, **decryption_opts)
                          else
                            nil
                          end
    end

    # :call-seq:
    #   doc.object(ref)    -> obj or nil
    #   doc.object(oid)    -> obj or nil
    #
    # Returns the current version of the indirect object for the given exact reference (see
    # Reference) or for the given object number.
    #
    # For references to unknown objects, +nil+ is returned but free objects are represented by a
    # PDF Null object, not by +nil+!
    #
    # See: Revisions#object
    def object(ref)
      @revisions.object(ref)
    end

    # :call-seq:
    #   doc.object?(ref)    -> true or false
    #   doc.object?(oid)    -> true or false
    #
    # Returns +true+ if the the document contains an indirect object for the given exact reference
    # (see Reference) or for the given object number.
    #
    # Even though this method might return +true+ for some references, #object may return +nil+
    # because this method takes *all* revisions into account. Also see the discussion on #each for
    # more information.
    #
    # See: Revisions#object?
    def object?(ref)
      @revisions.object?(ref)
    end

    # Dereferences the given object.
    #
    # Returns the object itself if it is not a reference, or the indirect object specified by the
    # reference.
    def deref(obj)
      obj.kind_of?(Reference) ? object(obj) : obj
    end

    # :call-seq:
    #   doc.add(obj, **wrap_opts)     -> indirect_object
    #
    # Adds the object to the document and returns the wrapped indirect object.
    #
    # The object can either be a native Ruby object (Hash, Array, Integer, ...) or a
    # HexaPDF::Object. If it is not the latter, #wrap is called with the object and the
    # additional keyword arguments.
    #
    # See: #wrap, Revisions#add_object
    def add(obj, **wrap_opts)
      obj = wrap(obj, **wrap_opts) unless obj.kind_of?(HexaPDF::Object)

      if obj.document? && obj.document != self
        raise HexaPDF::Error, "Can't add object that is already attached to another document"
      end
      obj.document = self

      @revisions.add_object(obj)
    end

    # :call-seq:
    #   doc.delete(ref)
    #   doc.delete(oid)
    #
    # Deletes the indirect object specified by an exact reference or by an object number from the
    # document.
    #
    # See: Revisions#delete_object
    def delete(ref)
      @revisions.delete_object(ref)
    end

    # :call-seq:
    #   doc.import(obj)     -> imported_object
    #
    # Imports the given object from a different HexaPDF::Document instance and returns the imported
    # object.
    #
    # If the same argument is provided in multiple invocations, the import is done only once and
    # the previously imported object is returned.
    #
    # Note: If you first create a PDF document from scratch or if you modify an existing document,
    # and then want to import objects from it into another PDF document, you need to run the
    # following on the source document:
    #
    #   doc.dispatch_message(:complete_objects)
    #   doc.validate
    #
    # This ensures that the source document has all the necessary PDF structures set-up correctly.
    #
    # See: Importer
    def import(obj)
      source = (obj.kind_of?(HexaPDF::Object) ? obj.document : nil)
      HexaPDF::Importer.for(self).import(obj, source: source)
    end

    # Wraps the given object inside a HexaPDF::Object (sub)class which allows one to use
    # convenience functions to work with the object.
    #
    # The +obj+ argument can also be a HexaPDF::Object object so that it can be re-wrapped if
    # necessary.
    #
    # The class of the returned object is always a subclass of HexaPDF::Object (or of
    # HexaPDF::Stream if +stream+ is given). Which subclass is used, depends on the values of the
    # +type+ and +subtype+ options as well as on the 'object.type_map' and 'object.subtype_map'
    # global configuration options:
    #
    # * First +type+ is used to try to determine the class. If it is not provided and if +obj+ is a
    #   hash with a :Type field, the value of this field is used instead. If the resulting object is
    #   already a Class object, it is used, otherwise the type is looked up in 'object.type_map'.
    #
    # * If +subtype+ is provided or can be determined because +obj+ is a hash with a :Subtype or :S
    #   field, the type and subtype together are used to look up a special subtype class in
    #   'object.subtype_map'.
    #
    #   Additionally, if there is no +type+ but a +subtype+, all required fields of the subtype
    #   class need to have values; otherwise the subtype class is not used. This is done to better
    #   prevent invalid mappings when only partial knowledge (:Type key is missing) is available.
    #
    # * If there is no valid class after the above steps, HexaPDF::Stream is used if a stream is
    #   given, HexaPDF::Dictionary if the given object is a hash, HexaPDF::PDFArray if it is an
    #   array or else HexaPDF::Object.
    #
    # Options:
    #
    # :type:: (Symbol or Class) The type of a PDF object that should be used for wrapping. This
    #         could be, for example, :Pages. If a class object is provided, it is used directly
    #         instead of determining the class through the type detection system.
    #
    # :subtype:: (Symbol) The subtype of a PDF object which further qualifies a type. For
    #            example, image objects in PDF have a type of :XObject and a subtype of :Image.
    #
    # :oid:: (Integer) The object number that should be set on the wrapped object. Defaults to 0
    #        or the value of the given object's object number.
    #
    # :gen:: (Integer) The generation number that should be set on the wrapped object. Defaults to
    #        0 or the value of the given object's generation number.
    #
    # :stream:: (String or StreamData) The stream object which should be set on the wrapped
    #           object.
    def wrap(obj, type: nil, subtype: nil, oid: nil, gen: nil, stream: nil)
      data = if obj.kind_of?(HexaPDF::Object)
               obj.data
             else
               HexaPDF::PDFData.new(obj)
             end
      data.oid = oid if oid
      data.gen = gen if gen
      data.stream = stream if stream

      if type.kind_of?(Class)
        klass = type
        type = (klass <= HexaPDF::Dictionary ? klass.type : nil)
      else
        type ||= deref(data.value[:Type]) if data.value.kind_of?(Hash)
        if type
          klass = GlobalConfiguration.constantize('object.type_map', type) { nil }
          if (type == :ObjStm || type == :XRef) &&
              klass.each_field.any? {|name, field| field.required? && !data.value.key?(name) }
            data.value.delete(:Type)
            klass = nil
          end
        end
      end

      if data.value.kind_of?(Hash)
        subtype ||= deref(data.value[:Subtype]) || deref(data.value[:S])
      end
      if subtype
        sub_klass = GlobalConfiguration.constantize('object.subtype_map', type, subtype) { klass }
        if type ||
            sub_klass&.each_field&.none? do |name, field|
              field.required? && !data.value.key?(name) && name != :Type
            end
          klass = sub_klass
        end
      end

      klass ||= if data.stream
                  HexaPDF::Stream
                elsif data.value.kind_of?(Hash)
                  HexaPDF::Dictionary
                elsif data.value.kind_of?(Array)
                  HexaPDF::PDFArray
                else
                  HexaPDF::Object
                end

      klass.new(data, document: self)
    end

    # :call-seq:
    #   document.unwrap(obj)   -> unwrapped_obj
    #
    # Recursively unwraps the object to get native Ruby objects (i.e. Hash, Array, Integer, ...)
    # instead of HexaPDF::Reference and HexaPDF::Object. Only HexaPDF::Stream objects are retained
    # as they are not representable by native Ruby objects.
    def unwrap(object, seen = {})
      object = deref(object)
      object = object.data if object.kind_of?(HexaPDF::Object) && !object.kind_of?(HexaPDF::Stream)
      if seen.key?(object)
        raise HexaPDF::Error, "Can't unwrap a recursive structure"
      end

      case object
      when Hash
        seen[object] = true
        object.transform_values {|value| unwrap(value, seen.dup) }
      when Array
        seen[object] = true
        object.map {|inner_o| unwrap(inner_o, seen.dup) }
      when HexaPDF::PDFData
        seen[object] = true
        unwrap(object.value, seen.dup)
      when HexaPDF::Stream
        object
      else
        object
      end
    end

    # :call-seq:
    #   doc.each(only_current: true, only_loaded: false) {|obj| block }
    #   doc.each(only_current: true, only_loaded: false) {|obj, rev| block }
    #   doc.each(only_current: true, only_loaded: false)                       -> Enumerator
    #
    # Yields every object and the revision it is in.
    #
    # If +only_current+ is +true+, only the current version of each object is yielded, otherwise all
    # objects from all revisions. *Note* that it is normally not necessary or useful to retrieve all
    # objects from all revisions and if it is still done that care has to be taken to avoid an
    # invalid document state.
    #
    # If +only_loaded+ is +true+, only the already loaded objects are yielded.
    #
    # For details see Revisions#each_object
    def each(only_current: true, only_loaded: false, &block)
      @revisions.each_object(only_current: only_current, only_loaded: only_loaded, &block)
    end

    # :call-seq:
    #    doc.register_listener(name, callable)             -> callable
    #    doc.register_listener(name) {|*args| block}       -> block
    #
    # Registers the given listener for the message +name+.
    #
    # If +callable+ is provided, it needs to be an Object responding to #call. Otherwise the block
    # has to be provided. The arguments that are provided to the #call method depend on the message.
    #
    # See: dispatch_message
    def register_listener(name, callable = nil, &block)
      callable ||= block
      (@listeners[name] ||= []) << callable
      callable
    end

    # Dispatches the message +name+ with the given arguments to all registered listeners.
    #
    # See the main Document documentation for an overview of messages that are used by HexaPDF
    # itself.
    #
    # See: register_listener
    def dispatch_message(name, *args)
      @listeners[name]&.each {|obj| obj.call(*args) }
    end

    UNSET = ::Object.new # :nordoc:

    # Caches and returns the given +value+ or the value of the given block using the given
    # +pdf_data+ and +key+ arguments as composite cache key.
    #
    # If a cached value already exists and +update+ is +false+, the cached value is just returned.
    # If +update+ is set to +true+, an update of the cached value is forced.
    #
    # This facility can be used to cache expensive operations in PDF objects that are easy to
    # compute again.
    #
    # Use #clear_cache to clear the cache if necessary.
    def cache(pdf_data, key, value = UNSET, update: false)
      return @cache[pdf_data][key] if cached?(pdf_data, key) && !update
      @cache[pdf_data][key] = (value == UNSET ? yield : value)
    end

    # Returns +true+ if there is a value cached for the composite key consisting of the given
    # +pdf_data+ and +key+ objects.
    #
    # See: #cache
    def cached?(pdf_data, key)
      @cache.key?(pdf_data) && @cache[pdf_data].key?(key)
    end

    # Clears all cached data or, if a Object::PDFData object is given, just the cache for this one
    # object.
    #
    # It is *not* recommended to clear the whole cache! Better clear the cache for individual PDF
    # objects!
    #
    # See: #cache, #cached?
    def clear_cache(pdf_data = nil)
      pdf_data ? @cache[pdf_data].clear : @cache.clear
    end

    # Returns the Metadata object that provides a convenience interface for working with the
    # document metadata.
    #
    # Note that invoking this method means that, depending on the settings, the info dictionary as
    # well as the metadata stream will be overwritten when the document gets written. See the
    # "Caveats" section in the Metadata documentation.
    def metadata
      @metadata ||= Metadata.new(self)
    end

    # Returns the Pages object that provides convenience methods for working with the pages of the
    # PDF file.
    #
    # See: Pages, Type::PageTreeNode
    def pages
      @pages ||= Pages.new(self)
    end

    # Returns the Images object that provides convenience methods for working with images (e.g.
    # adding them to the PDF or listing them).
    def images
      @images ||= Images.new(self)
    end

    # Returns the Files object that provides convenience methods for working with embedded files.
    def files
      @files ||= Files.new(self)
    end

    # Returns the Fonts object that provides convenience methods for working with the fonts used in
    # the PDF file.
    def fonts
      @fonts ||= Fonts.new(self)
    end

    # Returns the Destinations object that provides convenience methods for working with destination
    # objects.
    def destinations
      @destinations ||= Destinations.new(self)
    end

    # Returns the Annotations object that provides convenience methods for working with annotation
    # objects.
    def annotations
      @annotations ||= Annotations.new(self)
    end

    # Returns the Layout object that provides convenience methods for working with the
    # HexaPDF::Layout classes for document layout.
    def layout
      @layout ||= Layout.new(self)
    end

    # Returns the main AcroForm object for dealing with interactive forms.
    #
    # The meaning of the +create+ argument is detailed at Type::Catalog#acro_form.
    #
    # See: Type::AcroForm::Form
    def acro_form(create: false)
      catalog.acro_form(create: create)
    end

    # Returns the entry object to the document outline (a.k.a. bookmarks).
    #
    # See: Type::Outline
    def outline
      catalog.outline
    end

    # Returns the main object for working with optional content (a.k.a. layers).
    #
    # See: Type::Catalog#optional_content
    def optional_content
      catalog.optional_content
    end

    # Executes the given task and returns its result.
    #
    # Tasks provide an extensible way for performing operations on a PDF document without
    # cluttering the Document interface.
    #
    # See: Task
    def task(name, **opts, &block)
      task = config.constantize('task.map', name) do
        raise HexaPDF::Error, "No task named '#{name}' is available"
      end
      task.call(self, **opts, &block)
    end

    # Returns the trailer dictionary for the document.
    #
    # See: Type::Trailer
    def trailer
      @revisions.current.trailer
    end

    # Returns the document's catalog, the root of the object tree.
    #
    # See: Type::Catalog
    def catalog
      trailer.catalog
    end

    # Returns the PDF document's version as string (e.g. '1.4').
    #
    # This method takes the file header version and the catalog's /Version key into account. If a
    # version has been set manually and the catalog's /Version key refers to a later version, the
    # later version is used.
    #
    # See: PDF2.0 s7.2.2
    def version
      catalog_version = (catalog[:Version] || '1.0').to_s
      (@version < catalog_version ? catalog_version : @version)
    end

    # Sets the version of the PDF document.
    #
    # The argument +value+ must be a string in the format 'M.N' where M is the major version and N
    # the minor version (e.g. '1.4' or '2.0').
    def version=(value)
      raise ArgumentError, "PDF version must follow format M.N" unless value.to_s.match?(/\A\d\.\d\z/)
      @version = value.to_s
    end

    # Returns +true+ if the document is encrypted.
    def encrypted?
      !trailer[:Encrypt].nil?
    end

    # Encrypts the document.
    #
    # Encryption is done by setting up a security handler for this purpose and populating the
    # trailer's Encrypt dictionary accordingly. The actual encryption, however, is only done when
    # writing the document.
    #
    # The security handler used for encrypting is selected via the +name+ argument. All other
    # arguments are passed on to the security handler.
    #
    # If the document should not be encrypted, the +name+ argument has to be set to +nil+. This
    # removes the security handler and deletes the trailer's Encrypt dictionary.
    #
    # See: Encryption::SecurityHandler#set_up_encryption and
    # Encryption::StandardSecurityHandler::EncryptionOptions for possible encryption options.
    #
    # Examples:
    #
    #   document.encrypt(name: nil)  # remove the existing encryption
    #   document.encrypt(algorithm: :aes, key_length: 256, permissions: [:print, :extract_content]
    def encrypt(name: :Standard, **options)
      if name.nil?
        trailer.delete(:Encrypt)
        @security_handler = nil
      else
        @security_handler = Encryption::SecurityHandler.set_up_encryption(self, name, **options)
      end
    end

    # Returns the security handler that is used for decrypting or encrypting the document, or +nil+
    # if none is set.
    #
    # * If the document was created by reading an existing file and the document was automatically
    #   decrypted, then this method returns the handler for decrypting.
    #
    # * Once the #encrypt method is called, the specified security handler for encrypting is
    #   returned.
    def security_handler
      @security_handler
    end

    # Returns +true+ if the document is signed, i.e. contains digital signatures.
    def signed?
      acro_form&.signature_flag?(:signatures_exist)
    end

    # Returns a DigitalSignature::Signatures object that allows working with the digital signatures
    # of this document.
    def signatures
      @signatures ||= DigitalSignature::Signatures.new(self)
    end

    # Signs the document and writes it to the given file or IO object.
    #
    # For details on the arguments +file_or_io+, +signature+ and +write_options+ see
    # DigitalSignature::Signatures#add.
    #
    # The signing handler to be used is determined by the +handler+ argument together with the rest
    # of the keyword arguments (see DigitalSignature::Signatures#signing_handler for details).
    #
    # If not changed, the default signing handler is DigitalSignature::Signing::DefaultHandler.
    #
    # *Note*: Once signing is done the document cannot be changed anymore since it was written
    # during the signing process. If a document needs to be signed multiple times, it needs to be
    # loaded again afterwards.
    def sign(file_or_io, handler: :default, signature: nil, write_options: {}, **handler_options)
      handler = signatures.signing_handler(name: handler, **handler_options)
      signatures.add(file_or_io, handler, signature: signature, write_options: write_options)
    end

    # Validates all current objects, or, if +only_loaded+ is +true+, only loaded objects, with
    # optional auto-correction, and returns +true+ if everything is fine.
    #
    # If a block is given, it is called on validation problems.
    #
    # See Object#validate for more information.
    def validate(auto_correct: true, only_loaded: false, &block) #:yield: msg, correctable, object
      result = trailer.validate(auto_correct: auto_correct, &block)
      each(only_loaded: only_loaded) do |obj|
        result &&= obj.validate(auto_correct: auto_correct, &block)
      end
      result
    end

    # Returns an in-memory copy of the PDF document.
    #
    # In the context of this method this means that the returned PDF document contains the same PDF
    # object tree as this document, starting at the trailer. A possibly set encryption is not
    # transferred to the returned document.
    #
    # Note: If this PDF document was created from scratch or if it is an existing document that was
    # modified, the following commands need to be run on this document beforehand:
    #
    #   doc.dispatch_message(:complete_objects)
    #   doc.validate
    #
    # This ensures that all the necessary PDF structures set-up correctly.
    def duplicate
      dest = HexaPDF::Document.new
      dupped_trailer = HexaPDF::Importer.copy(dest, trailer, allow_all: true)
      dest.revisions.current.trailer.value.replace(dupped_trailer.value)
      dest.trailer.delete(:Encrypt)
      dest
    end

    # :call-seq:
    #   doc.write(filename, incremental: false, validate: true, update_fields: true, optimize: false, compact: true) -> [start_xref, section]
    #   doc.write(io, incremental: false, validate: true, update_fields: true, optimize: false, compact: true) -> [start_xref, section]
    #
    # Writes the document to the given file (in case +io+ is a String) or IO stream. Returns the
    # file position of the start of the last cross-reference section and the last XRefSection object
    # written.
    #
    # Before the document is written, it is validated using #validate and an error is raised if the
    # document is not valid. However, this step can be skipped if needed.
    #
    # The method dispatches two messages:
    #
    # :complete_objects::
    #   This message is dispatched before anything is done and should be used to finalize objects.
    #
    # :before_write::
    #   This message is dispatched directly before the document gets serialized and allows, for
    #   example, overriding automatic HexaPDF changes (e.g. forcefully setting a document version).
    #
    # Options:
    #
    # incremental::
    #   Use the incremental writing mode which just adds a new revision to an existing document.
    #   This is needed, for example, when modifying a signed PDF and the original signature should
    #   stay valid.
    #
    #   See: PDF2.0 s7.5.6
    #
    # validate::
    #   Validates the document and raises an error if an uncorrectable problem is found.
    #
    # update_fields::
    #   Updates the /ID field in the trailer dictionary as well as the /ModDate field in the
    #   trailer's /Info dictionary so that it is clear that the document has been updated.
    #
    # optimize::
    #   Optimize the file size by using object and cross-reference streams. This will raise the PDF
    #   version to at least 1.5.
    #
    # compact::
    #   Compact the document by reducing it to a single revision and removing null and unused
    #   objects.
    #
    #   The initial revision of a document has to contain objects with continuous numbering. If some
    #   object numbers refer to free entries, other PDF libraries/viewers might not work
    #   correctly. So continuous object numbers are assigned to stay compliant with the
    #   specification.
    #
    #   Only change this argument to +false+ if you run the optimization task with 'compact: true'
    #   beforehand or if you know exactly what you do and what not compacting implies.
    def write(file_or_io, incremental: false, validate: true, update_fields: true, optimize: false,
              compact: true)
      if update_fields
        trailer.update_id
        if @metadata
          metadata.modification_date(Time.now)
        else
          trailer.delete(:Info) unless trailer.info.kind_of?(HexaPDF::Dictionary)
          trailer.info[:ModDate] = Time.now
        end
      end

      dispatch_message(:complete_objects)

      if validate
        self.validate(auto_correct: true) do |msg, correctable, obj|
          next if correctable
          raise HexaPDF::Error, "Validation error for (#{obj.oid},#{obj.gen}): #{msg}"
        end
      end

      optimize_opts = {}
      optimize_opts[:object_streams] = :generate if optimize
      optimize_opts[:compact] = true if compact && !incremental
      task(:optimize, **optimize_opts) unless optimize_opts.empty?
      self.version = '1.5' if version < '1.5' if optimize

      dispatch_message(:before_write)

      if file_or_io.kind_of?(String)
        File.open(file_or_io, 'w+') {|file| Writer.write(self, file, incremental: incremental) }
      else
        Writer.write(self, file_or_io, incremental: incremental)
      end
    end

    # Writes the document to a string and returns the string.
    #
    # See #write for further information and details on the available arguments.
    def write_to_string(**args)
      io = StringIO.new(''.b)
      write(io, **args)
      io.string
    end

    def inspect #:nodoc:
      "<#{self.class.name}:#{object_id}>"
    end

  end

end
