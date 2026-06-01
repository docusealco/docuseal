require_relative "mtime_strategy"
require_relative "digest_strategy"

module Shakapacker
  class CompilerStrategy
    def self.from_config
      strategy_from_config = Shakapacker.config.compiler_strategy

      case strategy_from_config
      when "mtime"
        Shakapacker::MtimeStrategy.new
      when "digest"
        Shakapacker::DigestStrategy.new
      else
        raise "Unknown strategy '#{strategy_from_config}'. " \
              "Available options are 'mtime' and 'digest'."
      end
    end
  end
end
