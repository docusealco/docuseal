#!/usr/bin/env -S ruby

# :stopdoc:

require "optparse"
require "shellwords"

# complete -o bashdefault -f -C 'ruby lib/minitest/complete.rb' minitest
# using eg:
#    COMP_LINE="blah test/test_file.rb -n test_pattern"
# or test directly with:
#    ./lib/minitest/complete.rb test/test_file.rb -n test_pattern

argv = Shellwords.split ENV["COMP_LINE"] || ARGV.join(" ")
comp_re = nil

begin
  OptionParser.new do |opts|
    # part of my unofficial embedded gem "makeoptparseworkwell"
    def opts.topdict(name)   = (name.length > 1 ? top.long : top.short)
    def opts.alias(from, to) = (dict = topdict(from) ; dict[to] = dict[from])

    opts.on "-n", "--name [METHOD]", "minitest option" do |m|
      comp_re = Regexp.new m
    end

    opts.alias "name", "include"
    opts.alias "name", "exclude"
    opts.alias "n",    "i"
    opts.alias "n",    "e"
    opts.alias "n",    "x"
  end.parse! argv
rescue
  retry # ignore options passed to Ruby
end

path = argv.find_all { |f| File.file? f }.last

exit unless comp_re && path

require "prism"

names, queue = [], [Prism.parse_file(path).value]

while node = queue.shift do
  if node.type == :def_node then
    name = node.name
    names << name if name =~ comp_re
  else
    queue.concat node.compact_child_nodes # no need to process def body
  end
end

puts names.sort

# :startdoc:
