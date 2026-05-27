#!/usr/bin/env ruby
# if something is changed here -> change line numbers in doc/tutorial.page

require 'cmdparse'

class NetStatCommand < CmdParse::Command

  def initialize
    super('stat', takes_commands: false)
    short_desc("Show network statistics")
    long_desc("This command shows very useful 'network' statistics - eye catching!!!")
    argument_desc(M: 'start row number', N: 'end row number')
  end

  def execute(m = 1, n)
    puts "Showing network statistics" if command_parser.data[:verbose]
    puts
    m.to_i.upto(n.to_i) do |row|
      puts " "*(20 - row).abs + "#"*(row*2 - 1).abs
    end
    puts
  end

end

parser = CmdParse::CommandParser.new(handle_exceptions: :no_help)
parser.main_options.program_name = "net"
parser.main_options.version = "0.1.1"
parser.main_options.banner = "This is net, a s[ai]mple network analytics program"
parser.global_options do |opt|
  opt.on("-v", "--verbose", "Be verbose when outputting info") do
    parser.data[:verbose] = true
  end
end
parser.add_command(CmdParse::HelpCommand.new, default: true)
parser.add_command(CmdParse::VersionCommand.new)
parser.add_command(NetStatCommand.new)

# ipaddr
ipaddr = CmdParse::Command.new('ipaddr')
ipaddr.short_desc = "Manage IP addresses"
parser.add_command(ipaddr, default: true)

# ipaddr add
ipaddr.add_command('add') do |cmd|
  cmd.takes_commands(false)
  cmd.short_desc("Add an IP address")
  cmd.action do |*ips|
    puts "Adding ip addresses: #{ips.join(', ')}" if parser.data[:verbose]
    parser.data[:ipaddrs] += ips
  end
end

# ipaddr del
del = CmdParse::Command.new('del', takes_commands: false)
del.short_desc = "Delete an IP address"
del.options.on('-a', '--all', 'Delete all IPs') { del.data[:delete_all] = true }
del.action do |*ips|
  if del.data[:delete_all]
    puts "All IP adresses deleted!" if parser.data[:verbose]
    parser.data[:ipaddrs] = []
  else
    puts "Deleting ip addresses: #{ips.join(', ')}" if parser.data[:verbose]
    ips.each {|ip| parser.data[:ipaddrs].delete(ip) }
  end
end
ipaddr.add_command(del)

# ipaddr list
list = CmdParse::Command.new('list', takes_commands: false)
list.short_desc = "Lists all IP addresses"
list.action do
  puts "Listing ip addresses:" if parser.data[:verbose]
  puts parser.data[:ipaddrs].join("\n") unless parser.data[:ipaddrs].empty?
end
ipaddr.add_command(list, default: true)


parser.data[:ipaddrs] = if File.exists?('dumpnet')
                          Marshal.load(File.read('dumpnet', mode: 'rb'))
                        else
                          []
                        end
parser.parse
File.write('dumpnet', Marshal.dump(parser.data[:ipaddrs]), mode: 'wb+')
