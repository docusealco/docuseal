# frozen_string_literal: true
module Haml
  # Compile [:multi, [:static, 'foo'], [:dynamic, 'bar']] to [:dynamic, '"foo#{bar}"']
  class DynamicMerger < Temple::Filter
    def on_multi(*exps)
      exps = exps.dup
      result = [:multi]
      buffer = []

      until exps.empty?
        type, arg = exps.first
        if type == :dynamic && arg.count("\n") == 0
          buffer << exps.shift
        elsif type == :static && exps.size > (count = arg.count("\n")) &&
              exps[1, count].all? { |e| e == [:newline] }
          (1 + count).times { buffer << exps.shift }
        elsif type == :newline && exps.size > (count = count_newline(exps)) &&
              exps[count].first == :static && count == exps[count].last.count("\n")
          (count + 1).times { buffer << exps.shift }
        else
          result.concat(merge_dynamic(buffer))
          buffer = []
          result << compile(exps.shift)
        end
      end
      result.concat(merge_dynamic(buffer))

      result.size == 2 ? result[1] : result
    end

    private

    def merge_dynamic(exps)
      # Merge exps only when they have both :static and :dynamic
      unless exps.any? { |type,| type == :static } && exps.any? { |type,| type == :dynamic }
        return exps
      end

      strlit_body = String.new
      exps.each do |type, arg|
        case type
        when :static
          strlit_body << arg.dump.sub!(/\A"/, '').sub!(/"\z/, '').gsub('\n', "\n")
        when :dynamic
          strlit_body << "\#{#{arg}}"
        when :newline
          # newline is added by `gsub('\n', "\n")`
        else
          raise "unexpected type #{type.inspect} is given to #merge_dynamic"
        end
      end
      [[:dynamic, "%Q\0#{strlit_body}\0"]]
    end

    def count_newline(exps)
      count = 0
      exps.each do |exp|
        if exp == [:newline]
          count += 1
        else
          return count
        end
      end
      return count
    end
  end
end
