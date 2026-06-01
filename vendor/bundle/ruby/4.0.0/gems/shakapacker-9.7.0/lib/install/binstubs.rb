require "shakapacker/install/env"

# template.rb sets @conflict_option first during normal install flow.
# ||= keeps binstubs runnable standalone (e.g., rake shakapacker:binstubs).
@conflict_option ||= Shakapacker::Install::Env.conflict_option

say "Copying binstubs"
directory "#{__dir__}/bin", "bin", @conflict_option

chmod "bin", 0755 & ~File.umask, verbose: false
