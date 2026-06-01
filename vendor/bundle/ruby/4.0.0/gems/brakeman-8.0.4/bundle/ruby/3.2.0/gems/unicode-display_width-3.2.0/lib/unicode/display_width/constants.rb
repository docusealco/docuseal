# frozen_string_literal: true

module Unicode
  class DisplayWidth
    VERSION = "3.2.0"
    UNICODE_VERSION = "17.0.0"
    DATA_DIRECTORY = File.expand_path(File.dirname(__FILE__) + "/../../../data/")
    INDEX_FILENAME = DATA_DIRECTORY + "/display_width.marshal.gz"
  end
end
