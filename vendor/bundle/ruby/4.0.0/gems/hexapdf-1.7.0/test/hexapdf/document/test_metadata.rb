# -*- encoding: utf-8 -*-

require 'test_helper'
require 'stringio'
require 'hexapdf/document'

describe HexaPDF::Document::Metadata do
  before do
    @doc = HexaPDF::Document.new
    @doc.trailer.info[:Title] = 'Title'
    @metadata = @doc.metadata
  end

  it "parses the info dictionary on creation" do
    assert_equal('Title', @metadata.title)

    time = Time.now
    @doc.trailer.info[:ModDate] = ''
    assert_nil(HexaPDF::Document::Metadata.new(@doc).modification_date)
    @doc.trailer.info[:ModDate] = time
    assert_equal(time, HexaPDF::Document::Metadata.new(@doc).modification_date)
    @doc.trailer.info[:CreationDate] = ''
    assert_nil(HexaPDF::Document::Metadata.new(@doc).creation_date)
    @doc.trailer.info[:CreationDate] = time
    assert_equal(time, HexaPDF::Document::Metadata.new(@doc).creation_date)

    @doc.trailer.info[:Trapped] = :Unknown
    assert_nil(HexaPDF::Document::Metadata.new(@doc).trapped)
    @doc.trailer.info[:Trapped] = :True
    assert_equal(true, HexaPDF::Document::Metadata.new(@doc).trapped)
    @doc.trailer.info[:Trapped] = :False
    assert_equal(false, HexaPDF::Document::Metadata.new(@doc).trapped)
  end

  describe "default_language" do
    it "use the document's language as default" do
      @doc.catalog[:Lang] = 'de'
      assert_equal("de", HexaPDF::Document::Metadata.new(@doc).default_language)
    end

    it "falls back to the default language if the document doesn't have a default language set" do
      assert_equal('x-default', @metadata.default_language)
    end

    it "allows changing the default language" do
      @metadata.default_language('de')
      assert_equal('de', @metadata.default_language)
    end
  end

  it "enables writing the info dict by default" do
    assert(@metadata.write_info_dict?)
  end

  it "allows setting whether the info dict is written" do
    @metadata.write_info_dict(false)
    refute(@metadata.write_info_dict?)
  end

  it "enables writing the metadata stream by default" do
    assert(@metadata.write_metadata_stream?)
  end

  it "allows setting whether the metadata stream is written" do
    @metadata.write_metadata_stream(false)
    refute(@metadata.write_metadata_stream?)
  end

  it "resolves namespace URI via a prefix" do
    assert_equal('http://www.w3.org/1999/02/22-rdf-syntax-ns#', @metadata.namespace('rdf'))
  end

  it "allows registering prefixes for namespaces" do
    err = assert_raises(HexaPDF::Error) { @metadata.namespace('hexa') }
    assert_match(/prefix.*hexa.*not registered/, err.message)
    @metadata.register_namespace('hexa', 'hexa:')
    assert_equal('hexa:', @metadata.namespace('hexa'))
  end

  it "allows registering property types" do
    @metadata.register_property_type('dc', 'title', 'Boolean')
    assert_equal('Boolean', @metadata.instance_variable_get(:@properties)[@metadata.namespace('dc')]['title'])
  end

  it "allows reading and setting properties" do
    assert_equal('Title', @metadata.property('dc', 'title'))
    @metadata.property('dc', 'title', 'another')
    assert_equal('another', @metadata.property('dc', 'title'))
    @metadata.property('dc', 'title', nil)
    assert_nil(@metadata.property('dc', 'title'))
    refute(@metadata.instance_variable_get(:@metadata)[@metadata.namespace('dc')].key?('title'))
  end

  describe "delete" do
    it "deletes all properties" do
      @metadata.delete
      assert(@metadata.instance_variable_get(:@metadata).empty?)
    end

    it "deletes all properties of a single namespace" do
      @metadata.creator('Test')
      @metadata.delete('dc')
      assert_equal('Test', @metadata.creator)
      refute(@metadata.instance_variable_get(:@metadata).key?(@metadata.namespace('dc')))
    end

    it "deletes a specific property" do
      @metadata.delete('dc', 'title')
      assert_nil(@metadata.title)
    end
  end

  it "allows reading and setting all info dictionary properties" do
    [['title', 'dc', 'title'], ['author', 'dc', 'creator'], ['subject', 'dc', 'description'],
     ['keywords', 'pdf', 'Keywords'], ['creator', 'xmp', 'CreatorTool'],
     ['producer', 'pdf', 'Producer'], ['creation_date', 'xmp', 'CreateDate'],
     ['modification_date', 'xmp', 'ModifyDate'], ['trapped', 'pdf', 'Trapped']].each do |name, ns, property|
      @metadata.property(ns, property, 'value')
      assert_equal('value', @metadata.send(name), name)
      @metadata.send(name, 'modified')
      assert_equal('modified', @metadata.property(ns, property), name)
    end
  end

  describe "metadata writing" do
    before do
      @time = Time.now.floor
      @metadata.title('Title')
      @metadata.author('Author')
      @metadata.subject('Subject')
      @metadata.keywords('Keywords')
      @metadata.creator('Creator')
      @metadata.producer('Producer')
      @metadata.creation_date(@time)
      @metadata.modification_date(@time)
      @metadata.trapped(true)
    end

    it "writes the info dictionary properties" do
      info = @doc.trailer.info
      @doc.write(StringIO.new, update_fields: false)
      assert_equal('Title', info[:Title])
      assert_equal('Author', info[:Author])
      assert_equal('Subject', info[:Subject])
      assert_equal('Keywords', info[:Keywords])
      assert_equal('Creator', info[:Creator])
      assert_match(/HexaPDF/, info[:Producer])
      assert_same(@time, info[:CreationDate])
      assert_same(@time, info[:ModDate])
      assert_equal(:True, info[:Trapped])
    end

    it "omits values in the info dictionary that are not set" do
      @metadata.delete('pdf', 'Trapped')
      @metadata.delete('dc', 'title')
      @metadata.delete('dc', 'creator')
      @doc.write(StringIO.new, update_fields: false)
      info = @doc.trailer.info
      refute(info.key?(:Title))
      refute(info.key?(:Author))
      refute(info.key?(:Trapped))
    end

    it "uses a correctly updated modification date if set so by Document#write" do
      info = @doc.trailer.info
      sleep(0.1)
      @doc.write(StringIO.new)
      assert_same(@time, info[:CreationDate])
      refute_same(@time, info[:ModDate])
      assert(@time < info[:ModDate])
    end

    it "correctly handles array values for title, author, and subject for info dictionary" do
      @metadata.title(['Title', 'Another'])
      @metadata.author(['Author', 'Author2'])
      @metadata.subject(['Subject', 'Another'])
      @doc.write(StringIO.new)
      info = @doc.trailer.info
      assert_equal('Title', info[:Title])
      assert_equal('Author, Author2', info[:Author])
      assert_equal('Subject', info[:Subject])
    end

    it "omits rdf:Description elements without values" do
      @metadata.delete
      @doc.write(StringIO.new, update_fields: false)
      metadata = <<~XMP
        <?xpacket begin="﻿" id=""?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
        <pdf:Producer>HexaPDF version #{HexaPDF::VERSION}</pdf:Producer>
        </rdf:Description>
        </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="r"?>
      XMP
      assert_equal(metadata, @doc.catalog[:Metadata].stream.sub(/(?<=id=")\w+/, ''))
    end

    it "writes the custom metadata" do
      @metadata.delete
      @metadata.custom_metadata("<rdf:Description>Test</rdf:Description>")
      @metadata.custom_metadata("<rdf:Description>Test2</rdf:Description>")
      @doc.write(StringIO.new, update_fields: false)
      metadata = <<~XMP
        <?xpacket begin="﻿" id=""?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
        <pdf:Producer>HexaPDF version #{HexaPDF::VERSION}</pdf:Producer>
        </rdf:Description>
        <rdf:Description>Test</rdf:Description>
        <rdf:Description>Test2</rdf:Description>
        </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="r"?>
      XMP
      assert_equal(metadata, @doc.catalog[:Metadata].stream.sub(/(?<=id=")\w+/, ''))
    end

    it "writes the XMP metadata" do
      title = HexaPDF::Document::Metadata::LocalizedString.new('Der Titel')
      title.language = 'de'
      @metadata.title(['Title', title])
      @metadata.author(['Author 1', 'Author 2'])
      @metadata.creation_date('')
      @metadata.register_property_type('dc', 'other', 'URI')
      @metadata.property('dc', 'other', 'https://test.org/example')
      @metadata.property('pdfaid', 'part', 3)
      @metadata.property('pdfaid', 'conformance', 'b')
      @doc.write(StringIO.new, update_fields: false)
      metadata = <<~XMP
        <?xpacket begin="﻿" id=""?>
        <x:xmpmeta xmlns:x="adobe:ns:meta/">
        <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description rdf:about="" xmlns:dc="http://purl.org/dc/elements/1.1/">
        <dc:title><rdf:Alt>
        <rdf:li xml:lang="x-default">Title</rdf:li>
        <rdf:li xml:lang="de">Der Titel</rdf:li>
        </rdf:Alt></dc:title>
        <dc:creator><rdf:Seq>
        <rdf:li>Author 1</rdf:li>
        <rdf:li>Author 2</rdf:li>
        </rdf:Seq></dc:creator>
        <dc:description><rdf:Alt>
        <rdf:li xml:lang="x-default">Subject</rdf:li>
        </rdf:Alt></dc:description>
        <dc:other rdf:resource="https://test.org/example" />
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:pdf="http://ns.adobe.com/pdf/1.3/">
        <pdf:Keywords>Keywords</pdf:Keywords>
        <pdf:Producer>HexaPDF version #{HexaPDF::VERSION}</pdf:Producer>
        <pdf:Trapped>True</pdf:Trapped>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:xmp="http://ns.adobe.com/xap/1.0/">
        <xmp:CreatorTool>Creator</xmp:CreatorTool>
        <xmp:CreateDate></xmp:CreateDate>
        <xmp:ModifyDate>#{@metadata.send(:xmp_date, @time)}</xmp:ModifyDate>
        </rdf:Description>
        <rdf:Description rdf:about="" xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">
        <pdfaid:part>3</pdfaid:part>
        <pdfaid:conformance>b</pdfaid:conformance>
        </rdf:Description>
        </rdf:RDF>
        </x:xmpmeta>
        <?xpacket end="r"?>
      XMP
      assert_equal(metadata, @doc.catalog[:Metadata].stream.sub(/(?<=id=")\w+/, ''))
    end

    it "respects the write settings for info dictionary and metadata stream" do
      @metadata.write_info_dict(false)
      @metadata.write_metadata_stream(false)
      @doc.write(StringIO.new)
      assert_nil(@doc.trailer.info[:Author])
      refute(@doc.catalog.key?(:Metadata))
    end
  end
end
