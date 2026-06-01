require "test_helper"

module MockAttributes
  def self.included(base)
    base.attribute :foo
    base.attribute :bar
    base.attribute :biz
    base.attribute :baz
    base.attribute :bang
    base.attribute :foz
    base.attribute :fiz
    base.attribute :qax
    base.attribute :qux
    base.attribute :strip_me
    base.attribute :skip_me
    base.attribute :frozen
  end
end

class StripAllMockRecord < Tableless
  include MockAttributes
  strip_attributes
end

class StripOnlyOneMockRecord < Tableless
  include MockAttributes
  strip_attributes only: :foo
end

class StripOnlyThreeMockRecord < Tableless
  include MockAttributes
  strip_attributes only: [:foo, :bar, :biz]
end

class StripExceptOneMockRecord < Tableless
  include MockAttributes
  strip_attributes except: :foo
end

class StripExceptThreeMockRecord < Tableless
  include MockAttributes
  strip_attributes except: [:foo, :bar, :biz]
end

class StripAllowEmpty < Tableless
  include MockAttributes
  strip_attributes allow_empty: true
end

class CollapseDuplicateSpaces < Tableless
  include MockAttributes
  strip_attributes collapse_spaces: true
end

class ReplaceNewLines < Tableless
  include MockAttributes
  strip_attributes replace_newlines: true
end

class ReplaceNewLinesAndDuplicateSpaces < Tableless
  include MockAttributes
  strip_attributes replace_newlines: true, collapse_spaces: true
end

class CoexistWithOtherObjects < Tableless
  attr_accessor :arr, :hsh, :str
  strip_attributes
  def initialize
    @arr, @hsh, @str = [], {}, "foo "
  end
  def attributes
    {arr: arr, hsh: hsh, str: str}
  end
end

class CoexistWithOtherValidations < Tableless
  attribute :number, type: Integer

  strip_attributes
  validates :number, {
    numericality: { only_integer: true,  greater_than_or_equal_to: 1000 },
    allow_blank: true
  }
end

class StripRegexMockRecord < Tableless
  include MockAttributes
  strip_attributes regex: /[\^\%&\*]/
end

class IfSymMockRecord < Tableless
  include MockAttributes
  strip_attributes if: :strip_me?

  def strip_me?
    strip_me
  end
end

class UnlessSymMockRecord < Tableless
  include MockAttributes
  strip_attributes unless: :skip_me?

  def skip_me?
    skip_me
  end
end

class IfProcMockRecord < Tableless
  include MockAttributes
  strip_attributes if: Proc.new { |record| record.strip_me }
end

class StripAttributesTest < Minitest::Test
  def setup
    @init_params = {
      foo:  "\tfoo",
      bar:  "bar \t ",
      biz:  "\tbiz ",
      baz:  "",
      bang: " ",
      foz:  " foz  foz",
      fiz:  "fiz \n  fiz",
      qax:  "\n\t ",
      qux:  "\u200B"
    }
  end

  def test_should_exist
    assert Object.const_defined?(:StripAttributes)
  end

  def test_should_strip_all_fields
    record = StripAllMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
    assert_nil record.qax
    assert_nil record.qux
  end

  def test_should_strip_only_one_field
    record = StripOnlyOneMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar \t ",     record.bar
    assert_equal "\tbiz ",      record.biz
    assert_equal " foz  foz",   record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal " ",           record.bang
  end

  def test_should_strip_only_three_fields
    record = StripOnlyThreeMockRecord.new(@init_params)
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal " foz  foz",   record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal " ",           record.bang
  end

  def test_should_strip_all_except_one_field
    record = StripExceptOneMockRecord.new(@init_params)
    record.valid?
    assert_equal "\tfoo",       record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_all_except_three_fields
    record = StripExceptThreeMockRecord.new(@init_params)
    record.valid?
    assert_equal "\tfoo",       record.foo
    assert_equal "bar \t ",     record.bar
    assert_equal "\tbiz ",      record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_and_allow_empty
    record = StripAllowEmpty.new(@init_params)
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal "",            record.bang
  end

  def test_should_not_mutate_values
    record = StripAllMockRecord.new(foo: " foo ")
    old_value = record.foo
    record.valid?
    assert_equal "foo",        record.foo
    refute_equal old_value,    record.foo
  end

  def test_should_collapse_duplicate_spaces
    record = CollapseDuplicateSpaces.new(@init_params)
    record.valid?
    assert_equal "foo",        record.foo
    assert_equal "bar",        record.bar
    assert_equal "biz",        record.biz
    assert_equal "foz foz",    record.foz
    assert_equal "fiz \n fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_replace_newlines
    record = ReplaceNewLines.new(@init_params)
    record.valid?
    assert_equal "foo",        record.foo
    assert_equal "bar",        record.bar
    assert_equal "biz",        record.biz
    assert_equal "foz  foz",   record.foz
    assert_equal "fiz    fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_replace_newlines_and_duplicate_spaces
    record = ReplaceNewLinesAndDuplicateSpaces.new(@init_params)
    record.valid?
    assert_equal "foo",     record.foo
    assert_equal "bar",     record.bar
    assert_equal "biz",     record.biz
    assert_equal "foz foz", record.foz
    assert_equal "fiz fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_and_allow_empty_always
    record = StripAllowEmpty.new(@init_params)
    record.valid?
    record.assign_attributes(@init_params)
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal "",            record.bang
  end

  def test_should_allow_other_empty_objects
    record = CoexistWithOtherObjects.new
    record.valid?
    assert_equal [],    record.arr
    assert_equal({},    record.hsh)
    assert_equal "foo", record.str
  end

  def test_should_coexist_with_other_validations
    record = CoexistWithOtherValidations.new
    record.number = 1000.1
    assert !record.valid?, "Expected record to be invalid"
    assert record.errors.include?(:number), "Expected record to have an error on :number"

    record = CoexistWithOtherValidations.new(number: " 1000.2 ")
    assert !record.valid?, "Expected record to be invalid"
    assert record.errors.include?(:number), "Expected record to have an error on :number"

    # record = CoexistWithOtherValidations.new(number: " 1000 ")
    # assert record.valid?, "Expected record to be valid, but got #{record.errors.full_messages}"
    # assert !record.errors.include?(:number), "Expected record to have no errors on :number"
  end

  def test_should_strip_regex
    record = StripRegexMockRecord.new
    record.assign_attributes(@init_params.merge(foo: "^%&*abc  "))
    record.valid?
    assert_equal "abc",        record.foo
    assert_equal "bar",        record.bar
  end

  def test_should_strip_unicode
    skip "multi-byte characters not supported by this version of Ruby" unless StripAttributes::MULTIBYTE_SUPPORTED

    record = StripOnlyOneMockRecord.new({foo: "\u200A\u200B foo\u200A\u200B\u00A0 "})
    record.valid?
    assert_equal "foo",      record.foo
  end

  def test_should_strip_all_fields_if_true
    record = IfSymMockRecord.new(@init_params.merge(strip_me: true))
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_no_fields_if_false
    record = IfSymMockRecord.new(@init_params.merge(strip_me: false))
    record.valid?
    assert_equal "\tfoo",       record.foo
    assert_equal "bar \t ",     record.bar
    assert_equal "\tbiz ",      record.biz
    assert_equal " foz  foz",   record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal " ",           record.bang
  end

  def test_should_strip_all_fields_unless_false
    record = UnlessSymMockRecord.new(@init_params.merge(skip_me: false))
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_no_fields_unless_true
    record = UnlessSymMockRecord.new(@init_params.merge(skip_me: true))
    record.valid?
    assert_equal "\tfoo",       record.foo
    assert_equal "bar \t ",     record.bar
    assert_equal "\tbiz ",      record.biz
    assert_equal " foz  foz",   record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal " ",           record.bang
  end

  def test_should_strip_all_fields_if_true_proc
    record = IfProcMockRecord.new(@init_params.merge(strip_me: true))
    record.valid?
    assert_equal "foo",         record.foo
    assert_equal "bar",         record.bar
    assert_equal "biz",         record.biz
    assert_equal "foz  foz",    record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_nil record.baz
    assert_nil record.bang
  end

  def test_should_strip_no_fields_if_false_proc
    record = IfProcMockRecord.new(@init_params.merge(strip_me: false))
    record.valid?
    assert_equal "\tfoo",       record.foo
    assert_equal "bar \t ",     record.bar
    assert_equal "\tbiz ",      record.biz
    assert_equal " foz  foz",   record.foz
    assert_equal "fiz \n  fiz", record.fiz
    assert_equal "",            record.baz
    assert_equal " ",           record.bang
  end

  class ClassMethodsTest < Minitest::Test
    def test_should_strip_whitespace
      assert_nil StripAttributes.strip("")
      assert_nil StripAttributes.strip(" \t ")
      assert_equal "thirty six", StripAttributes.strip(" thirty six \t \n")
    end

    def test_should_allow_empty
      assert_equal "", StripAttributes.strip("", allow_empty: true)
      assert_equal "", StripAttributes.strip(" \t ", allow_empty: true)
    end

    def test_should_collapse_spaces
      assert_equal "1 2 3", StripAttributes.strip(" 1   2   3\t ", collapse_spaces: true)
    end

    def test_should_collapse_multibyte_spaces
      assert_equal "1 2 3", StripAttributes.strip(" 1 \u00A0  2\u00A03\t ", collapse_spaces: true)
    end

    def test_should_replace_newlines
      assert_equal "1 2", StripAttributes.strip("1\n2", replace_newlines: true)
      assert_equal "1 2", StripAttributes.strip("1\r\n2", replace_newlines: true)
      assert_equal "1 2", StripAttributes.strip("1\r2", replace_newlines: true)
    end

    def test_should_strip_regex
      assert_equal "abc", StripAttributes.strip("^%&*abc  ^  ", regex: /[\^\%&\*]/)
    end

    def test_should_keep_only_alphanumerics
      nickname = " funky BAT-2009"
      assert_equal "funkyBAT-2009", StripAttributes.strip(nickname, regex: /[^[:alnum:]_-]/)
    end

    def test_should_strip_trailing_whitespace
      messy_code =
        "const hello = (name) => {      \n" +
        "  if (name === 'voldemort') return; \n" +
        "  \n" +
        "  console.log(`Hello ${name}!`); \t \t \n" +
        "};  \n"
      expected = <<~EOF.strip
        const hello = (name) => {
          if (name === 'voldemort') return;

          console.log(`Hello ${name}!`);
        };
      EOF
      actual = StripAttributes.strip(messy_code, regex: /[[:blank:]]+$/)
      assert_equal expected, actual
    end

    def test_should_strip_unicode
      skip "multi-byte characters not supported by this version of Ruby" unless StripAttributes::MULTIBYTE_SUPPORTED

      assert_equal "foo", StripAttributes.strip("\u200A\u200B foo\u200A\u200B ")
      assert_equal "foo\u20AC".b, StripAttributes.strip("foo\u20AC ".b)
    end
  end
end
