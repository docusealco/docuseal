# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

# This code was adapted from GNU Classpath, but modified significantly.  Ordinarily, derivatives are
# treated as falling under the same license as the original source, but classpath comes with the
# following exception:
#
# "As a special exception, the copyright holders of this library give you
# permission to link this library with independent modules to produce an
# executable, regardless of the license terms of these independent
# modules, and to copy and distribute the resulting executable under
# terms of your choice, provided that you also meet, for each linked
# independent module, the terms and conditions of the license of that
# module.  An independent module is a module which is not derived from
# or based on this library.  If you modify this library, you may extend
# this exception to your version of the library, but you are not
# obligated to do so.  If you do not wish to do so, delete this
# exception statement from your version."
#
# We are assuming here that building a gem with the compiled version of bidi.java falls under these terms,
# specifically that we are "link(ing) this library with independent modules to produce an executable."
# We are NOT including the original source code to avoid licensing restrictions, but it can be viewed here:
# http://developer.classpath.org/doc/java/text/Bidi-source.html


module TwitterCldr
  module Shared
    class Bidi
      attr_reader :types, :levels, :string_arr

      MAX_DEPTH = 62

      class << self
        def from_string(str, options = {})
          string_arr = str.unpack("U*")
          Bidi.new(options.merge(types: compute_types(string_arr), string_arr: string_arr))
        end

        def from_type_array(types, options = {})
          Bidi.new(options.merge(types: types))
        end

        protected

        def compute_types(arr)
          arr.map do |code_point|
            TwitterCldr::Shared::CodePoint.get(code_point).bidi_class.to_sym
          end
        end
      end

      def initialize(options = {})
        @string_arr = options[:string_arr] || options[:types]
        @types = options[:types] || []
        @levels = []
        @runs = []
        @direction = options[:direction]
        @default_direction = options[:default_direction] || :LTR
        @length = @types.size
        run_bidi
      end

      def to_s
        @string_arr.pack("U*")
      end

      def reorder_visually!
        raise "No string given!" unless @string_arr

        # Do this explicitly so we can also find the maximum depth at the
        # same time.
        max = 0
        lowest_odd = MAX_DEPTH + 1

        @levels.each do |level|
          max = [level, max].max
          lowest_odd = [lowest_odd, level].min unless level.even?
        end

        # Reverse the runs starting with the deepest.
        max.downto(lowest_odd) do |depth|
          start = 0

          while start < @levels.size
            # Find the start of a run >= DEPTH.
            start += 1 while start < @levels.size && @levels[start] < depth

            break if start == @levels.size

            # Find the end of the run.
            finish = start + 1
            finish += 1 while finish < @levels.size && @levels[finish] >= depth

            # Reverse this run.
            ((finish - start) / 2).times do |i|
              tmpb = @levels[finish - i - 1]
              @levels[finish - i - 1] = @levels[start + i]
              @levels[start + i] = tmpb

              tmpo = @string_arr[finish - i - 1]
              @string_arr[finish - i - 1] = @string_arr[start + i]
              @string_arr[start + i] = tmpo
            end

            # Handle the next run.
            start = finish + 1
          end
        end

        self
      end

      protected

      def compute_paragraph_embedding_level
        # First check to see if the user supplied a directionality override.
        if [:LTR, :RTL].include?(@direction)
          @direction == :LTR ? 0 : 1
        else
          # This implements rules P2 and P3.
          # (Note that we don't need P1, as the user supplies
          # a paragraph.)
          @types.each do |type|
            return 0 if type == :L
            return 1 if type == :R
          end

          @default_direction == :LTR ? 0 : 1
        end
      end

      def compute_explicit_levels
        current_embedding = @base_embedding

        # The directional override is a Character directionality
        # constant.  -1 means there is no override.
        directional_override = -1

        # The stack of pushed embeddings, and the stack pointer.
        # Note that because the direction is inherent in the depth,
        # and because we have a bit left over in a byte, we can encode
        # the override, if any, directly in this value on the stack.

        embedding_stack = []
        @formatter_indices ||= []
        sp = 0

        @length.times do |i|
          is_ltr = false
          is_special = true
          is_ltr = @types[i] == :LRE || @types[i] == :LRO

          case @types[i]
            when :RLE, :RLO, :LRE, :LRO
              new_embedding = if is_ltr
                # Least greater even.
                ((current_embedding & ~1) + 2)
              else
                # Least greater odd.
                ((current_embedding + 1) | 1)
              end

              # FIXME: we don't properly handle invalid pushes.
              if new_embedding < MAX_DEPTH
                # The new level is valid.  Push the old value.
                # See above for a comment on the encoding here.

                current_embedding |= -0x80 if (directional_override != -1)
                embedding_stack[sp] = current_embedding
                current_embedding = new_embedding
                sp += 1

                directional_override = if @types[i] == :LRO
                  :L
                elsif @types[i] == :RLO
                  :R
                else
                  -1
                end
              end

            when :PDF
              # FIXME: we don't properly handle a pop with a corresponding
              # invalid push.
              # If sp === 0, we saw a pop without a push.  Just ignore it.
              if sp > 0
                sp -= 1
                new_embedding = embedding_stack[sp]
                current_embedding = new_embedding & 0x7f

                directional_override = if new_embedding < 0
                  (new_embedding & 1) == 0 ? :L : :R
                else
                  -1
                end
              end

            else
              is_special = false
          end

          @levels[i] = current_embedding

          if is_special
            # Mark this character for removal.
            @formatter_indices << i
          elsif directional_override != -1
            @types[i] = directional_override
          end
        end

        # Remove the formatting codes and update both the arrays
        # and 'length'.  It would be more efficient not to remove
        # these codes, but it is also more complicated.  Also, the
        # Unicode algorithm reference does not properly describe
        # how this is to be done -- from what I can tell, their suggestions
        # in this area will not yield the correct results.

        output = 0
        input = 0
        size = @formatter_indices.size

        0.upto(size).each do |i|
          if i == size
            next_fmt = @length
          else
            next_fmt = @formatter_indices[i]
          end

          len = next_fmt - input

          # Non-formatter codes are from 'input' to 'next_fmt'.
          arraycopy(@levels, input, @levels, output, len)
          arraycopy(@types, input, @types, output, len)

          output += len
          input = next_fmt + 1
        end

        @length -= @formatter_indices.size
      end

      def compute_runs
        run_count = 0
        current_embedding = @base_embedding

        @length.times do |i|
          if @levels[i] != current_embedding
            current_embedding = @levels[i]
            run_count += 1
          end
        end

        # This may be called multiple times.  If so, and if
        # the number of runs has not changed, then don't bother
        # allocating a new array.
        where = 0
        last_run_start = 0
        current_embedding = @base_embedding

        @length.times do |i|
          if @levels[i] != current_embedding
            @runs[where] = last_run_start
            where += 1
            last_run_start = i
            current_embedding = @levels[i]
          end
        end

        @runs[where] = last_run_start
      end

      def resolve_weak_types
        run_count = @runs.size
        previous_level = @base_embedding

        run_count.times do |run_idx|
          start = get_run_start(run_idx)
          finish = get_run_limit(run_idx)
          level = get_run_level(run_idx) || 0

          # These are the names used in the Bidi algorithm.
          sor = [previous_level, level].max.even? ? :L : :R

          next_level = if run_idx == (run_count - 1)
            @base_embedding
          else
            get_run_level(run_idx + 1) || 0
          end

          eor = [level, next_level].max.even? ? :L : :R
          prev_type = sor
          prev_strong_type = sor

          start.upto(finish - 1) do |i|
            next_type = (i == finish - 1) ? eor : @types[i + 1]

            # Rule W1: change NSM to the prevailing direction.
            if @types[i] == :NSM
              @types[i] = prev_type
            else
              prev_type = @types[i]
            end

            # Rule W2: change EN to AN in some cases.
            if @types[i] == :EN
              if prev_strong_type == :AL
                @types[i] = :AN
              end
            elsif @types[i] == :L || @types[i] == :R || @types[i] == :AL
              prev_strong_type = @types[i]
            end

            # Rule W3: change AL to R.
            if @types[i] == :AL
              @types[i] = :R
            end

            # Rule W4: handle separators between two numbers.
            if prev_type == :EN && next_type == :EN
              if @types[i] == :ES || @types[i] == :CS
                @types[i] = nextType
              end
            elsif prev_type == :AN && next_type == :AN && @types[i] == :CS
              @types[i] = next_type
            end

            # Rule W5: change a sequence of european terminators to
            # european numbers, if they are adjacent to european numbers.
            # We also include BN characters in this.
            if @types[i] == :ET || @types[i] == :BN
              if prev_type == :EN
                @types[i] = prev_type
              else
                # Look ahead to see if there is an EN terminating this
                # sequence of ETs.
                j = i + 1

                while j < finish && @types[j] == :ET || @types[j] == :BN
                  j += 1
                end

                if j < finish && @types[j] == :EN
                  # Change them all to EN now.
                  i.upto(j - 1) do |k|
                    @types[k] = :EN
                  end
                end
              end
            end

            # Rule W6: separators and terminators change to ON.
            # Again we include BN.
            if @types[i] == :ET || @types[i] == :CS || @types[i] == :BN
              @types[i] = :ON
            end

            # Rule W7: change european number types.
            if prev_strong_type == :L && @types[i] == :EN
              @types[i] = prev_strong_type
            end
          end

          previous_level = level
        end
      end

      def get_run_count
        @runs.size
      end

      def get_run_level(which)
        @levels[@runs[which]]
      end

      def get_run_limit(which)
        if which == (@runs.length - 1)
          @length
        else
          @runs[which + 1]
        end
      end

      def get_run_start(which)
        @runs[which]
      end

      def resolve_implicit_levels
        # This implements rules I1 and I2.
        @length.times do |i|
          if (@levels[i] & 1) == 0
            if @types[i] == :R
              @levels[i] += 1
            elsif @types[i] == :AN || @types[i] == :EN
              @levels[i] += 2
            end
          else
            if @types[i] == :L || @types[i] == :AN || @types[i] == :EN
              @levels[i] += 1
            end
          end
        end
      end

      def resolve_neutral_types
        # This implements rules N1 and N2.
        run_count = get_run_count
        previous_level = @base_embedding

        run_count.times do |run|
          start = get_run_start(run)
          finish = get_run_limit(run)
          level = get_run_level(run)
          next unless level

          embedding_direction = level.even? ? :L : :R
          # These are the names used in the Bidi algorithm.
          sor = [previous_level, level].max.even? ? :L : :R

          next_level = if run == (run_count - 1)
            @base_embedding
          else
            get_run_level(run + 1)
          end

          eor = [level, next_level].max.even? ? :L : :R
          prev_strong = sor
          neutral_start = -1

          start.upto(finish) do |i|
            new_strong = -1
            this_type = i == finish ? eor : @types[i]

            case this_type
              when :L
                new_strong = :L
              when :R, :AN, :EN
                new_strong = :R
              when :BN, :ON, :S, :B, :WS
                neutral_start = i if neutral_start == -1
            end

            # If we see a strong character, update all the neutrals.
            if new_strong != -1
              if neutral_start != -1
                override = prev_strong == new_strong ? prev_strong : embedding_direction
                neutral_start.upto(i - 1) { |j| @types[j] = override }
              end

              prev_strong = new_strong
              neutral_start = -1
            end
          end

          previous_level = level
        end
      end

      def reinsert_formatting_codes
        if @formatter_indices
          input = @length
          output = @levels.size

          # Process from the end as we are copying the array over itself here.
          (@formatter_indices.size - 1).downto(0) do |index|
            next_fmt = @formatter_indices[index]

            # nextFmt points to a location in the original array.  So,
            # nextFmt+1 is the target of our copying.  output is the location
            # to which we last copied, thus we can derive the length of the
            # copy from it.
            len = output - next_fmt - 1
            output = next_fmt
            input -= len

            # Note that we no longer need 'types' at this point, so we
            # only edit 'levels'.
            if next_fmt + 1 < @levels.size
              arraycopy(@levels, input, @levels, next_fmt + 1, len)
            end

            # Now set the level at the reinsertion point.
            right_level = if output == @levels.length - 1
              @base_embedding
            else
              @levels[output + 1] || 0
            end

            left_level = if input == 0
              @base_embedding
            else
              @levels[input] || 0;
            end

            @levels[output] = [left_level, right_level].max
          end
        end

        @length = @levels.size
      end

      def arraycopy(orig, orig_index, dest, dest_index, length)
        orig[orig_index...(orig_index + length)].each_with_index do |elem, count|
          dest[dest_index + count] = elem
        end
      end

      def run_bidi
        @base_embedding = compute_paragraph_embedding_level

        compute_explicit_levels
        compute_runs
        resolve_weak_types
        resolve_neutral_types
        resolve_implicit_levels
        reinsert_formatting_codes

        # After resolving the implicit levels, the number
        # of runs may have changed.
        compute_runs
      end
    end
  end
end
