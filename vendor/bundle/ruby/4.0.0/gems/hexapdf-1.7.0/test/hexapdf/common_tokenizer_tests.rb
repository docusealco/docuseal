# -*- encoding: utf-8 -*-

require 'test_helper'

module CommonTokenizerTests
  extend Minitest::Spec::DSL

  it "next_token: returns all available kinds of tokens on next_token" do
    create_tokenizer(<<-EOF.chomp.gsub(/^ {8}/, ''))
        % Regular tokens
          		true false
        123 +17 -98 0 0059
        34.5 -3.62 +123.6 4. -.002 .002 0.0

        % Keywords
        obj endobj f* *f

        % Specials
        { }

        % Literal string tests
        (parenthese\\s ( ) and \\(\r
        special \\0053\\053\\53characters\r (*!&}^% and \\
        so \\\r
        on).\\n)
        ()

        % Hex strings
        <4E6F762073 686D6F7A20	6B612070
        6F702E>
        < 901FA3 ><901fA>

        % Names
        /Name1
        /ASomewhatLongerName
        /A;Name_With-Various***Characters?
        /1.2/$$
        /@pattern
        /.notdef
        /lime#20Green
        /paired#28#29parentheses
        /The_Key_of_F#23_Minor
        /A#42
        /

        % Arrays
        [ 5 6 /Name ]
        [5 6 /Name]

        % Dictionaries
        <</Name 5>>

        % Test
    EOF

    expected_tokens = [
      true, false,
      123, 17, -98, 0, 59,
      34.5, -3.62, 123.6, 4.0, -0.002, 0.002, 0.0,
      'obj', 'endobj', 'f*', '*f', '{', '}',
      "parentheses ( ) and (\nspecial \0053++characters\n (*!&}^% and so on).\n", '',
      "Nov shmoz ka pop.", "\x90\x1F\xA3", "\x90\x1F\xA0",
      :Name1, :ASomewhatLongerName, :'A;Name_With-Various***Characters?',
      :'1.2', :$$, :@pattern, :'.notdef', :'lime Green', :'paired()parentheses',
      :'The_Key_of_F#_Minor', :AB, :"",
      '[', 5, 6, :Name, ']', '[', 5, 6, :Name, ']',
      '<<', :Name, 5, '>>'
    ].map {|t| t.respond_to?(:force_encoding) ? t.b : t }

    until expected_tokens.empty?
      expected_token = expected_tokens.shift
      token = @tokenizer.next_token
      assert_equal(expected_token, token)
      assert_equal(Encoding::BINARY, token.encoding) if token.kind_of?(String)
    end
    assert_equal(0, expected_tokens.length)
    assert_equal(HexaPDF::Tokenizer::NO_MORE_TOKENS, @tokenizer.next_token)
  end

  it "next_token: should return name tokens in US-ASCII/UTF-8 or binary encoding" do
    create_tokenizer("/ASomewhatLongerName")
    token = @tokenizer.next_token
    assert_equal(:ASomewhatLongerName, token)
    assert_equal(Encoding::US_ASCII, token.encoding)

    create_tokenizer("/Hößgang")
    token = @tokenizer.next_token
    assert_equal(:Hößgang, token)
    assert_equal(Encoding::UTF_8, token.encoding)

    create_tokenizer('/H#c3#b6#c3#9fgang')
    token = @tokenizer.next_token
    assert_equal(:Hößgang, token)
    assert_equal(Encoding::UTF_8, token.encoding)

    create_tokenizer('/H#E8lp')
    token = @tokenizer.next_token
    assert_equal("H\xE8lp".b.intern, token)
    assert_equal(Encoding::BINARY, token.encoding)
  end

  it "next_token: fails on a greater than sign that is not part of a hex string" do
    create_tokenizer(" >")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_token }
  end

  it "next_token: fails on a closing parenthesis that is not part of a literal string" do
    create_tokenizer(" )")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_token }
  end

  it "next_token: fails on a missing greater than sign in a hex string" do
    create_tokenizer("<ABCD")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_token }
  end

  it "next_token: fails on unbalanced parentheses in a literal string" do
    create_tokenizer("(href(test)")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_token }
  end

  it "next_token: returns a PDF keyword for a solitary plus sign" do
    create_tokenizer("+")
    token = @tokenizer.next_token
    assert_equal("+", token)
    assert(token.kind_of?(HexaPDF::Tokenizer::Token))
  end

  it "next_object: works for all PDF object types, including array and dictionary" do
    create_tokenizer(<<-EOF.chomp.gsub(/^ {8}/, ''))
        true false null 123 34.5 (string) <4E6F76> /Name
        [5 6 /Name] <</Name 5/Null null>>
    EOF
    assert_equal(true, @tokenizer.next_object)
    assert_equal(false, @tokenizer.next_object)
    assert_nil(@tokenizer.next_object)
    assert_equal(123, @tokenizer.next_object)
    assert_equal(34.5, @tokenizer.next_object)
    assert_equal("string".b, @tokenizer.next_object)
    assert_equal("Nov".b, @tokenizer.next_object)
    assert_equal(:Name, @tokenizer.next_object)
    assert_equal([5, 6, :Name], @tokenizer.next_object)
    assert_equal({Name: 5}, @tokenizer.next_object)
  end

  it "next_object: allows keywords if the corresponding option is set" do
    create_tokenizer("name")
    obj = @tokenizer.next_object(allow_keyword: true)
    assert_kind_of(HexaPDF::Tokenizer::Token, obj)
    assert_equal('name', obj)
  end

  it "next_object: fails if the value is not a correct object" do
    create_tokenizer("<< /name ] >>")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    create_tokenizer("other")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    create_tokenizer("<< (string) (key) >>")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    create_tokenizer("<< /NoValueForKey >>")
    assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
  end

  it "next_object: fails for an array without closing bracket, encountering EOS" do
    create_tokenizer("[1 2")
    exception = assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    assert_match(/Unclosed array found/, exception.message)
  end

  it "next_object: fails for a dictionary without closing bracket, encountering EOS" do
    create_tokenizer("<</Name 5")
    exception = assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    assert_match(/must be PDF name objects.*EOS/, exception.message)
    create_tokenizer("<</Name 5 /Other")
    exception = assert_raises(HexaPDF::MalformedPDFError) { @tokenizer.next_object }
    assert_match(/must be PDF name objects.*EOS/, exception.message)
  end

  it "returns the correct position on operations" do
    create_tokenizer("hallo du" + " " * 50000 + "hallo du")
    @tokenizer.next_token
    assert_equal(5, @tokenizer.pos)

    @tokenizer.skip_whitespace
    assert_equal(6, @tokenizer.pos)

    @tokenizer.next_byte
    assert_equal(7, @tokenizer.pos)

    @tokenizer.peek_token
    assert_equal(7, @tokenizer.pos)

    @tokenizer.next_token
    assert_equal(8, @tokenizer.pos)

    @tokenizer.next_token
    assert_equal(50013, @tokenizer.pos)

    @tokenizer.next_token
    assert_equal(50016, @tokenizer.pos)

    @tokenizer.next_token
    assert_equal(50016, @tokenizer.pos)
  end

  it "returns the next byte" do
    create_tokenizer('hallo')
    assert_equal('h'.ord, @tokenizer.next_byte)
    assert_equal('a'.ord, @tokenizer.next_byte)
  end

  it "returns the next token but doesn't advance the position on peek_token" do
    create_tokenizer("hallo du")
    2.times do
      assert_equal('hallo', @tokenizer.peek_token)
      assert_equal(0, @tokenizer.pos)
    end
  end

  it "next_xref_entry: works on correct entries" do
    create_tokenizer("0000000001 00001 n \n0000000001 00032 f \n")
    assert_equal([1, 1, 'n'], @tokenizer.next_xref_entry)
    assert_equal([1, 32, 'f'], @tokenizer.next_xref_entry)
  end

  it "next_xref_entry: fails on invalidly formatted entries" do
    create_tokenizer("0000000001 00001 g \n")
    assert_raises(RuntimeError) { @tokenizer.next_xref_entry {|recoverable| refute(recoverable); raise } }
    create_tokenizer("0000000001 00001 n\n")
    assert_raises(RuntimeError) { @tokenizer.next_xref_entry {|recoverable| assert(recoverable); raise } }
    create_tokenizer("0000000001 00001 n\r")
    assert_raises(RuntimeError) { @tokenizer.next_xref_entry {|recoverable| assert(recoverable); raise } }
    create_tokenizer("0000000001 00001 n\r\r")
    assert_raises(RuntimeError) { @tokenizer.next_xref_entry {|recoverable| assert(recoverable); raise } }
  end
end
