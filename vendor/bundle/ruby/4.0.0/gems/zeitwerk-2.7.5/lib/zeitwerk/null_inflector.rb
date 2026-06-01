class Zeitwerk::NullInflector
  #: (String, String) -> String
  def camelize(basename, _abspath)
    basename
  end
end
