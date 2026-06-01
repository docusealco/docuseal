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

require 'hexapdf/font/invalid_glyph'
require 'hexapdf/error'

module HexaPDF

  # Manages both the global and document specific configuration options for HexaPDF.
  #
  # == Overview
  #
  # HexaPDF allows detailed control over many aspects of PDF manipulation. If there is a need to
  # use a certain default value somewhere, it is defined as a configuration option so that it can
  # easily be changed.
  #
  # Some options are defined as global options because they are needed on the class level - see
  # HexaPDF::GlobalConfiguration[index.html#GlobalConfiguration]. Other options can be configured
  # for individual documents as they allow to fine-tune some behavior - see
  # HexaPDF::DefaultDocumentConfiguration[index.html#DefaultDocumentConfiguration].
  #
  # A configuration option name is dot-separted to provide a hierarchy of option names. For
  # example, io.chunk_size.
  class Configuration

    # Creates a new document specific Configuration object by merging the values into the default
    # configuration object.
    def self.with_defaults(values = {})
      DefaultDocumentConfiguration.merge(values)
    end

    # Creates a new Configuration object using the provided hash argument.
    def initialize(options = {})
      @options = options
    end

    # Returns +true+ if the given option exists.
    def key?(name)
      options.key?(name)
    end
    alias option? key?

    # Returns the value for the configuration option +name+.
    def [](name)
      options[name]
    end

    # Uses +value+ as the value for the configuration option +name+.
    def []=(name, value)
      options[name] = value
    end

    # Returns a new Configuration object containing the options from the given configuration
    # object (or hash) and this configuration object.
    #
    # If a key already has a value in this object, its value is overwritten by the one from
    # +config+. However, hash values are merged instead of being overwritten. Array values are
    # duplicated.
    def merge(config)
      config = (config.kind_of?(self.class) ? config.options : config)
      merged_config = options.each_with_object({}) do |(key, old), conf|
        new = config[key]
        conf[key] = if old.kind_of?(Hash) && new.kind_of?(Hash)
                      old.merge(new)
                    elsif new.kind_of?(Array) || old.kind_of?(Array)
                      (new || old).dup
                    elsif config.key?(key)
                      new
                    else
                      old
                    end
      end
      self.class.new(merged_config)
    end

    # :call-seq:
    #   config.constantize(name, *keys)                  -> constant
    #   config.constantize(name, *keys) {|name| block}   -> obj
    #
    # Returns the constant the option +name+ is referring to. If +keys+ are provided and the value
    # of the option +name+ responds to \#dig, the constant to which the keys refer is returned.
    #
    # If no constant can be found and no block is provided, an error is raised. If a block is
    # provided it is called with the option name and its result will be returned.
    #
    #   config.constantize('encryption.aes')      #=> HexaPDF::Encryption::FastAES
    #   config.constantize('filter.map', :Fl)     #=> HexaPDF::Filter::FlateDecode
    def constantize(name, *keys)
      data = self[name]
      data = data.dig(*keys) if data.respond_to?(:dig)
      (data = ::Object.const_get(data) rescue nil) if data.kind_of?(String)
      if data.nil? && block_given?
        data = yield(name)
      elsif data.nil?
        raise HexaPDF::Error, "Error getting constant for configuration option '#{name}'" +
          (keys.empty? ? "" : " and keys '#{keys.join(', ')}'")
      end
      data
    end

    protected

    # Returns the hash with the configuration options.
    attr_reader :options

  end

  # Provides the default implementation for the configuration option 'font.on_invalid_glyph'.
  #
  # It uses the first font in the list provided by the 'font.fallback' configuration option that
  # contains a glyph for the +codepoint+ (taking the font variant into account). If no fallback font
  # contains such a glyph, +invalid_glyph+ is used.
  def self.font_on_invalid_glyph(codepoint, invalid_glyph)
    font_wrapper = invalid_glyph.font_wrapper
    document = font_wrapper.pdf_object.document
    variant = case
              when font_wrapper.italic? && font_wrapper.bold? then :bold_italic
              when font_wrapper.bold? then :bold
              when font_wrapper.italic? then :italic
              else :none
              end
    document.config['font.fallback'].each do |font_name|
      font = document.fonts.add(font_name, variant: variant) rescue document.fonts.add(font_name)
      glyph = font.decode_codepoint(codepoint)
      unless glyph.kind_of?(HexaPDF::Font::InvalidGlyph)
        return [glyph]
      end
    end
    [invalid_glyph]
  end

  # The default document specific configuration object.
  #
  # Modify this object if you want to globally change document specific options or if you want to
  # introduce new document specific options.
  #
  # The following options are provided:
  #
  # acro_form.appearance_generator::
  #    The class that should be used for generating appearances for AcroForm fields. If the value is
  #    a String, it should contain the name of a constant to such a class.
  #
  #    See HexaPDF::Type::AcroForm::AppearanceGenerator
  #
  # acro_form.create_appearances::
  #    A boolean specifying whether an AcroForm field's appearances should automatically be
  #    generated if they are missing.
  #
  # acro_form.default_font_size::
  #    A number specifying the default font size of AcroForm text fields which should be auto-sized.
  #
  # acro_form.fallback_default_appearance::
  #    A hash containging arguments for
  #    HexaPDF::Type::AcroForm::VariableTextField#set_defaut_appearance_string which is used as
  #    fallback for fields without a default appearance.
  #
  #    If this value is set to +nil+, an error is raised in case a variable text field cannot
  #    resolve a default appearance string.
  #
  #    The default is the empty hash meaning the defaults from the method are used.
  #
  # acro_form.fallback_font::
  #    The font that should be used when a variable text field references a font that cannot be used.
  #
  #    Can be one of the following:
  #
  #    * The name of a font, like 'Helvetica'.
  #
  #    * An array consisting of the font name and a hash of font options, like ['Helvetica',
  #      variant: :italic].
  #
  #    * A callable object receiving the field and the font object (or +nil+ if no valid font object
  #      was found) and which has to return either a font name or an array consisting of the font
  #      name and a hash of font options. This way the response can be different depending on the
  #      original font and it would also allow e.g. modifying the configured fonts to add custom
  #      ones.
  #
  #    If set to +nil+, the use of the fallback font is disabled.
  #
  #    Default is 'Helvetica'.
  #
  # acro_form.on_invalid_value::
  #    Callback hook when an invalid value is set for certain types of AcroForm fields.
  #
  #    The value needs to be an object that responds to \#call(field, value) where +field+ is the
  #    AcroForm field on which the value is set and +value+ is the invalid value. The returned value
  #    is used instead of the invalid value.
  #
  #    The default implementation raises an error.
  #
  # acro_form.text_field.default_width::
  #    A number specifying the default width of AcroForm text fields which should be auto-sized.
  #
  # acro_form.text_field.on_max_len_exceeded::
  #    Callback hook when the value of a text field exceeds the set maximum length.
  #
  #    The value needs to be an object that responds to \#call(field, value) where +field+ is the
  #    AcroForm text field on which the value is set and +value+ is the invalid value. The returned
  #    value is used instead of the invalid value.
  #
  #    The default implementation raises an error.
  #
  # annotation.appearance_generator::
  #    The class that should be used for generating appearances for annotations. If the value is a
  #    String, it should contain the name of a constant to such a class.
  #
  #    See HexaPDF::Type::Annotations::AppearanceGenerator
  #
  # debug::
  #    If set to +true+, enables debug output.
  #
  # document.auto_decrypt::
  #    A boolean determining whether the document should be decrypted automatically when parsed.
  #
  #    If this is set to +false+ and the PDF document should later be decrypted, the method
  #    Encryption::SecurityHandler.set_up_decryption(document, decryption_opts) has to be called to
  #    set and retrieve the needed security handler. Note, however, that already loaded indirect
  #    objects have to be decrypted manually!
  #
  #    In nearly all cases this option should not be changed from its default setting!
  #
  # document.on_invalid_string::
  #    A callable object that takes the invalid UTF-16BE encoded string and returns a valid UTF-8
  #    encoded string.
  #
  #    The default is to remove all invalid characters.
  #
  # encryption.aes::
  #    The class that should be used for AES encryption. If the value is a String, it should
  #    contain the name of a constant to such a class.
  #
  #    See HexaPDF::Encryption::AES for the general interface such a class must conform to and
  #    HexaPDF::Encryption::RubyAES as well as HexaPDF::Encryption::FastAES for implementations.
  #
  # encryption.arc4::
  #    The class that should be used for ARC4 encryption. If the value is a String, it should
  #    contain the name of a constant to such a class.
  #
  #    See HexaPDF::Encryption::ARC4 for the general interface such a class must conform to and
  #    HexaPDF::Encryption::RubyARC4 as well as HexaPDF::Encryption::FastARC4 for implementations.
  #
  # encryption.filter_map::
  #    A mapping from a PDF name (a Symbol) to a security handler class (see
  #    Encryption::SecurityHandler). If the value is a String, it should contain the name of a
  #    constant to such a class.
  #
  #    PDF defines a standard security handler that is implemented
  #    (HexaPDF::Encryption::StandardSecurityHandler) and assigned the :Standard name.
  #
  # encryption.on_decryption_error::
  #    Callback hook when HexaPDF encounters a decryption error that can potentially be ignored.
  #
  #    The value needs to be an object that responds to \#call(obj, message) and returns +true+ if
  #    an error should be raised.
  #
  # encryption.sub_filter_map::
  #    A mapping from a PDF name (a Symbol) to a security handler class (see
  #    HexaPDF::Encryption::SecurityHandler). If the value is a String, it should contain the name
  #    of a constant to such a class.
  #
  #    The sub filter map is used when the security handler defined by the encryption dictionary
  #    is not available, but a compatible implementation is.
  #
  # filter.map::
  #    A mapping from a PDF name (a Symbol) to a filter object (see Filter). If the value is a
  #    String, it should contain the name of a constant that contains a filter object.
  #
  #    The most often used filters are implemented and readily available.
  #
  #    See PDF2.0 s7.4.1, ADB sH.3 3.3
  #
  # font.default::
  #    This font is used by the layout engine when no font is specified but one is needed.
  #
  #    This is used, for example, for the font set on styles that don't have a font set.
  #
  #    The default value is 'Times'.
  #
  # font.fallback::
  #    An array of fallback font names to be used when replacing invalid glyphs.
  #
  #    The values can be anything that can be passed to Document::Fonts#add. Note that the +variant+
  #    of a font is determined by looking at the font for which a invalid glyph should be replaced.
  #
  #    The default value consists of the built-in fonts ZapfDingbats and Symbol.
  #
  # font.map::
  #    Defines a mapping from font names and variants to font files.
  #
  #    The value needs to be a hash of the form:
  #      {"font_name" => {variant: file_name, variant2: file_name2, ...}, ...}
  #
  #    Once a font is registered in this way, the font name together with a variant name can be used
  #    with the HexaPDF::Document::Fonts#add method to load the font.
  #
  #    For best compatibility, the following variant names should be used:
  #
  #    [none] For the normal variant of the font
  #    [bold] For the bold variant of the font
  #    [italic] For the italic or oblique variant of the font
  #    [bold_italic] For the bold and italic/oblique variant of the font
  #
  # font.on_invalid_glyph::
  #    Callback hook when a character cannot be mapped to a glyph and one or more glyphs from a
  #    different font should be used. Only applies when using high-level text creation facilities.
  #
  #    The value needs to be an object that responds to \#call(codepoint, invalid_glyph) where
  #    +codepoint+ is the Unicode codepoint that cannot be mapped to a valid glyph. The
  #    +invalid_glyph+ argument is the HexaPDF::Font::InvalidGlyph object that was the result of the
  #    initial mapping. The return value has to be an array of glyph objects which can be from any
  #    font but all need to be from the same one.
  #
  #    The default implementation is provided by ::font_on_invalid_glyph and uses the
  #    'font.fallback' configuration option. It is usually not necessary to change this
  #    configuration option or the 'font.on_missing_glyph' one.
  #
  #    Note: The 'font.on_missing_glyph' configuration option does something similar but is
  #    restricted to returning a single glyph from the same font. Whenever a glyph is not found,
  #    'font.on_missing_glyph' is invoked first and if an invalid glyph instance is returned, this
  #    callback hook is invoked when using the layout engine.
  #
  #    A typical implementation would use one or more fallback fonts (probably choosing one in the
  #    correct font variant) for providing the necessary glyph(s):
  #
  #      doc.config['font.on_invalid_glyph'] = lambda do |codepoint, glyph|
  #        [other_font.decode_codepoint(codepoint)]
  #      end
  #
  # font.on_missing_glyph::
  #    Callback hook when an UTF-8 character cannot be mapped to a glyph of a font.
  #
  #    The value needs to be an object that responds to \#call(character, font_wrapper) where
  #    +character+ is the Unicode character for the missing glyph and returns a substitute glyph to
  #    be used instead. This substitute glyph needs to be from the same font, i.e. it needs to be
  #    created through the provided +font_wrapper+ instance.
  #
  #    The +font_wrapper+ argument is the used font wrapper object, e.g.
  #    HexaPDF::Font::TrueTypeWrapper. To access the HexaPDF::Document instance from which this hook
  #    was called, you can use +font_wrapper.pdf_object.document+.
  #
  #    The default implementation returns an object of class HexaPDF::Font::InvalidGlyph which, when
  #    not removed before encoding, will raise a HexaPDF::MissingGlyphError.
  #
  #    Note: The 'font.on_invalid_glyph' configuration option does something similar but is used
  #    later and only by the layout engine. If this callback hook returns an invalid glyph instance,
  #    the 'font.on_invalid_glyph' callback hook is invoked when using the layout engine and it can
  #    return a substitute glyph in any font.
  #
  #    If a replacement glyph should be displayed instead of an error, the following provides a good
  #    starting implementation:
  #
  #      doc.config['font.on_missing_glyph'] = lambda do |character, font_wrapper|
  #        font_wrapper.custom_glyph(font_wrapper.font_type == :Type1 ? :question : 0, character)
  #      end
  #
  # font.on_missing_unicode_mapping::
  #    Callback hook when a character code point cannot be converted to a Unicode character.
  #
  #    The value needs to be an object that responds to \#call(code, font_dict) where +code+ is the
  #    decoded code point and +font_dict+ is the font dictionary which was used for the conversion.
  #    The returned value is used as the Unicode character and should be a string.
  #
  #    The default implementation raises an error.
  #
  # font_loader::
  #    An array with font loader implementations. When a font should be loaded, the array is
  #    iterated in sequence and the first valid font returned by a font loader is used.
  #
  #    If a value is a String, it should contain the name of a constant that is a font loader
  #    object.
  #
  #    See the HexaPDF::FontLoader module for information on how to implement a font loader object.
  #
  # graphic_object.arc.max_curves::
  #    The maximum number of curves used for approximating a complete ellipse using Bezier curves.
  #
  #    The default value is 6, higher values result in better approximations but also take longer
  #    to compute. It should not be set to values lower than 4, otherwise the approximation of a
  #    complete ellipse is visibly false.
  #
  # graphic_object.map::
  #    A mapping from graphic object names to graphic object factories.
  #
  #    See HexaPDF::Content::GraphicObject for more information.
  #
  # image_loader::
  #    An array with image loader implementations. When an image should be loaded, the array is
  #    iterated in sequence to find a suitable image loader.
  #
  #    If a value is a String, it should contain the name of a constant that is an image loader
  #    object.
  #
  #    See the HexaPDF::ImageLoader module for information on how to implement an image loader
  #    object.
  #
  # image_loader.pdf.use_stringio::
  #    A boolean determining whether images specified via file names should be read into memory
  #    all at once using a StringIO object.
  #
  #    Since loading a PDF as image entails having the IO object from the image PDF around until
  #    the PDF document where it is used is written, there is the choice whether memory should be
  #    used to load the image PDF all at once or whether a File object is used that needs to be
  #    manually closed.
  #
  #    To avoid leaking file descriptors, using the StringIO is the default setting. If you set
  #    this option to +false+, it is strongly advised to use ObjectSpace.each_object(File) (or
  #    +IO+ instead of +File) to traverse the list of open file descriptors and close the ones
  #    that have been used for PDF images.
  #
  # io.chunk_size::
  #    The size of the chunks that are used when reading IO data.
  #
  #    This can be used to limit the memory needed for reading or writing PDF files with huge
  #    stream objects.
  #
  # layout.boxes.map::
  #    A mapping from layout box names to box classes. If the value is a String, it should contain
  #    the name of a constant to such a class.
  #
  #    See HexaPDF::Layout::Box for more information.
  #
  # page.default_media_box::
  #    The media box that is used for new pages that don't define a media box. Default value is
  #    A4. See HexaPDF::Type::Page::PAPER_SIZE for a list of predefined paper sizes.
  #
  #    This configuration option (together with 'page.default_media_orientation') is also used when
  #    validating pages and a page without a media box is found.
  #
  #    The value can either be a rectangle defining the paper size or a Symbol referencing one of
  #    the predefined paper sizes.
  #
  # page.default_media_orientation::
  #    The page orientation that is used for new pages that don't define a media box. It is only
  #    used if 'page.default_media_box' references a predefined paper size. Default value is
  #    :portrait. The other possible value is :landscape.
  #
  # parser.on_correctable_error::
  #    Callback hook when the parser encounters an error that can be corrected.
  #
  #    The value needs to be an object that responds to \#call(document, message, position) and
  #    returns +true+ if an error should be raised.
  #
  # parser.try_xref_reconstruction::
  #    A boolean specifying whether non-recoverable parsing errors should lead to reconstructing the
  #    main cross-reference table.
  #
  #    The reconstructed cross-reference table might make damaged files usable but there is no way
  #    to ensure that the reconstructed file is equal to the undamaged original file (though
  #    generally it works out).
  #
  #    There is also the possibility that reconstructing doesn't work because the algorithm has to
  #    assume that the PDF was written in a certain way (which is recommended by the PDF
  #    specification).
  #
  #    Defaults to +true+.
  #
  # signature.signing_handler::
  #   A mapping from a Symbol to a signing handler class (see
  #   HexaPDF::Document::Signatures::DefaultHandler). If the value is a String, it should contain
  #   the name of a constant to such a class.
  #
  # signature.sub_filter_map::
  #    A mapping from a PDF name (a Symbol) to a signature handler class (see
  #    HexaPDF::DigitalSignature::Handler). If the value is a String, it should contain the name of
  #    a constant to such a class.
  #
  #    The sub filter map is used for mapping specific signature algorithms to handler classes. The
  #    filter value of a signature dictionary is ignored since we only support the standard
  #    signature algorithms.
  #
  # sorted_tree.max_leaf_node_size::
  #    The maximum number of nodes that should be in a leaf node of a node tree.
  #
  # style.layers_map::
  #    A mapping from style layer names to layer objects.
  #
  #    See HexaPDF::Layout::Style::Layers for more information.
  #
  # task.map::
  #    A mapping from task names to callable task objects. See HexaPDF::Task for more information.
  DefaultDocumentConfiguration =
    Configuration.new('acro_form.appearance_generator' => 'HexaPDF::Type::AcroForm::AppearanceGenerator',
                      'acro_form.create_appearances' => true,
                      'acro_form.default_font_size' => 10,
                      'acro_form.fallback_default_appearance' => {},
                      'acro_form.fallback_font' => 'Helvetica',
                      'acro_form.on_invalid_value' => proc do |field, value|
                        raise HexaPDF::Error, "Invalid value #{value.inspect} for " \
                          "#{field.concrete_field_type} field named '#{field.full_field_name}'"
                      end,
                      'acro_form.text_field.default_width' => 100,
                      'acro_form.text_field.on_max_len_exceeded' => proc do |field, value|
                        raise HexaPDF::Error, "Value exceeds maximum allowed length of #{field[:MaxLen]}"
                      end,
                      'annotation.appearance_generator' => 'HexaPDF::Type::Annotations::AppearanceGenerator',
                      'debug' => false,
                      'document.auto_decrypt' => true,
                      'document.on_invalid_string' => proc do |str|
                        str.encode(Encoding::UTF_8, invalid: :replace, replace: '')
                      end,
                      'encryption.aes' => 'HexaPDF::Encryption::FastAES',
                      'encryption.arc4' => 'HexaPDF::Encryption::FastARC4',
                      'encryption.filter_map' => {
                        Standard: 'HexaPDF::Encryption::StandardSecurityHandler',
                      },
                      'encryption.on_decryption_error' => proc do |_obj, _error|
                        false
                      end,
                      'encryption.sub_filter_map' => {},
                      'filter.map' => {
                        ASCIIHexDecode: 'HexaPDF::Filter::ASCIIHexDecode',
                        AHx: 'HexaPDF::Filter::ASCIIHexDecode',
                        ASCII85Decode: 'HexaPDF::Filter::ASCII85Decode',
                        A85: 'HexaPDF::Filter::ASCII85Decode',
                        LZWDecode: 'HexaPDF::Filter::LZWDecode',
                        LZW: 'HexaPDF::Filter::LZWDecode',
                        FlateDecode: 'HexaPDF::Filter::FlateDecode',
                        Fl: 'HexaPDF::Filter::FlateDecode',
                        RunLengthDecode: 'HexaPDF::Filter::RunLengthDecode',
                        RL: 'HexaPDF::Filter::RunLengthDecode',
                        CCITTFaxDecode: 'HexaPDF::Filter::PassThrough',
                        CCF: 'HexaPDF::Filter::PassThrough',
                        JBIG2Decode: 'HexaPDF::Filter::PassThrough',
                        DCTDecode: 'HexaPDF::Filter::PassThrough',
                        DCT: 'HexaPDF::Filter::PassThrough',
                        JPXDecode: 'HexaPDF::Filter::PassThrough',
                        Crypt: 'HexaPDF::Filter::Crypt',
                        Encryption: 'HexaPDF::Filter::Encryption',
                        BrotliDecode: 'HexaPDF::Filter::BrotliDecode',
                      },
                      'font.default' => 'Times',
                      'font.fallback' => ['ZapfDingbats', 'Symbol'],
                      'font.map' => {},
                      'font.on_invalid_glyph' => method(:font_on_invalid_glyph),
                      'font.on_missing_glyph' => proc do |char, font_wrapper|
                        HexaPDF::Font::InvalidGlyph.new(font_wrapper, char)
                      end,
                      'font.on_missing_unicode_mapping' => proc do |code_point, font|
                        raise HexaPDF::Error, "No Unicode mapping for code point #{code_point} " \
                          "in font #{font[:BaseFont]}"
                      end,
                      'font_loader' => [
                        'HexaPDF::FontLoader::Standard14',
                        'HexaPDF::FontLoader::FromConfiguration',
                        'HexaPDF::FontLoader::FromFile',
                        'HexaPDF::FontLoader::VariantFromName',
                      ],
                      'graphic_object.arc.max_curves' => 6,
                      'graphic_object.map' => {
                        arc: 'HexaPDF::Content::GraphicObject::Arc',
                        endpoint_arc: 'HexaPDF::Content::GraphicObject::EndpointArc',
                        solid_arc: 'HexaPDF::Content::GraphicObject::SolidArc',
                        geom2d: 'HexaPDF::Content::GraphicObject::Geom2D',
                      },
                      'image_loader' => [
                        'HexaPDF::ImageLoader::JPEG',
                        'HexaPDF::ImageLoader::PNG',
                        'HexaPDF::ImageLoader::PDF',
                      ],
                      'image_loader.pdf.use_stringio' => true,
                      'io.chunk_size' => 2**16,
                      'layout.boxes.map' => {
                        base: 'HexaPDF::Layout::Box',
                        text: 'HexaPDF::Layout::TextBox',
                        image: 'HexaPDF::Layout::ImageBox',
                        column: 'HexaPDF::Layout::ColumnBox',
                        list: 'HexaPDF::Layout::ListBox',
                        table: 'HexaPDF::Layout::TableBox',
                        container: 'HexaPDF::Layout::ContainerBox',
                      },
                      'page.default_media_box' => :A4,
                      'page.default_media_orientation' => :portrait,
                      'parser.on_correctable_error' => proc { false },
                      'parser.try_xref_reconstruction' => true,
                      'signature.signing_handler' => {
                        default: 'HexaPDF::DigitalSignature::Signing::DefaultHandler',
                        timestamp: 'HexaPDF::DigitalSignature::Signing::TimestampHandler',
                      },
                      'signature.sub_filter_map' => {
                        'adbe.x509.rsa_sha1': 'HexaPDF::DigitalSignature::PKCS1Handler',
                        'adbe.pkcs7.detached': 'HexaPDF::DigitalSignature::CMSHandler',
                        'ETSI.CAdES.detached': 'HexaPDF::DigitalSignature::CMSHandler',
                        'ETSI.RFC3161': 'HexaPDF::DigitalSignature::CMSHandler',
                      },
                      'sorted_tree.max_leaf_node_size' => 64,
                      'style.layers_map' => {
                        link: 'HexaPDF::Layout::Style::LinkLayer',
                      },
                      'task.map' => {
                        optimize: 'HexaPDF::Task::Optimize',
                        dereference: 'HexaPDF::Task::Dereference',
                        pdfa: 'HexaPDF::Task::PDFA',
                        merge_acro_form: 'HexaPDF::Task::MergeAcroForm',
                      })

  # The global configuration object, providing the following options:
  #
  # color_space.map::
  #    A mapping from a PDF name (a Symbol) to a color space class (see
  #    HexaPDF::Content::ColorSpace). If the value is a String, it should contain the name of a
  #    constant that contains a color space class.
  #
  #    Classes for the most often used color space families are implemented and readily available.
  #
  #    See PDF2.0 s8.6
  #
  # filter.brotli.compression::
  #    Specifies the compression level that should be used with the BrotliDecode filter. The level
  #    can range from 0 (no compression), 1 (best speed) to 11 (best compression). The default
  #    value is 8 which is a good compromise between speed and resulting size.
  #
  # filter.flate.compression::
  #    Specifies the compression level that should be used with the FlateDecode filter. The level
  #    can range from 0 (no compression), 1 (best speed) to 9 (best compression, default).
  #
  # filter.flate.memory::
  #    Specifies the memory level that should be used with the FlateDecode filter. The level can
  #    range from 1 (minimum memory usage; slow, reduces compression) to 9 (maximum memory usage).
  #
  #    The HexaPDF default value of 6 has been found in tests to be nearly equivalent to the Zlib
  #    default of 8 in terms of speed and compression level but uses less memory.
  #
  # filter.flate.on_error::
  #    Callback hook when a potentially recoverable Zlib error occurs in the FlateDecode filter.
  #
  #    The value needs to be an object that responds to \#call(stream, error) where stream is the
  #    Zlib stream object and error is the thrown error. The method needs to return +true+ if an
  #    error should be raised.
  #
  #    The default implementation prevents errors from being raised.
  #
  # filter.predictor.strict::
  #    Specifies whether the predictor algorithm used by LZWDecode and FlateDecode should operate in
  #    strict mode, i.e. adhering to the PDF specification without correcting for common deficiences
  #    of PDF writer libraries.
  #
  # object.type_map::
  #    A mapping from a PDF name (a Symbol) to PDF object classes which is based on the /Type
  #    field. If the value is a String, it should contain the name of a constant that contains a
  #    PDF object class.
  #
  #    This mapping is used to provide automatic wrapping of objects in the HexaPDF::Document#wrap
  #    method.
  #
  # object.subtype_map::
  #    A mapping from a PDF name (a Symbol) to PDF object classes which is based on the /Subtype
  #    field. If the value is a String, it should contain the name of a constant that contains a
  #    PDF object class.
  #
  #    This mapping is used to provide automatic wrapping of objects in the HexaPDF::Document#wrap
  #    method.
  GlobalConfiguration =
    Configuration.new('color_space.map' => {
                        DeviceRGB: 'HexaPDF::Content::ColorSpace::DeviceRGB',
                        DeviceCMYK: 'HexaPDF::Content::ColorSpace::DeviceCMYK',
                        DeviceGray: 'HexaPDF::Content::ColorSpace::DeviceGray',
                      },
                      'filter.flate.compression' => 9,
                      'filter.flate.memory' => 6,
                      'filter.flate.on_error' => proc { false },
                      'filter.predictor.strict' => false,
                      'object.type_map' => {
                        XRef: 'HexaPDF::Type::XRefStream',
                        ObjStm: 'HexaPDF::Type::ObjectStream',
                        Catalog: 'HexaPDF::Type::Catalog',
                        Pages: 'HexaPDF::Type::PageTreeNode',
                        Page: 'HexaPDF::Type::Page',
                        Filespec: 'HexaPDF::Type::FileSpecification',
                        EmbeddedFile: 'HexaPDF::Type::EmbeddedFile',
                        ExtGState: 'HexaPDF::Type::GraphicsStateParameter',
                        Font: 'HexaPDF::Type::Font',
                        FontDescriptor: 'HexaPDF::Type::FontDescriptor',
                        XXEmbeddedFileParameters: 'HexaPDF::Type::EmbeddedFile::Parameters',
                        XXEmbeddedFileParametersMacInfo: 'HexaPDF::Type::EmbeddedFile::MacInfo',
                        XXFilespecEFDictionary: 'HexaPDF::Type::FileSpecification::EFDictionary',
                        XXInfo: 'HexaPDF::Type::Info',
                        XXNames: 'HexaPDF::Type::Names',
                        XXResources: 'HexaPDF::Type::Resources',
                        XXTrailer: 'HexaPDF::Type::Trailer',
                        XXViewerPreferences: 'HexaPDF::Type::ViewerPreferences',
                        Action: 'HexaPDF::Type::Action',
                        XXLaunchActionWinParameters: 'HexaPDF::Type::Actions::Launch::WinParameters',
                        Annot: 'HexaPDF::Type::Annotation',
                        XXAppearanceCharacteristics: 'HexaPDF::Type::Annotations::Widget::AppearanceCharacteristics',
                        XXIconFit: 'HexaPDF::Type::IconFit',
                        XXAcroForm: 'HexaPDF::Type::AcroForm::Form',
                        XXAcroFormField: 'HexaPDF::Type::AcroForm::Field',
                        XXAppearanceDictionary: 'HexaPDF::Type::Annotation::AppearanceDictionary',
                        Border: 'HexaPDF::Type::Annotation::Border',
                        XXBorderEffect: 'HexaPDF::Type::Annotation::BorderEffect',
                        SigFieldLock: 'HexaPDF::Type::AcroForm::SignatureField::LockDictionary',
                        SV: 'HexaPDF::Type::AcroForm::SignatureField::SeedValueDictionary',
                        SVCert: 'HexaPDF::Type::AcroForm::SignatureField::CertificateSeedValueDictionary',
                        Sig: 'HexaPDF::DigitalSignature::Signature',
                        DocTimeStamp: 'HexaPDF::DigitalSignature::Signature',
                        SigRef: 'HexaPDF::DigitalSignature::Signature::SignatureReference',
                        TransformParams: 'HexaPDF::DigitalSignature::Signature::TransformParams',
                        Outlines: 'HexaPDF::Type::Outline',
                        XXOutlineItem: 'HexaPDF::Type::OutlineItem',
                        PageLabel: 'HexaPDF::Type::PageLabel',
                        XXMarkInformation: 'HexaPDF::Type::MarkInformation',
                        OCG: 'HexaPDF::Type::OptionalContentGroup',
                        OCMD: 'HexaPDF::Type::OptionalContentMembership',
                        XXOCUsage: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage',
                        XXOCUsageCreatorInfo: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::CreatorInfo',
                        XXOCUsageLanguage: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Language',
                        XXOCUsageExport: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Export',
                        XXOCUsageZoom: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Zoom',
                        XXOCUsagePrint: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::Print',
                        XXOCUsageView: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::View',
                        XXOCUsageUser: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::User',
                        XXOCUsagePageElement: 'HexaPDF::Type::OptionalContentGroup::OptionalContentUsage::PageElement',
                        XXOCProperties: 'HexaPDF::Type::OptionalContentProperties',
                        XXOCConfiguration: 'HexaPDF::Type::OptionalContentConfiguration',
                        XXOCUsageApplication: 'HexaPDF::Type::OptionalContentConfiguration::UsageApplication',
                        XXReference: 'HexaPDF::Type::Form::Reference',
                        XXCIDSystemInfo: 'HexaPDF::Type::CIDFont::CIDSystemInfo',
                        Group: 'HexaPDF::Type::Form::Group',
                        Metadata: 'HexaPDF::Type::Metadata',
                        OutputIntent: 'HexaPDF::Type::OutputIntent',
                        XXDestOutputProfileRef: 'HexaPDF::Type::OutputIntent::DestOutputProfileRef',
                        ExData: 'HexaPDF::Type::Annotations::MarkupAnnotation::ExData',
                        CMap: 'HexaPDF::Type::CMap',
                        StructTreeRoot: 'HexaPDF::Type::StructTreeRoot',
                        StructElem: 'HexaPDF::Type::StructElem',
                        Namespace: 'HexaPDF::Type::Namespace',
                        MCR: 'HexaPDF::Type::MarkedContentReference',
                        OBJR: 'HexaPDF::Type::ObjectReference',
                        Measure: 'HexaPDF::Type::Measure',
                        DSS: 'HexaPDF::Type::DocumentSecurityStore',
                        VRI: 'HexaPDF::Type::DocumentSecurityStore::ValidationRelatedInformation',
                      },
                      'object.subtype_map' => {
                        nil => {
                          Image: 'HexaPDF::Type::Image',
                          Form: 'HexaPDF::Type::Form',
                          Type0: 'HexaPDF::Type::FontType0',
                          Type1: 'HexaPDF::Type::FontType1',
                          TrueType: 'HexaPDF::Type::FontTrueType',
                          CIDFontType0: 'HexaPDF::Type::CIDFont',
                          CIDFontType2: 'HexaPDF::Type::CIDFont',
                          GoTo: 'HexaPDF::Type::Actions::GoTo',
                          GoToR: 'HexaPDF::Type::Actions::GoToR',
                          Launch: 'HexaPDF::Type::Actions::Launch',
                          URI: 'HexaPDF::Type::Actions::URI',
                          SetOCGState: 'HexaPDF::Type::Actions::SetOCGState',
                          Text: 'HexaPDF::Type::Annotations::Text',
                          Link: 'HexaPDF::Type::Annotations::Link',
                          Widget: 'HexaPDF::Type::Annotations::Widget',
                          Line: 'HexaPDF::Type::Annotations::Line',
                          Square: 'HexaPDF::Type::Annotations::Square',
                          Circle: 'HexaPDF::Type::Annotations::Circle',
                          Polygon: 'HexaPDF::Type::Annotations::Polygon',
                          PolyLine: 'HexaPDF::Type::Annotations::Polyline',
                          XML: 'HexaPDF::Type::Metadata',
                          GTS_PDFX: 'HexaPDF::Type::OutputIntent',
                          GTS_PDFA1: 'HexaPDF::Type::OutputIntent',
                          ISO_PDFE1: 'HexaPDF::Type::OutputIntent',
                        },
                        XObject: {
                          Image: 'HexaPDF::Type::Image',
                          Form: 'HexaPDF::Type::Form',
                        },
                        Font: {
                          Type0: 'HexaPDF::Type::FontType0',
                          Type1: 'HexaPDF::Type::FontType1',
                          Type3: 'HexaPDF::Type::FontType3',
                          TrueType: 'HexaPDF::Type::FontTrueType',
                          CIDFontType0: 'HexaPDF::Type::CIDFont',
                          CIDFontType2: 'HexaPDF::Type::CIDFont',
                        },
                        Action: {
                          GoTo: 'HexaPDF::Type::Actions::GoTo',
                          GoToR: 'HexaPDF::Type::Actions::GoToR',
                          Launch: 'HexaPDF::Type::Actions::Launch',
                          URI: 'HexaPDF::Type::Actions::URI',
                          SetOCGState: 'HexaPDF::Type::Actions::SetOCGState',
                        },
                        Annot: {
                          Text: 'HexaPDF::Type::Annotations::Text',
                          Link: 'HexaPDF::Type::Annotations::Link',
                          Widget: 'HexaPDF::Type::Annotations::Widget',
                          Line: 'HexaPDF::Type::Annotations::Line',
                          Square: 'HexaPDF::Type::Annotations::Square',
                          Circle: 'HexaPDF::Type::Annotations::Circle',
                          Polygon: 'HexaPDF::Type::Annotations::Polygon',
                          PolyLine: 'HexaPDF::Type::Annotations::Polyline',
                        },
                        XXAcroFormField: {
                          Tx: 'HexaPDF::Type::AcroForm::TextField',
                          Btn: 'HexaPDF::Type::AcroForm::ButtonField',
                          Ch: 'HexaPDF::Type::AcroForm::ChoiceField',
                          Sig: 'HexaPDF::Type::AcroForm::SignatureField',
                        },
                        OutputIntent: {
                          GTS_PDFX: 'HexaPDF::Type::OutputIntent',
                          GTS_PDFA1: 'HexaPDF::Type::OutputIntent',
                          ISO_PDFE1: 'HexaPDF::Type::OutputIntent',
                        },
                      })

end
