# frozen_string_literal: true

class Pry
  module Input
    # Readline replacement for low-capability terminals.
    class SimpleStdio
      def self.readline(prompt)
        Pry.config.output.print(prompt)
        $stdin.gets
      end
    end
  end
end
