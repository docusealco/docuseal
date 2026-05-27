$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'arabic-letter-connector/version'

Gem::Specification.new do |s|

  s.name          = 'arabic-letter-connector'
  s.version       = ArabicLetterConnector::VERSION
  s.date          = '2013-05-29'
  s.summary       = 'Arabic Letter Connector'
  s.description   = 'A tool to replace generic disconnected Arabic letters with their connected counterparts.'
  s.authors       = ["Sinan Taifour", "Ahmed Nasser"]
  s.email         = 'sinan@taifour.com'
  s.homepage      = 'http://github.com/staii/arabic-letter-connector'

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

end
