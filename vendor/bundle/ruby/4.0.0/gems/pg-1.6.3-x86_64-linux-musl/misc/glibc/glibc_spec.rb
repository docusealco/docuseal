RSpec.describe "require 'pg'" do
  it "gives a descriptive error message when GLIBC is too old" do
    expect { require "pg" }.to raise_error(/GLIBC.*gem install pg --platform ruby/m)
  end
end
