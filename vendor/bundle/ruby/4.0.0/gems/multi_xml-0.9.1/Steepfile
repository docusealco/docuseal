D = Steep::Diagnostic

target :lib do
  signature "sig"

  # Check core library files (excluding parser implementations that depend on optional gems)
  check "lib/multi_xml.rb"
  check "lib/multi_xml/constants.rb"
  check "lib/multi_xml/errors.rb"
  check "lib/multi_xml/file_like.rb"
  check "lib/multi_xml/helpers.rb"
  check "lib/multi_xml/version.rb"

  # Use stdlib types
  library "date"
  library "time"
  library "yaml"
  library "bigdecimal"
  library "stringio"

  configure_code_diagnostics(D::Ruby.strict) do |hash|
    # The fiber-local Fiber[] reader returns untyped — intentional
    # for with_parser's previous_override save/restore.
    hash[D::Ruby::FallbackAny] = :hint
    # set_backtrace has three overloads and Steep can't pick one when
    # given an `(Array[String] | nil)` union from `cause.backtrace`.
    hash[D::Ruby::UnresolvedOverloading] = :hint
  end
end
