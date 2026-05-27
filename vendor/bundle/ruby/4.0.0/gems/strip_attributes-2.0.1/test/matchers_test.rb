begin
  require "minitest/matchers_vaccine"
rescue LoadError
  require "minitest/matchers"
end
require "test_helper"
require "strip_attributes/matchers"

class SampleMockRecord < Tableless
  attribute :stripped1
  attribute :stripped2
  attribute :stripped3
  attribute :unstripped1
  attribute :unstripped2
  attribute :unstripped3
  strip_attributes only: [:stripped1, :stripped2, :stripped3]

  attribute :collapsed
  attribute :uncollapsed
  strip_attributes only: [:collapsed], collapse_spaces: true

  attribute :replaceable
  attribute :unreplaceable
  strip_attributes only: [:replaceable], replace_newlines: true

  attribute :upcased
  strip_attributes only: [:upcased]

  def upcased=(value)
    super((value.upcase if value))
  end
end

describe SampleMockRecord do
  include StripAttributes::Matchers

  subject { SampleMockRecord.new }

  if defined? Minitest::MatchersVaccine
    it "should strip strippable attributes" do
      must strip_attribute :stripped1
      must strip_attribute :stripped2
      must strip_attribute :stripped3
    end

    it "should not strip other attributes" do
      wont strip_attribute :unstripped1
      wont strip_attribute :unstripped2
      wont strip_attribute :unstripped3
    end

    it "should collapse collapsible attributes" do
      must strip_attribute(:collapsed).collapse_spaces
    end

    it "should not collapse other attributes" do
      wont strip_attribute(:uncollapsed).collapse_spaces
    end

    it "should replace replaceable attributes" do
      must strip_attribute(:replaceable).replace_newlines
    end

    it "should not replace on other attributes" do
      wont strip_attribute(:unreplaceable).replace_newlines
    end

    it "should not strip normalized attributes missing a custom value" do
      wont strip_attribute(:upcased)
      wont strip_attribute(:upcased).using("fOO")
    end

    it "should strip normalized attributes using a custom value" do
      must strip_attribute(:upcased).using("BIG")
    end
  else
    must { strip_attribute :stripped1 }
    must { strip_attribute :stripped2 }
    must { strip_attribute :stripped3 }
    wont { strip_attribute :unstripped1 }
    wont { strip_attribute :unstripped2 }
    wont { strip_attribute :unstripped3 }

    must { strip_attribute(:collapsed).collapse_spaces }
    wont { strip_attribute(:uncollapsed).collapse_spaces }

    must { strip_attribute(:replaceable).replace_newlines }
    wont { strip_attribute(:unreplaceable).replace_newlines }

    wont { strip_attribute(:upcased) }
    wont { strip_attribute(:upcased).using("fOO") }
    must { strip_attribute(:upcased).using("BIG") }
  end

  it "should fail when testing for strip on an unstripped attribute" do
    begin
      assert_must strip_attribute(:unstripped1)
      assert false
    rescue
      assert true
    end
  end

  it "should fail when testing for no strip on a stripped attribute" do
    begin
      assert_wont strip_attribute(:stripped1)
      assert false
    rescue
      assert true
    end
  end

  it "should fail when testing for collapse on an uncollapsed attribute" do
    begin
      assert_must collapse_attribute(:uncollapsed)
      assert false
    rescue
      assert true
    end
  end

  it "should fail when testing for no collapse on a collapsed attribute" do
    begin
      assert_wont collapse_attribute(:collapsed)
      assert false
    rescue
      assert true
    end
  end

  it "should fail when testing for replacement on an unreplaceable attribute" do
    begin
      assert_must replace_newlines(:unreplaceable)
      assert false
    rescue
      assert true
    end
  end

  it "should fail when testing for no replacement on a replaceable attribute" do
    begin
      assert_wont replace_newlines(:replaceable)
      assert false
    rescue
      assert true
    end
  end

  it "should take a list of arguments" do
    must strip_attribute(:stripped1, :stripped2, :stripped3)
    wont strip_attribute(:unstripped1, :unstripped2, :unstripped3)
  end

  it "should alias strip_attribute to strip_attributes" do
    must strip_attributes(:stripped1, :stripped2, :stripped3)
    wont strip_attributes(:unstripped1, :unstripped2, :unstripped3)
  end
end
