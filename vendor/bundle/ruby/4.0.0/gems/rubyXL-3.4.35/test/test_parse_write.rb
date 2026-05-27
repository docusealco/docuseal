require 'rubyXL'
require 'benchmark'

spreadsheets = Dir.glob(File.join('test', 'input', '*.xls?')).sort!

spreadsheets.each { |input|
  puts "<<<--- Parsing #{input}..."
  doc = nil
  tm = Benchmark.realtime { doc = RubyXL::Parser.parse(input) }
  puts "Elapsed: #{tm} sec"
  output = File.join('test', 'output', File.basename(input))
  puts "--->>> Writing #{output}..."
  tm = Benchmark.realtime { doc.write(output) }
  puts "Elapsed: #{tm} sec"
}
