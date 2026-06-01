require "spec_helper"
require "foreman"

describe Foreman do

  describe "VERSION" do
    subject { Foreman::VERSION }
    it { is_expected.to be_a String }
  end

  describe "runner" do
    it "should exist" do
      expect(File.exist?(Foreman.runner)).to eq(true)
    end
  end
end
