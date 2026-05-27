# encoding: UTF-8
require "bigdecimal"

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

[Integer, Float, BigDecimal].each do |klass|
  TwitterCldr::Localized::LocalizedNumber.localize(klass)
end

[Array, Date, DateTime, String, Symbol, Time, Hash].each do |klass|
  TwitterCldr::Localized::const_get("Localized#{klass}").localize(klass)
end
