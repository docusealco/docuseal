# frozen_string_literal: true

require "set" unless defined?(::Set)

module Net
  class IMAP

    ##
    # An \IMAP sequence set is a set of message sequence numbers or unique
    # identifier numbers ("UIDs").  It contains numbers and ranges of numbers.
    # The numbers are all non-zero unsigned 32-bit integers and one special
    # value (<tt>"*"</tt>) that represents the largest value in the mailbox.
    #
    # Certain types of \IMAP responses will contain a SequenceSet, for example
    # the data for a <tt>"MODIFIED"</tt> ResponseCode.  Some \IMAP commands may
    # receive a SequenceSet as an argument, for example IMAP#search, IMAP#fetch,
    # and IMAP#store.
    #
    # == Creating sequence sets
    #
    # SequenceSet.new may receive a single optional argument: a non-zero 32 bit
    # unsigned integer, a range, a <tt>sequence-set</tt> formatted string,
    # another SequenceSet, a Set (containing only numbers or <tt>*</tt>), or an
    # Array containing any of these (array inputs may be nested).
    #
    #     set = Net::IMAP::SequenceSet.new(1)
    #     set.valid_string  #=> "1"
    #     set = Net::IMAP::SequenceSet.new(1..100)
    #     set.valid_string  #=> "1:100"
    #     set = Net::IMAP::SequenceSet.new(1...100)
    #     set.valid_string  #=> "1:99"
    #     set = Net::IMAP::SequenceSet.new([1, 2, 5..])
    #     set.valid_string  #=> "1:2,5:*"
    #     set = Net::IMAP::SequenceSet.new("1,2,3:7,5,6:10,2048,1024")
    #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     set = Net::IMAP::SequenceSet.new(1, 2, 3..7, 5, 6..10, 2048, 1024)
    #     set.valid_string  #=> "1:10,55,1024:2048"
    #
    # SequenceSet.new with no arguments creates an empty sequence set.  Note
    # that an empty sequence set is invalid in the \IMAP grammar.
    #
    #     set = Net::IMAP::SequenceSet.new
    #     set.empty?        #=> true
    #     set.valid?        #=> false
    #     set.valid_string  #!> raises DataFormatError
    #     set << 1..10
    #     set.empty?        #=> false
    #     set.valid?        #=> true
    #     set.valid_string  #=> "1:10"
    #
    # Using SequenceSet.new with another SequenceSet input behaves the same as
    # calling #dup on the other set.  The input's #string will be preserved.
    #
    #     input = Net::IMAP::SequenceSet.new("1,2,3:7,5,6:10,2048,1024")
    #     copy  = Net::IMAP::SequenceSet.new(input)
    #     input.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     copy.valid_string   #=> "1,2,3:7,5,6:10,2048,1024"
    #     copy2 = input.dup   # same as calling new with a SequenceSet input
    #     copy ==     input   #=> true,  same set membership
    #     copy.eql?   input   #=> true,  same string value
    #     copy.equal? input   #=> false, different objects
    #
    #     copy.normalize!
    #     copy.valid_string   #=> "1:10,1024,2048"
    #     copy ==   input     #=> true,  same set membership
    #     copy.eql? input     #=> false, different string value
    #
    #     copy << 999
    #     copy.valid_string   #=> "1:10,999,1024,2048"
    #     copy ==   input     #=> false, different set membership
    #     copy.eql? input     #=> false, different string value
    #
    # Use Net::IMAP::SequenceSet() to coerce a single (optional) input.
    # A SequenceSet input is returned without duplication, even when frozen.
    #
    #     set = Net::IMAP::SequenceSet()
    #     set.string   #=> nil
    #     set.frozen?  #=> false
    #
    #     # String order is preserved
    #     set = Net::IMAP::SequenceSet("1,2,3:7,5,6:10,2048,1024")
    #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     set.frozen?       #=> false
    #
    #     # Other inputs are normalized
    #     set = Net::IMAP::SequenceSet([1, 2, [3..7, 5], 6..10, 2048, 1024])
    #     set.valid_string  #=> "1:10,1024,2048"
    #     set.frozen?       #=> false
    #
    #     unfrozen = set
    #     frozen   = set.dup.freeze
    #     unfrozen.equal? Net::IMAP::SequenceSet(unfrozen)  #=> true
    #     frozen.equal?   Net::IMAP::SequenceSet(frozen)    #=> true
    #
    # Use ::[] to coerce one or more arguments into a valid frozen SequenceSet.
    # A valid frozen SequenceSet is returned directly, without allocating a new
    # object.  ::[] will not create an invalid (empty) set.
    #
    #     Net::IMAP::SequenceSet[]     #!> raises ArgumentError
    #     Net::IMAP::SequenceSet[nil]  #!> raises DataFormatError
    #     Net::IMAP::SequenceSet[""]   #!> raises DataFormatError
    #
    #     # String order is preserved
    #     set = Net::IMAP::SequenceSet["1,2,3:7,5,6:10,2048,1024"]
    #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
    #     set.frozen?       #=> true
    #
    #     # Other inputs are normalized
    #     set = Net::IMAP::SequenceSet[1, 2, [3..7, 5], 6..10, 2048, 1024]
    #     set.valid_string  #=> "1:10,1024,2048"
    #     set.frozen?       #=> true
    #
    #     frozen   = set
    #     unfrozen = set.dup
    #     frozen.equal?   Net::IMAP::SequenceSet[frozen]    #=> true
    #     unfrozen.equal? Net::IMAP::SequenceSet[unfrozen]  #=> false
    #
    # Objects which respond to +to_sequence_set+ (such as SearchResult and
    # ThreadMember) can be coerced to a SequenceSet with ::new, ::try_convert,
    # ::[], or Net::IMAP::SequenceSet.
    #
    #     search = imap.uid_search(["SUBJECT", "hello", "NOT", "SEEN"])
    #     seqset = Net::IMAP::SequenceSet(search) - already_fetched
    #     fetch  = imap.uid_fetch(seqset, "FAST")
    #
    # == Ordered and Normalized sets
    #
    # Sometimes the order of the set's members is significant, such as with the
    # +ESORT+, <tt>CONTEXT=SORT</tt>, and +UIDPLUS+ extensions.  So, when a
    # sequence set is created from a single string (such as by the parser), that
    # #string representation is preserved.  Assigning a string with #string= or
    # #replace will also preserve that string.  Use #each_entry, #entries, or
    # #each_ordered_number to enumerate the entries in their #string order.
    # Hash equality (using #eql?) is based on the string representation.
    #
    # Internally, SequenceSet uses a normalized uint32 set representation which
    # sorts and de-duplicates all numbers and coalesces adjacent or overlapping
    # entries.  Many methods use this sorted set representation for <tt>O(lg
    # n)</tt> searches.  Use #each_element, #elements, #each_range, #ranges,
    # #each_number, or #numbers to enumerate the set in sorted order.  Basic
    # object equality (using #==) is based on set membership, without regard to
    # #entry order or #string normalization.
    #
    # Most modification methods reset #string to its #normalized form, so that
    # #entries and #elements are identical.  Use #append to preserve #entries
    # order while modifying a set.
    #
    # Non-normalized sets store both representations of the set, which can more
    # than double memory usage.  Very large sequence sets should avoid
    # denormalizing methods (such as #append) unless order is significant.
    #
    # == Using <tt>*</tt>
    #
    # \IMAP sequence sets may contain a special value <tt>"*"</tt>, which
    # represents the largest number in use.  From +seq-number+ in
    # {RFC9051 §9}[https://www.rfc-editor.org/rfc/rfc9051.html#section-9-5]:
    # >>>
    #   In the case of message sequence numbers, it is the number of messages
    #   in a non-empty mailbox.  In the case of unique identifiers, it is the
    #   unique identifier of the last message in the mailbox or, if the
    #   mailbox is empty, the mailbox's current UIDNEXT value.
    #
    # When creating a SequenceSet, <tt>*</tt> may be input as <tt>-1</tt>,
    # <tt>"*"</tt>, <tt>:*</tt>, an endless range, or a range ending in
    # <tt>-1</tt>.  When converting to #elements, #ranges, or #numbers, it will
    # output as either <tt>:*</tt> or an endless range.  For example:
    #
    #   Net::IMAP::SequenceSet["1,3,*"].to_a      #=> [1, 3, :*]
    #   Net::IMAP::SequenceSet["1,234:*"].to_a    #=> [1, 234..]
    #   Net::IMAP::SequenceSet[1234..-1].to_a     #=> [1234..]
    #   Net::IMAP::SequenceSet[1234..].to_a       #=> [1234..]
    #
    #   Net::IMAP::SequenceSet[1234..].to_s       #=> "1234:*"
    #   Net::IMAP::SequenceSet[1234..-1].to_s     #=> "1234:*"
    #
    # Use #limit to convert <tt>"*"</tt> to a maximum value.  When a range
    # includes <tt>"*"</tt>, the maximum value will always be matched:
    #
    #   Net::IMAP::SequenceSet["9999:*"].limit(max: 25)
    #   #=> Net::IMAP::SequenceSet["25"]
    #
    # === Surprising <tt>*</tt> behavior
    #
    # When a set includes <tt>*</tt>, some methods may have surprising behavior.
    #
    # For example, #complement treats <tt>*</tt> as its own member.  This way,
    # the #intersection of a set and its #complement will always be empty.  And
    # <tt>*</tt> is sorted as greater than any other number in the set.  This is
    # not how an \IMAP server interprets the set: it will convert <tt>*</tt> to
    # the number of messages in the mailbox, the +UID+ of the last message in
    # the mailbox, or +UIDNEXT+, as appropriate.  Several methods have an
    # argument for how <tt>*</tt> should be interpreted.
    #
    # But, for example, this means that there may be overlap between a set and
    # its complement after #limit is applied to each:
    #
    #   ~Net::IMAP::SequenceSet["*"]  == Net::IMAP::SequenceSet[1..(2**32-1)]
    #   ~Net::IMAP::SequenceSet[1..5] == Net::IMAP::SequenceSet["6:*"]
    #
    #   set = Net::IMAP::SequenceSet[1..5]
    #   (set & ~set).empty? => true
    #
    #   (set.limit(max: 4) & (~set).limit(max: 4)).to_a => [4]
    #
    # When counting the number of numbers in a set, <tt>*</tt> will be counted
    # as if it were equal to UINT32_MAX:
    #   UINT32_MAX = 2**32 - 1
    #   Net::IMAP::SequenceSet["*"].count                   => 1
    #   Net::IMAP::SequenceSet[1..UINT32_MAX - 1, :*].count => UINT32_MAX
    #
    #   Net::IMAP::SequenceSet["1:*"].count                 => UINT32_MAX
    #   Net::IMAP::SequenceSet[UINT32_MAX, :*].count        => 1
    #   Net::IMAP::SequenceSet[UINT32_MAX..].count          => 1
    #
    # Use #cardinality to count the set members wxth <tt>*</tt> counted as a
    # distinct member:
    #   Net::IMAP::SequenceSet[1..].cardinality            #=> UINT32_MAX + 1
    #   Net::IMAP::SequenceSet[UINT32_MAX, :*].cardinality #=> 2
    #   Net::IMAP::SequenceSet[UINT32_MAX..].cardinality   #=> 2
    #
    # == What's here?
    #
    # SequenceSet provides methods for:
    # * {Creating a SequenceSet}[rdoc-ref:SequenceSet@Methods+for+Creating+a+SequenceSet]
    # * {Comparing}[rdoc-ref:SequenceSet@Methods+for+Comparing]
    # * {Querying}[rdoc-ref:SequenceSet@Methods+for+Querying]
    # * {Iterating}[rdoc-ref:SequenceSet@Methods+for+Iterating]
    # * {Set Operations}[rdoc-ref:SequenceSet@Methods+for+Set+Operations]
    # * {Assigning}[rdoc-ref:SequenceSet@Methods+for+Assigning]
    # * {Deleting}[rdoc-ref:SequenceSet@Methods+for+Deleting]
    # * {IMAP String Formatting}[rdoc-ref:SequenceSet@Methods+for+IMAP+String+Formatting]
    #
    # === Methods for Creating a \SequenceSet
    # * ::[]: Creates a validated frozen sequence set from one or more inputs.
    # * ::new: Creates a new mutable sequence set, which may be empty (invalid).
    # * ::try_convert: Calls +to_sequence_set+ on an object and verifies that
    #   the result is a SequenceSet.
    # * Net::IMAP::SequenceSet(): Coerce an input using ::try_convert or ::new.
    # * ::empty: Returns a frozen empty (invalid) SequenceSet.
    # * ::full: Returns a frozen SequenceSet containing every possible number.
    #
    # === Methods for Comparing
    #
    # <i>Comparison to another \SequenceSet:</i>
    # - #==: Returns whether a given set contains the same numbers as +self+.
    # - #eql?: Returns whether a given set uses the same #string as +self+.
    #
    # <i>Comparison to objects which are convertible to \SequenceSet:</i>
    # - #===:
    #   Returns whether a given object is fully contained within +self+, or
    #   +nil+ if the object cannot be converted to a compatible type.
    # - #cover?:
    #   Returns whether a given object is fully contained within +self+.
    # - #intersect? (aliased as #overlap?):
    #   Returns whether +self+ and a given object have any common elements.
    # - #disjoint?:
    #   Returns whether +self+ and a given object have no common elements.
    #
    # === Methods for Querying
    # These methods do not modify +self+.
    #
    # <i>Set membership:</i>
    # - #include? (aliased as #member?):
    #   Returns whether a given element is contained by the set.
    # - #include_star?: Returns whether the set contains <tt>*</tt>.
    #
    # <i>Minimum and maximum value elements:</i>
    # - #min: Returns one or more of the lowest numbers in the set.
    # - #max: Returns one or more of the highest numbers in the set.
    # - #minmax: Returns the lowest and highest numbers in the set.
    #
    # <i>Accessing value by offset in sorted set:</i>
    # - #[] (aliased as #slice): Returns the number or consecutive subset at a
    #   given offset or range of offsets in the sorted set.
    # - #at: Returns the number at a given offset in the sorted set.
    # - #find_index: Returns the given number's offset in the sorted set.
    #
    # <i>Accessing value by offset in ordered entries</i>
    # - #ordered_at: Returns the number at a given offset in the ordered entries.
    # - #find_ordered_index: Returns the index of the given number's first
    #   occurrence in entries.
    #
    # <i>Set cardinality:</i>
    # - #cardinality: Returns the number of distinct members in the set.
    #   <tt>*</tt> is counted as its own member, distinct from UINT32_MAX.
    # - #count: Returns the count of distinct numbers in the set.
    #   <tt>*</tt> is counted as equal to UINT32_MAX.
    # - #empty?: Returns whether the set has no members.  \IMAP syntax does not
    #   allow empty sequence sets.
    # - #valid?: Returns whether the set has any members.
    # - #full?: Returns whether the set contains every possible value, including
    #   <tt>*</tt>.
    #
    # <i>Denormalized properties:</i>
    # - #normalized?: Returns whether #entries are sorted, deduplicated, and
    #   coalesced, and all #string entries are in normalized form.
    # - #has_duplicates?: Returns whether the ordered entries repeat any
    #   numbers.
    # - #size: Returns the total size of all #entries, including repeated
    #   numbers.  <tt>*</tt> is counted as its own member, distinct from
    #   UINT32_MAX.
    # - #count_with_duplicates: Returns the count of numbers in the ordered
    #   #entries, including repeated numbers.  <tt>*</tt> is counted as
    #   equal to UINT32_MAX.
    # - #count_duplicates: Returns the count of repeated numbers in the ordered
    #   #entries.  <tt>*</tt> is counted as equal to UINT32_MAX.
    #
    # === Methods for Iterating
    #
    # <i>Normalized (sorted and coalesced):</i>
    # - #each_element: Yields each number and range in the set, sorted and
    #   coalesced, and returns +self+.
    # - #elements (aliased as #to_a): Returns an Array of every number and range
    #   in the set, sorted and coalesced.
    # - #each_range:
    #   Yields each element in the set as a Range and returns +self+.
    # - #ranges: Returns an Array of every element in the set, converting
    #   numbers into ranges of a single value.
    # - #each_number: Yields each number in the set and returns +self+.
    # - #numbers: Returns an Array with every number in the set, expanding
    #   ranges into all of their contained numbers.
    # - #to_set: Returns a Set containing all of the #numbers in the set.
    #
    # <i>Order preserving:</i>
    # - #each_entry: Yields each number and range in the set, unsorted and
    #   without deduplicating numbers or coalescing ranges, and returns +self+.
    # - #entries: Returns an Array of every number and range in the set,
    #   unsorted and without deduplicating numbers or coalescing ranges.
    # - #each_ordered_number: Yields each number in the ordered entries and
    #   returns +self+.
    #
    # === Methods for \Set Operations
    # These methods do not modify +self+.
    #
    # - #| (aliased as #union and #+): Returns a new set combining all members
    #   from +self+ with all members from the other set.
    # - #& (aliased as #intersection): Returns a new set containing all members
    #   common to +self+ and the other set.
    # - #- (aliased as #difference): Returns a copy of +self+ with all members
    #   in the other set removed.
    # - #^ (aliased as #xor): Returns a new set containing all members from
    #   +self+ and the other set except those common to both.
    # - #~ (aliased as #complement): Returns a new set containing all members
    #   that are not in +self+
    # - #above: Return a copy of +self+ which only contains numbers above a
    #   given number.
    # - #below: Return a copy of +self+ which only contains numbers below a
    #   given value.
    # - #limit: Returns a copy of +self+ which has replaced <tt>*</tt> with a
    #   given maximum value and removed all members over that maximum.
    #
    # === Methods for Assigning
    # These methods add or replace numbers in +self+.
    #
    # <i>Normalized (sorted and coalesced):</i>
    #
    # These methods always update #string to be fully sorted and coalesced.
    #
    # - #add (aliased as #<<): Adds a given element to the set; returns +self+.
    # - #add?: If the given element is not fully included the set, adds it and
    #   returns +self+; otherwise, returns +nil+.
    # - #merge: In-place set #union.  Adds all members of the given sets into
    #   this set; returns +self+.
    # - #complement!: In-place set #complement.  Replaces the contents of this
    #   set with its own #complement; returns +self+.
    # - #xor!: In-place +XOR+ operation.  Adds numbers that are unique to the
    #   other set and removes numbers that are common to both; returns +self+.
    #
    # <i>Order preserving:</i>
    #
    # These methods _may_ cause #string to not be sorted or coalesced.
    #
    # - #append: Adds the given entry to the set, appending it to the existing
    #   string, and returns +self+.
    # - #string=: Assigns a new #string value and replaces #elements to match.
    # - #replace: Replaces the contents of the set with the contents
    #   of a given object.
    #
    # === Methods for Deleting
    # These methods remove numbers from +self+, and update #string to be fully
    # sorted and coalesced.
    #
    # - #clear: Removes all elements in the set; returns +self+.
    # - #delete: Removes a given element from the set; returns +self+.
    # - #delete?: If the given element is included in the set, removes it and
    #   returns it; otherwise, returns +nil+.
    # - #delete_at: Removes the number at a given offset.
    # - #intersect!: In-place set #intersection.  Removes numbers that are not
    #   in the given set; returns +self+.
    # - #slice!: Removes the number or consecutive numbers at a given offset or
    #   range of offsets.
    # - #subtract: In-place set #difference.  Removes all members of the given
    #   sets from this set; returns +self+.
    # - #limit!: Replaces <tt>*</tt> with a given maximum value and removes all
    #   members over that maximum; returns +self+.
    #
    # === Methods for \IMAP String Formatting
    #
    # - #to_s: Returns the +sequence-set+ string, or an empty string when the
    #   set is empty.
    # - #string: Returns the +sequence-set+ string, or nil when empty.
    # - #valid_string: Returns the +sequence-set+ string, or raises
    #   DataFormatError when the set is empty.
    # - #normalized_string: Returns a <tt>sequence-set</tt> string with its
    #   elements sorted and coalesced, or nil when the set is empty.
    # - #normalize: Returns a new set with this set's normalized +sequence-set+
    #   representation.
    # - #normalize!: Updates #string to its normalized +sequence-set+
    #   representation and returns +self+.
    #
    class SequenceSet
      # The largest possible non-zero unsigned 32-bit integer
      UINT32_MAX = 2**32 - 1

      # represents "*" internally, to simplify sorting (etc)
      STAR_INT  = UINT32_MAX + 1
      private_constant :STAR_INT

      # valid inputs for "*"
      STARS     = [:*, ?*, -1].freeze
      private_constant :STARS

      INSPECT_MAX_LEN      = 512
      INSPECT_TRUNCATE_LEN =  16
      private_constant :INSPECT_MAX_LEN, :INSPECT_TRUNCATE_LEN

      # /(,\d+){100}\z/ is shockingly slow on huge strings.
      # /(,\d{0,10}){100}\z/ is ok, but ironically, Regexp.linear_time? is false.
      #
      # This unrolls all nested quantifiers.  It's much harder to read, but it's
      # also the fastest out of all the versions I tested.
      nz_uint32   = /[1-9](?:\d(?:\d(?:\d(?:\d(?:\d(?:\d(?:\d(?:\d(?:\d)?)?)?)?)?)?)?)?)?/
      num_or_star = /#{nz_uint32}|\*/
      entry       = /#{num_or_star}(?::#{num_or_star})?/
      entries     = ([entry] * INSPECT_TRUNCATE_LEN).join(",")
      INSPECT_ABRIDGED_HEAD_RE = /\A#{entries},/
      INSPECT_ABRIDGED_TAIL_RE = /,#{entries}\z/
      private_constant :INSPECT_ABRIDGED_HEAD_RE, :INSPECT_ABRIDGED_TAIL_RE

      class << self

        # :call-seq:
        #   SequenceSet[*inputs] -> valid frozen sequence set
        #
        # Returns a frozen SequenceSet, constructed from +inputs+.
        #
        # When only a single valid frozen SequenceSet is given, that same set is
        # returned.
        #
        # An empty SequenceSet is invalid and will raise a DataFormatError.
        #
        # Use ::new to create a mutable or empty SequenceSet.
        #
        # Related: ::new, Net::IMAP::SequenceSet(), ::try_convert
        def [](first, *rest)
          if rest.empty?
            set = try_convert(first)&.validate
            set&.frozen? ? set : (set&.dup || new(first).validate).freeze
          else
            new(first).merge(*rest).validate.freeze
          end
        end

        # :call-seq:
        #   SequenceSet.try_convert(obj) -> sequence set or nil
        #
        # If +obj+ is a SequenceSet, returns +obj+.  If +obj+ responds_to
        # +to_sequence_set+, calls +obj.to_sequence_set+ and returns the result.
        # Otherwise returns +nil+.
        #
        # If +obj.to_sequence_set+ doesn't return a SequenceSet or +nil+, an
        # exception is raised.
        #
        # Related: Net::IMAP::SequenceSet(), ::new, ::[]
        def try_convert(obj)
          return obj if obj.is_a?(SequenceSet)
          return nil unless obj.respond_to?(:to_sequence_set)
          return nil unless obj = obj.to_sequence_set
          return obj if obj.is_a?(SequenceSet)
          raise DataFormatError, "invalid object returned from to_sequence_set"
        end

        # Returns a frozen empty set singleton.  Note that valid \IMAP sequence
        # sets cannot be empty, so this set is _invalid_.
        def empty; EMPTY end

        # Returns a frozen full set singleton: <tt>"1:*"</tt>
        def full;  FULL end

      end

      # Create a new SequenceSet object from +input+, which may be another
      # SequenceSet, an IMAP formatted +sequence-set+ string, a non-zero 32 bit
      # unsigned integer, a range, <tt>:*</tt>, a Set of numbers or <tt>*</tt>,
      # an object that responds to +to_sequence_set+ (such as SearchResult) or
      # an Array of these (array inputs may be nested).
      #
      #     set = Net::IMAP::SequenceSet.new(1)
      #     set.valid_string  #=> "1"
      #     set = Net::IMAP::SequenceSet.new(1..100)
      #     set.valid_string  #=> "1:100"
      #     set = Net::IMAP::SequenceSet.new(1...100)
      #     set.valid_string  #=> "1:99"
      #     set = Net::IMAP::SequenceSet.new([1, 2, 5..])
      #     set.valid_string  #=> "1:2,5:*"
      #     set = Net::IMAP::SequenceSet.new("1,2,3:7,5,6:10,2048,1024")
      #     set.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
      #     set = Net::IMAP::SequenceSet.new(1, 2, 3..7, 5, 6..10, 2048, 1024)
      #     set.valid_string  #=> "1:10,1024,2048"
      #
      # With no arguments (or +nil+) creates an empty sequence set.  Note that
      # an empty sequence set is invalid in the \IMAP grammar.
      #
      #     set = Net::IMAP::SequenceSet.new
      #     set.empty?        #=> true
      #     set.valid?        #=> false
      #     set.valid_string  #!> raises DataFormatError
      #     set << 1..10
      #     set.empty?        #=> false
      #     set.valid?        #=> true
      #     set.valid_string  #=> "1:10"
      #
      # When +input+ is a SequenceSet, ::new behaves the same as calling #dup on
      # that other set.  The input's #string will be preserved.
      #
      #     input = Net::IMAP::SequenceSet.new("1,2,3:7,5,6:10,2048,1024")
      #     copy  = Net::IMAP::SequenceSet.new(input)
      #     input.valid_string  #=> "1,2,3:7,5,6:10,2048,1024"
      #     copy.valid_string   #=> "1,2,3:7,5,6:10,2048,1024"
      #     copy2 = input.dup   # same as calling new with a SequenceSet input
      #     copy ==     input   #=> true,  same set membership
      #     copy.eql?   input   #=> true,  same string value
      #     copy.equal? input   #=> false, different objects
      #
      #     copy.normalize!
      #     copy.valid_string   #=> "1:10,1024,2048"
      #     copy ==   input     #=> true,  same set membership
      #     copy.eql? input     #=> false, different string value
      #
      #     copy << 999
      #     copy.valid_string   #=> "1:10,999,1024,2048"
      #     copy ==   input     #=> false, different set membership
      #     copy.eql? input     #=> false, different string value
      #
      # === Alternative set creation methods
      #
      # * ::[] returns a frozen validated (non-empty) SequenceSet, without
      #   allocating a new object when the input is already a valid frozen
      #   SequenceSet.
      # * Net::IMAP::SequenceSet() coerces an input to SequenceSet, without
      #   allocating a new object when the input is already a SequenceSet.
      # * ::try_convert calls +to_sequence_set+ on inputs that support it and
      #   returns +nil+ for inputs that don't.
      # * ::empty and ::full both return frozen singleton sets which can be
      #   combined with set operations (#|, #&, #^, #-, etc) to make new sets.
      #
      # See SequenceSet@Creating+sequence+sets.
      def initialize(input = nil)
        @set_data = new_set_data
        @string = nil
        replace(input) unless input.nil?
      end

      # Removes all elements and returns self.
      def clear
        modifying! # redundant check (normalizes the error message for JRuby)
        set_data.clear
        @string = nil
        self
      end

      # Replace the contents of the set with the contents of +other+ and returns
      # +self+.
      #
      # +other+ may be another SequenceSet or any other object that would be
      # accepted by ::new.
      def replace(other)
        case other
        when SequenceSet then
          modifying! # short circuit before doing any work
          @set_data = other.dup_set_data
          @string = other.instance_variable_get(:@string)
        when String      then self.string = other
        else                  clear; merge other
        end
        self
      end

      # Returns the \IMAP +sequence-set+ string representation, or raises a
      # DataFormatError when the set is empty.
      #
      # Use #string to return +nil+ or #to_s to return an empty string without
      # error.
      #
      # Related: #string, #normalized_string, #to_s
      def valid_string
        raise DataFormatError, "empty sequence-set" if empty?
        string
      end

      # Returns the \IMAP +sequence-set+ string representation, or +nil+ when
      # the set is empty.  Note that an empty set is invalid in the \IMAP
      # syntax.
      #
      # Use #valid_string to raise an exception when the set is empty, or #to_s
      # to return an empty string.
      #
      # If the set was created from a single string, it is not normalized.  If
      # the set is updated the string will be normalized.
      #
      # Related: #valid_string, #normalized_string, #to_s, #inspect
      def string; @string || normalized_string if valid? end

      # Returns an array with #normalized_string when valid and an empty array
      # otherwise.
      def deconstruct; valid? ? [normalized_string] : [] end

      # Assigns a new string to #string and resets #elements to match.
      # Assigning +nil+ or an empty string are equivalent to calling #clear.
      #
      # Non-empty strings are validated but not normalized.
      #
      # Use #add, #merge, or #append to add a string to an existing set.
      #
      # Related: #replace, #clear
      def string=(input)
        if input.nil?
          clear
        elsif (str = String.try_convert(input))
          modifying! # short-circuit before parsing the string
          entries = each_parsed_entry(str).to_a
          clear
          if normalized_entries?(entries)
            replace_minmaxes entries.map!(&:minmax)
          else
            add_minmaxes entries.map!(&:minmax)
            @string = -str
          end
        else
          raise ArgumentError, "expected a string or nil, got #{input.class}"
        end
        input
      end

      # Returns the \IMAP +sequence-set+ string representation, or an empty
      # string when the set is empty.  Note that an empty set is invalid in the
      # \IMAP syntax.
      #
      # Related: #string, #valid_string, #normalized_string, #inspect
      def to_s; string || "" end

      # Freezes and returns the set.  A frozen SequenceSet is Ractor-safe.
      def freeze
        return self if frozen?
        freeze_set_data
        super
      end

      # :call-seq: self == other -> true or false
      #
      # Returns true when the other SequenceSet represents the same message
      # identifiers.  Encoding difference—such as order, overlaps, or
      # duplicates—are ignored.
      #
      #   Net::IMAP::SequenceSet["1:3"]   == Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,2,3"] == Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,3"]   == Net::IMAP::SequenceSet["3,1"]
      #   #=> true
      #   Net::IMAP::SequenceSet["9,1:*"] == Net::IMAP::SequenceSet["1:*"]
      #   #=> true
      #
      # Related: #eql?, #normalize
      def ==(other)
        self.class == other.class &&
          (to_s == other.to_s || set_data == other.set_data)
      end

      # :call-seq: eql?(other) -> true or false
      #
      # Hash equality requires the same encoded #string representation.
      #
      #   Net::IMAP::SequenceSet["1:3"]  .eql? Net::IMAP::SequenceSet["1:3"]
      #   #=> true
      #   Net::IMAP::SequenceSet["1,2,3"].eql? Net::IMAP::SequenceSet["1:3"]
      #   #=> false
      #   Net::IMAP::SequenceSet["1,3"]  .eql? Net::IMAP::SequenceSet["3,1"]
      #   #=> false
      #   Net::IMAP::SequenceSet["9,1:*"].eql? Net::IMAP::SequenceSet["1:*"]
      #   #=> false
      #
      # Related: #==, #normalize
      def eql?(other) self.class == other.class && string == other.string end

      # See #eql?
      def hash; [self.class, string].hash end

      # :call-seq: self === other -> true | false | nil
      #
      # Returns whether +other+ is contained within the set.  +other+ may be any
      # object that would be accepted by ::new.  Returns +nil+ if StandardError
      # is raised while converting +other+ to a comparable type.
      #
      # Related: #cover?, #include?, #include_star?
      def ===(other)
        cover?(other)
      rescue
        nil
      end

      # :call-seq: cover?(other) -> true | false | nil
      #
      # Returns whether +other+ is contained within the set.  +other+ may be any
      # object that would be accepted by ::new.
      #
      # Related: #===, #include?, #include_star?, #intersect?
      def cover?(other) import_runs(other).none? { !include_run?(_1) } end

      # Returns +true+ when a given number or range is in +self+, and +false+
      # otherwise.  Returns +nil+ when +number+ isn't a valid SequenceSet
      # element (Integer, Range, <tt>*</tt>, +sequence-set+ string).
      #
      #     set = Net::IMAP::SequenceSet["5:10,100,111:115"]
      #     set.include? 1      #=> false
      #     set.include? 5..10  #=> true
      #     set.include? 11..20 #=> false
      #     set.include? 100    #=> true
      #     set.include? 6      #=> true, covered by "5:10"
      #     set.include? 6..9   #=> true, covered by "5:10"
      #     set.include? "6:9"  #=> true, strings are parsed
      #     set.include? 4..9   #=> false, intersection is not sufficient
      #     set.include? "*"    #=> false, use #limit to re-interpret "*"
      #     set.include? -1     #=> false, -1 is interpreted as "*"
      #
      #     set = Net::IMAP::SequenceSet["5:10,100,111:*"]
      #     set.include? :*     #=> true
      #     set.include? "*"    #=> true
      #     set.include? -1     #=> true
      #     set.include?(200..) #=> true
      #     set.include?(100..) #=> false
      #
      # Related: #include_star?, #cover?, #===, #intersect?
      def include?(element)
        run = import_run element rescue nil
        !!include_run?(run) if run
      end

      alias member? include?

      # Returns +true+ when the set contains <tt>*</tt>.
      def include_star?; max_num == STAR_INT end

      # Returns +true+ if the set and a given object have any common elements,
      # +false+ otherwise.
      #
      #     Net::IMAP::SequenceSet["5:10"].intersect? "7,9,11" #=> true
      #     Net::IMAP::SequenceSet["5:10"].intersect? "11:33"  #=> false
      #
      # Related: #intersection, #disjoint?, #cover?, #include?
      def intersect?(other)
        valid? && import_runs(other).any? { intersect_run? _1 }
      end
      alias overlap? intersect?

      # Returns +true+ if the set and a given object have no common elements,
      # +false+ otherwise.
      #
      #     Net::IMAP::SequenceSet["5:10"].disjoint? "7,9,11" #=> false
      #     Net::IMAP::SequenceSet["5:10"].disjoint? "11:33"  #=> true
      #
      # Related: #intersection, #intersect?
      def disjoint?(other)
        empty? || import_runs(other).none? { intersect_run? _1 }
      end

      # :call-seq:
      #   max(star: :*) => integer or star or nil
      #   max(count) => SequenceSet
      #
      # Returns the maximum value in +self+, +star+ when the set includes
      # <tt>*</tt>, or +nil+ when the set is empty.
      #
      # When +count+ is given, a new SequenceSet is returned, containing only
      # the last +count+ numbers.  An empty SequenceSet is returned when +self+
      # is empty.  (+star+ is ignored when +count+ is given.)
      #
      # Related: #min, #minmax, #slice
      def max(count = nil, star: :*)
        if count
          if cardinality <= count
            frozen? ? self : dup
          else
            slice(-count..) || remain_frozen_empty
          end
        elsif (val = max_num)
          val == STAR_INT ? star : val
        end
      end

      # :call-seq:
      #   min(star: :*) => integer or star or nil
      #   min(count) => SequenceSet
      #
      # Returns the minimum value in +self+, +star+ when the only value in the
      # set is <tt>*</tt>, or +nil+ when the set is empty.
      #
      # When +count+ is given, a new SequenceSet is returned, containing only
      # the first +count+ numbers.  An empty SequenceSet is returned when +self+
      # is empty.  (+star+ is ignored when +count+ is given.)
      #
      # Related: #max, #minmax, #slice
      def min(count = nil, star: :*)
        if count
          slice(0...count) || remain_frozen_empty
        elsif (val = min_num)
          val != STAR_INT ? val : star
        end
      end

      # :call-seq: minmax(star: :*) => [min, max] or nil
      #
      # Returns a 2-element array containing the minimum and maximum numbers in
      # +self+, or +nil+ when the set is empty.  +star+ is handled the same way
      # as by #min and #max.
      #
      # Related: #min, #max
      def minmax(star: :*); [min(star: star), max(star: star)] unless empty? end

      # Returns false when the set is empty.
      def valid?; !empty? end

      # Returns true if the set contains no elements
      def empty?; runs.empty? end

      # Returns true if the set contains every possible element.
      def full?; set_data == FULL_SET_DATA end

      # :call-seq:
      #   self + other -> sequence set
      #   self | other -> sequence set
      #   union(other) -> sequence set
      #
      # Returns a new sequence set that has every number in the +other+ object
      # added.
      #
      # +other+ may be any object that would be accepted by ::new.
      #
      #     Net::IMAP::SequenceSet["1:5"] | 2 | [4..6, 99]
      #     #=> Net::IMAP::SequenceSet["1:6,99"]
      #
      # Related: #add, #merge, #&, #-, #^, #~
      #
      # ==== Set identities
      #
      # <tt>lhs | rhs</tt> is equivalent to:
      # * <tt>rhs | lhs</tt> (commutative)
      # * <tt>~(~lhs & ~rhs)</tt> (De Morgan's Law)
      # * <tt>(lhs & rhs) ^ (lhs ^ rhs)</tt>
      def |(other) remain_frozen dup.merge other end
      alias :+    :|
      alias union :|

      # :call-seq:
      #   self - other      -> sequence set
      #   difference(other) -> sequence set
      #
      # Returns a new sequence set built by duplicating this set and removing
      # every number that appears in +other+.
      #
      # +other+ may be any object that would be accepted by ::new.
      #
      #     Net::IMAP::SequenceSet[1..5] - 2 - 4 - 6
      #     #=> Net::IMAP::SequenceSet["1,3,5"]
      #
      # Related: #subtract, #|, #&, #^, #~
      #
      # ==== Set identities
      #
      # <tt>lhs - rhs</tt> is equivalent to:
      # * <tt>~rhs - ~lhs</tt>
      # * <tt>lhs & ~rhs</tt>
      # * <tt>~(~lhs | rhs)</tt>
      # * <tt>lhs & (lhs ^ rhs)</tt>
      # * <tt>lhs ^ (lhs & rhs)</tt>
      # * <tt>rhs ^ (lhs | rhs)</tt>
      def -(other) remain_frozen dup.subtract other end
      alias difference :-

      # :call-seq:
      #   self & other        -> sequence set
      #   intersection(other) -> sequence set
      #
      # Returns a new sequence set containing only the numbers common to this
      # set and +other+.
      #
      # +other+ may be any object that would be accepted by ::new.
      #
      #     Net::IMAP::SequenceSet[1..5] & [2, 4, 6]
      #     #=> Net::IMAP::SequenceSet["2,4"]
      #
      # Related: #intersect?, #|, #-, #^, #~
      #
      # ==== Set identities
      #
      # <tt>lhs & rhs</tt> is equivalent to:
      # * <tt>rhs & lhs</tt> (commutative)
      # * <tt>~(~lhs | ~rhs)</tt> (De Morgan's Law)
      # * <tt>lhs - ~rhs</tt>
      # * <tt>lhs - (lhs - rhs)</tt>
      # * <tt>lhs - (lhs ^ rhs)</tt>
      # * <tt>lhs ^ (lhs - rhs)</tt>
      def &(other) remain_frozen dup.intersect! other end
      alias intersection :&

      # :call-seq:
      #   self ^ other -> sequence set
      #   xor(other)   -> sequence set
      #
      # Returns a new sequence set containing numbers that are exclusive between
      # this set and +other+.
      #
      # +other+ may be any object that would be accepted by ::new.
      #
      #     Net::IMAP::SequenceSet[1..5] ^ [2, 4, 6]
      #     #=> Net::IMAP::SequenceSet["1,3,5:6"]
      #
      # Related: #|, #&, #-, #~
      #
      # ==== Set identities
      #
      # <tt>lhs ^ rhs</tt> is equivalent to:
      # * <tt>rhs ^ lhs</tt> (commutative)
      # * <tt>~lhs ^ ~rhs</tt>
      # * <tt>(lhs | rhs) - (lhs & rhs)</tt>
      # * <tt>(lhs - rhs) | (rhs - lhs)</tt>
      # * <tt>(lhs ^ other) ^ (other ^ rhs)</tt>
      def ^(other) remain_frozen dup.xor! other end
      alias xor :^

      # :call-seq:
      #   ~ self     -> sequence set
      #   complement -> sequence set
      #
      # Returns the complement of self, a SequenceSet which contains all numbers
      # _except_ for those in this set.
      #
      #     ~Net::IMAP::SequenceSet.full  #=> Net::IMAP::SequenceSet.empty
      #     ~Net::IMAP::SequenceSet.empty #=> Net::IMAP::SequenceSet.full
      #     ~Net::IMAP::SequenceSet["1:5,100:222"]
      #     #=> Net::IMAP::SequenceSet["6:99,223:*"]
      #     ~Net::IMAP::SequenceSet["6:99,223:*"]
      #     #=> Net::IMAP::SequenceSet["1:5,100:222"]
      #
      # Related: #complement!, #|, #&, #-, #^
      #
      # ==== Set identities
      #
      # <tt>~set</tt> is equivalent to:
      # * <tt>full - set</tt>, where "full" is Net::IMAP::SequenceSet.full
      def ~; remain_frozen dup.complement! end
      alias complement :~

      # :call-seq:
      #   add(element)   -> self
      #   self << other -> self
      #
      # Adds a range or number to the set and returns +self+.
      #
      # #string will be regenerated.  Use #merge to add many elements at once.
      #
      # Use #append to append new elements to #string.  See
      # SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #add?, #merge, #union, #append
      def add(element)
        modifying! # short-circuit before import_run
        add_run import_run element
        normalize!
      end
      alias << add

      # Adds a range or number to the set and returns +self+.
      #
      # Unlike #add, #merge, or #union, the new value is appended to #string.
      # This may result in a #string which has duplicates or is out-of-order.
      #
      #    set = Net::IMAP::SequenceSet.new
      #    set.append(1..2)  # => Net::IMAP::SequenceSet("1:2")
      #    set.append(5)     # => Net::IMAP::SequenceSet("1:2,5")
      #    set.append(4)     # => Net::IMAP::SequenceSet("1:2,5,4")
      #    set.append(3)     # => Net::IMAP::SequenceSet("1:2,5,4,3")
      #    set.append(2)     # => Net::IMAP::SequenceSet("1:2,5,4,3,2")
      #
      # If +entry+ is a string, it will be converted into normal form.
      #
      #    set = Net::IMAP::SequenceSet("4:5,1:2")
      #    set.append("6:6") # => Net::IMAP::SequenceSet("4:5,1:2,6")
      #    set.append("9:8") # => Net::IMAP::SequenceSet("4:5,1:2,6,8:9")
      #
      # If +entry+ adjacently follows the last entry, they will coalesced:
      #    set = Net::IMAP::SequenceSet.new("2,1,9:10")
      #    set.append(11..12) # => Net::IMAP::SequenceSet("2,1,9:12")
      #
      # Non-normalized sets store the string <em>in addition to</em> an internal
      # normalized uint32 set representation.  This can more than double memory
      # usage, so large sets should avoid using #append unless preserving order
      # is required.  See SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #add, #merge, #union
      def append(entry)
        modifying! # short-circuit before import_minmax
        minmax = import_minmax entry
        adj = minmax.first - 1
        if @string.nil? && (runs.empty? || max_num <= adj)
          # append to elements or coalesce with last element
          add_minmax minmax
          return self
        elsif @string.nil?
          # generate string for out-of-order append
          head, comma = normalized_string, ","
        else
          # @string already exists... maybe coalesce with last entry
          head, comma, last_entry = @string.rpartition(",")
          last_min, last_max = import_minmax last_entry
          if last_max == adj
            # coalesce with last entry
            minmax[0] = last_min
          else
            # append to existing string
            head, comma = @string, ","
          end
        end
        entry = export_minmax minmax
        add_minmax minmax
        @string = -"#{head}#{comma}#{entry}"
        self
      end

      # :call-seq: add?(element) -> self or nil
      #
      # Adds a range or number to the set and returns +self+.  Returns +nil+
      # when the element is already included in the set.
      #
      # #string will be regenerated.  Use #merge to add many elements at once.
      #
      # Related: #add, #merge, #union, #include?
      def add?(element)
        modifying! # short-circuit before include?
        add element unless include? element
      end

      # :call-seq: delete(element) -> self
      #
      # Deletes the given range or number from the set and returns +self+.
      #
      # #string will be regenerated after deletion.  Use #subtract to remove
      # many elements at once.
      #
      # Related: #delete?, #delete_at, #subtract, #difference
      def delete(element)
        modifying! # short-circuit before import_run
        subtract_run import_run element
        normalize!
      end

      # :call-seq:
      #   delete?(number) -> integer or nil
      #   delete?(star)   -> :* or nil
      #   delete?(range)  -> sequence set or nil
      #
      # Removes a specified value from the set, and returns the removed value.
      # Returns +nil+ if nothing was removed.
      #
      # Returns an integer when the specified +number+ argument was removed:
      #     set = Net::IMAP::SequenceSet.new [5..10, 20]
      #     set.delete?(7)      #=> 7
      #     set                 #=> #<Net::IMAP::SequenceSet "5:6,8:10,20">
      #     set.delete?("20")   #=> 20
      #     set                 #=> #<Net::IMAP::SequenceSet "5:6,8:10">
      #     set.delete?(30)     #=> nil
      #
      # Returns <tt>:*</tt> when <tt>*</tt> or <tt>-1</tt> is specified and
      # removed:
      #     set = Net::IMAP::SequenceSet.new "5:9,20,35,*"
      #     set.delete?(-1)  #=> :*
      #     set              #=> #<Net::IMAP::SequenceSet "5:9,20,35">
      #
      # And returns a new SequenceSet when a range is specified:
      #
      #     set = Net::IMAP::SequenceSet.new [5..10, 20]
      #     set.delete?(9..)  #=> #<Net::IMAP::SequenceSet "9:10,20">
      #     set               #=> #<Net::IMAP::SequenceSet "5:8">
      #     set.delete?(21..) #=> nil
      #
      # #string will be regenerated after deletion.
      #
      # Related: #delete, #delete_at, #subtract, #difference, #disjoint?
      def delete?(element)
        modifying! # short-circuit before import_minmax
        element = input_try_convert(element)
        minmax = import_minmax element
        if number_input?(element)
          return unless include_minmax? minmax
          subtract_minmax minmax
          normalize!
          export_num minmax.first
        else
          copy = dup
          subtract_minmax minmax
          normalize!
          copy if copy.subtract(self).valid?
        end
      end

      # :call-seq: delete_at(index) -> number or :* or nil
      #
      # Deletes a number the set, indicated by the given +index+.  Returns the
      # number that was removed, or +nil+ if nothing was removed.
      #
      # #string will be regenerated after deletion.
      #
      # Related: #delete, #delete?, #slice!, #subtract, #difference
      def delete_at(index)
        slice! Integer(index.to_int)
      end

      # :call-seq:
      #    slice!(index)          -> integer or :* or nil
      #    slice!(start, length)  -> sequence set or nil
      #    slice!(range)          -> sequence set or nil
      #
      # Deletes a number or consecutive numbers from the set, indicated by the
      # given +index+, +start+ and +length+, or +range+ of offsets.  Returns the
      # number or sequence set that was removed, or +nil+ if nothing was
      # removed.  Arguments are interpreted the same as for #slice or #[].
      #
      # #string will be regenerated after deletion.
      #
      # Related: #slice, #delete_at, #delete, #delete?, #subtract, #difference
      def slice!(index, length = nil)
        modifying! # short-circuit before slice
        deleted = slice(index, length) and subtract deleted
        deleted
      end

      # In-place set #union.  Merges all of the elements that appear in any of
      # the +sets+ into this set, and returns +self+.
      #
      # The +sets+ may be any objects that would be accepted by ::new.
      #
      # #string will be regenerated after all sets have been merged.
      #
      # Related: #add, #add?, #union
      def merge(*sets)
        modifying! # short-circuit before import_runs
        add_runs import_runs sets
        normalize!
      end

      # In-place set #difference.  Removes all of the elements that appear in
      # any of the given +sets+ from this set, and returns +self+.
      #
      # The +sets+ may be any objects that would be accepted by ::new.
      #
      # Related: #difference
      def subtract(*sets)
        modifying! # short-circuit before import_runs
        subtract_runs import_runs sets
        normalize!
      end

      # Returns an array of ranges and integers and <tt>:*</tt>.
      #
      # The entries are in the same order they appear in #string, with no
      # sorting, deduplication, or coalescing.  When #string is in its
      # normalized form, this will return the same result as #elements.
      # This is useful when the given order is significant, for example in a
      # ESEARCH response to IMAP#sort.
      #
      # See SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #each_entry, #elements
      def entries; each_entry.to_a end

      # Returns an array of ranges and integers and <tt>:*</tt>.
      #
      # The returned elements are sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize,
      # SequenceSet@Ordered+and+Normalized+sets.
      #
      # By itself, <tt>*</tt> translates to <tt>:*</tt>.  A range containing
      # <tt>*</tt> translates to an endless range.  Use #limit to translate both
      # cases to a maximum value.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,*,12:11"].elements
      #   #=> [2, 5..9, 11..12, :*]
      #
      # Related: #each_element, #ranges, #numbers
      def elements; each_element.to_a end
      alias to_a elements

      # Returns an array of ranges
      #
      # The returned elements are sorted and coalesced, even when the input
      # #string is not.  <tt>*</tt> will sort last.  See #normalize,
      # SequenceSet@Ordered+and+Normalized+sets.
      #
      # <tt>*</tt> translates to an endless range.  By itself, <tt>*</tt>
      # translates to <tt>:*..</tt>.  Use #limit to set <tt>*</tt> to a maximum
      # value.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,*,12:11"].ranges
      #   #=> [2..2, 5..9, 11..12, :*..]
      #   Net::IMAP::SequenceSet["123,999:*,456:789"].ranges
      #   #=> [123..123, 456..789, 999..]
      #
      # Related: #each_range, #elements, #numbers, #to_set
      def ranges; each_range.to_a end

      # Returns a sorted array of all of the number values in the sequence set.
      #
      # The returned numbers are sorted and de-duplicated, even when the input
      # #string is not.  See #normalize, SequenceSet@Ordered+and+Normalized+sets.
      #
      #   Net::IMAP::SequenceSet["2,5:9,6,12:11"].numbers
      #   #=> [2, 5, 6, 7, 8, 9, 11, 12]
      #
      # If the set contains a <tt>*</tt>, RangeError is raised.  See #limit.
      #
      #   Net::IMAP::SequenceSet["10000:*"].numbers
      #   #!> RangeError
      #
      # *WARNING:* Even excluding sets with <tt>*</tt>, an enormous result can
      # easily be created.  An array with over 4 billion integers could be
      # returned, requiring up to 32GiB of memory on a 64-bit architecture.
      #
      #   Net::IMAP::SequenceSet[10000..2**32-1].numbers
      #   # ...probably freezes the process for a while...
      #   #!> NoMemoryError (probably)
      #
      # For safety, consider using #limit or #intersection to set an upper
      # bound.  Alternatively, use #each_element, #each_range, or even
      # #each_number to avoid allocation of a result array.
      #
      # Related: #elements, #ranges, #to_set
      def numbers; each_number.to_a end

      # Yields each number or range in #string to the block and returns +self+.
      # Returns an enumerator when called without a block.
      #
      # The entries are yielded in the same order they appear in #string, with
      # no sorting, deduplication, or coalescing.  When #string is in its
      # normalized form, this will yield the same values as #each_element.
      #
      # See SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #entries, #each_element
      def each_entry(&block) # :yields: integer or range or :*
        return to_enum(__method__) unless block_given?
        each_entry_run do yield export_run_entry _1 end
      end

      # Yields each number or range (or <tt>:*</tt>) in #elements to the block
      # and returns self.  Returns an enumerator when called without a block.
      #
      # The returned numbers are sorted and de-duplicated, even when the input
      # #string is not.  See #normalize, SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #elements, #each_entry
      def each_element # :yields: integer or range or :*
        return to_enum(__method__) unless block_given?
        runs.each do yield export_run_entry _1 end
        self
      end

      # Yields each range in #ranges to the block and returns self.
      # Returns an enumerator when called without a block.
      #
      # Related: #ranges
      def each_range # :yields: range
        return to_enum(__method__) unless block_given?
        minmaxes.each do |min, max|
          if    min == STAR_INT then yield :*..
          elsif max == STAR_INT then yield min..
          else                       yield min..max
          end
        end
        self
      end

      # Yields each number in #numbers to the block and returns self.
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # Returns an enumerator when called without a block (even if the set
      # contains <tt>*</tt>).
      #
      # Related: #numbers, #each_ordered_number
      def each_number(&block) # :yields: integer
        return to_enum(__method__) unless block_given?
        raise RangeError, '%s contains "*"' % [self.class] if include_star?
        minmaxes.each do each_number_in_minmax _1, _2, &block end
        self
      end

      # Yields each number in #entries to the block and returns self.
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # Returns an enumerator when called without a block (even if the set
      # contains <tt>*</tt>).
      #
      # Related: #entries, #each_number
      def each_ordered_number(&block)
        return to_enum(__method__) unless block_given?
        raise RangeError, '%s contains "*"' % [self.class] if include_star?
        each_entry_minmax do each_number_in_minmax _1, _2, &block end
      end

      # Returns a Set with all of the #numbers in the sequence set.
      #
      # If the set contains a <tt>*</tt>, RangeError will be raised.
      #
      # See #numbers for the warning about very large sets.
      #
      # Related: #elements, #ranges, #numbers
      def to_set; Set.new(numbers) end

      # Returns the number of members in the set.
      #
      # Unlike #count, <tt>"*"</tt> is considered to be distinct from
      # <tt>2³² - 1</tt> (the maximum 32-bit unsigned integer value).
      #
      #     set = Net::IMAP::SequenceSet[1..10]
      #     set.count        #=> 10
      #     set.cardinality  #=> 10
      #
      #     set = Net::IMAP::SequenceSet["4294967295,*"]
      #     set.count        #=> 1
      #     set.cardinality  #=> 2
      #
      #     set = Net::IMAP::SequenceSet[1..]
      #     set.count        #=> 4294967295
      #     set.cardinality  #=> 4294967296
      #
      # Related: #count, #count_with_duplicates
      def cardinality = minmaxes.sum(runs.count) { _2 - _1 }

      # Returns the count of distinct #numbers in the set.
      #
      # Unlike #cardinality, <tt>"*"</tt> is considered to be equal to
      # <tt>2³² - 1</tt> (the maximum 32-bit unsigned integer value).
      #
      #     set = Net::IMAP::SequenceSet[1..10]
      #     set.count        #=> 10
      #     set.cardinality  #=> 10
      #
      #     set = Net::IMAP::SequenceSet["4294967295,*"]
      #     set.count        #=> 1
      #     set.cardinality  #=> 2
      #
      #     set = Net::IMAP::SequenceSet[1..]
      #     set.count        #=> 4294967295
      #     set.cardinality  #=> 4294967296
      #
      # Related: #cardinality, #count_with_duplicates
      def count
        cardinality + (include_star? && include?(UINT32_MAX) ? -1 : 0)
      end

      # Returns the count of numbers in the ordered #entries, including any
      # repeated numbers.
      #
      # When #string is normalized, this returns the same as #count.  Like
      # #count, <tt>"*"</tt> is considered to be equal to <tt>2³² - 1</tt> (the
      # maximum 32-bit unsigned integer value).
      #
      # In a range, <tt>"*"</tt> is _not_ considered a duplicate:
      #     set = Net::IMAP::SequenceSet["4294967295:*"]
      #     set.count_with_duplicates  #=> 1
      #     set.size                   #=> 2
      #     set.count                  #=> 1
      #     set.cardinality            #=> 2
      #
      # In a separate entry, <tt>"*"</tt> _is_ considered a duplicate:
      #     set = Net::IMAP::SequenceSet["4294967295,*"]
      #     set.count_with_duplicates  #=> 2
      #     set.size                   #=> 2
      #     set.count                  #=> 1
      #     set.cardinality            #=> 2
      #
      # Related: #count, #cardinality, #size, #count_duplicates,
      # #has_duplicates?, #entries
      def count_with_duplicates
        return count unless @string
        each_entry_minmax.sum {|min, max|
          max - min + ((max == STAR_INT && min != STAR_INT) ? 0 : 1)
        }
      end

      # Returns the combined size of the ordered #entries, including any
      # repeated numbers.
      #
      # When #string is normalized, this returns the same as #cardinality.
      # Like #cardinality, <tt>"*"</tt> is considered to be be distinct from
      # <tt>2³² - 1</tt> (the maximum 32-bit unsigned integer value).
      #
      #     set = Net::IMAP::SequenceSet["4294967295:*"]
      #     set.size                   #=> 2
      #     set.count_with_duplicates  #=> 1
      #     set.count                  #=> 1
      #     set.cardinality            #=> 2
      #
      #     set = Net::IMAP::SequenceSet["4294967295,*"]
      #     set.size                   #=> 2
      #     set.count_with_duplicates  #=> 2
      #     set.count                  #=> 1
      #     set.cardinality            #=> 2
      #
      # Related: #cardinality, #count_with_duplicates, #count, #entries
      def size
        return cardinality unless @string
        each_entry_minmax.sum {|min, max| max - min + 1 }
      end

      # Returns the count of repeated numbers in the ordered #entries, the
      # difference between #count_with_duplicates and #count.
      #
      # When #string is normalized, this is zero.
      #
      # Related: #entries, #count_with_duplicates, #has_duplicates?
      def count_duplicates
        return 0 unless @string
        count_with_duplicates - count
      end

      # :call-seq: has_duplicates? -> true | false
      #
      # Returns whether or not the ordered #entries repeat any numbers.
      #
      # Always returns +false+ when #string is normalized.
      #
      # Related: #entries, #count_with_duplicates, #count_duplicates
      def has_duplicates?
        return false unless @string
        count_with_duplicates != count
      end

      # Returns the (sorted and deduplicated) index of +number+ in the set, or
      # +nil+ if +number+ isn't in the set.
      #
      # Related: #[], #at, #find_ordered_index
      def find_index(number)
        number = import_num number
        each_minmax_with_index(minmaxes) do |min, max, idx_min|
          number <  min and return nil
          number <= max and return export_num(idx_min + (number - min))
        end
        nil
      end

      # Returns the first index of +number+ in the ordered #entries, or
      # +nil+ if +number+ isn't in the set.
      #
      # Related: #find_index
      def find_ordered_index(number)
        number = import_num number
        each_minmax_with_index(each_entry_minmax) do |min, max, idx_min|
          if min <= number && number <= max
            return export_num(idx_min + (number - min))
          end
        end
        nil
      end

      # :call-seq: at(index) -> integer or nil
      #
      # Returns the number at the given +index+ in the sorted set, without
      # modifying the set.
      #
      # +index+ is interpreted the same as in #[], except that #at only allows a
      # single integer argument.
      #
      # Related: #[], #slice, #ordered_at
      def at(index)
        seek_number_in_minmaxes(minmaxes, index)
      end

      # :call-seq: ordered_at(index) -> integer or nil
      #
      # Returns the number at the given +index+ in the ordered #entries, without
      # modifying the set.
      #
      # +index+ is interpreted the same as in #at (and #[]), except that
      # #ordered_at applies to the ordered #entries, not the sorted set.
      #
      # Related: #[], #slice, #ordered_at
      def ordered_at(index)
        seek_number_in_minmaxes(each_entry_minmax, index)
      end

      # :call-seq:
      #    seqset[index]         -> integer or :* or nil
      #    slice(index)          -> integer or :* or nil
      #    seqset[start, length] -> sequence set or nil
      #    slice(start, length)  -> sequence set or nil
      #    seqset[range]         -> sequence set or nil
      #    slice(range)          -> sequence set or nil
      #
      # Returns a number or a subset from the _sorted_ set, without modifying
      # the set.
      #
      # When an Integer argument +index+ is given, the number at offset +index+
      # in the sorted set is returned:
      #
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[0]   #=> 10
      #     set[5]   #=> 15
      #     set[10]  #=> 26
      #
      # If +index+ is negative, it counts relative to the end of the sorted set:
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[-1]  #=> 26
      #     set[-3]  #=> 22
      #     set[-6]  #=> 15
      #
      # If +index+ is out of range, +nil+ is returned.
      #
      #     set = Net::IMAP::SequenceSet["10:15,20:23,26"]
      #     set[11]  #=> nil
      #     set[-12] #=> nil
      #
      # The result is based on the sorted and de-duplicated set, not on the
      # ordered #entries in #string.
      #
      #     set = Net::IMAP::SequenceSet["12,20:23,11:16,21"]
      #     set[0]   #=> 11
      #     set[-1]  #=> 23
      #
      # Related: #at
      def [](index, length = nil)
        if    length              then slice_length(index, length)
        elsif index.is_a?(Range)  then slice_range(index)
        else                           at(index)
        end
      end

      alias slice :[]

      # Returns a copy of +self+ which only contains the numbers above +num+.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"].above(10) # to_s => "11:22,50"
      #   Net::IMAP::SequenceSet["5,10:22,50"].above(20) # to_s => "21:22,50
      #   Net::IMAP::SequenceSet["5,10:22,50"].above(30) # to_s => "50"
      #
      # This returns the same result as #intersection with <tt>((num+1)..)</tt>
      # or #difference with <tt>(..num)</tt>.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"] & (11..)   # to_s => "11:22,50"
      #   Net::IMAP::SequenceSet["5,10:22,50"] - (..10)   # to_s => "11:22,50"
      #   Net::IMAP::SequenceSet["5,10:22,50"] & (21..)   # to_s => "21:22,50"
      #   Net::IMAP::SequenceSet["5,10:22,50"] - (..20)   # to_s => "21:22,50"
      #
      # Related: #above, #-, #&
      def above(num)
        NumValidator.valid_nz_number?(num) or
          raise ArgumentError, "not a valid sequence set number"
        difference(..num)
      end

      # Returns a copy of +self+ which only contains numbers below +num+.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"].below(10) # to_s => "5"
      #   Net::IMAP::SequenceSet["5,10:22,50"].below(20) # to_s => "5,10:19"
      #   Net::IMAP::SequenceSet["5,10:22,50"].below(30) # to_s => "5,10:22"
      #
      # This returns the same result as #intersection with <tt>(..(num-1))</tt>
      # or #difference with <tt>(num..)</tt>.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"] & (..9)    # to_s => "5"
      #   Net::IMAP::SequenceSet["5,10:22,50"] - (10..)   # to_s => "5"
      #   Net::IMAP::SequenceSet["5,10:22,50"] & (..19)   # to_s => "5,10:19"
      #   Net::IMAP::SequenceSet["5,10:22,50"] - (20..)   # to_s => "5,10:19"
      #
      # When the set does not contain <tt>*</tt>, #below is identical to #limit
      # with <tt>max: num - 1</tt>.  When the set does contain <tt>*</tt>,
      # #below always drops it from the result.  Use #limit when the IMAP
      # semantics for <tt>*</tt> must be enforced.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"].below(30)      # to_s => "5,10:22"
      #   Net::IMAP::SequenceSet["5,10:22,50"].limit(max: 29) # to_s => "5,10:22"
      #   Net::IMAP::SequenceSet["5,10:22,*"].below(30)       # to_s => "5,10:22"
      #   Net::IMAP::SequenceSet["5,10:22,*"].limit(max: 29)  # to_s => "5,10:22,29"
      #
      # Related: #above, #-, #&, #limit
      def below(num)
        NumValidator.valid_nz_number?(num) or
          raise ArgumentError, "not a valid sequence set number"
        difference(num..)
      end

      # Returns a frozen SequenceSet with <tt>*</tt> converted to +max+, numbers
      # and ranges over +max+ removed, and ranges containing +max+ converted to
      # end at +max+.
      #
      #   Net::IMAP::SequenceSet["5,10:22,50"].limit(max: 20).to_s
      #   #=> "5,10:20"
      #
      # <tt>*</tt> is always interpreted as the maximum value.  When the set
      # contains <tt>*</tt>, it will be set equal to the limit.
      #
      #   Net::IMAP::SequenceSet["*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["37"]
      #   Net::IMAP::SequenceSet["5:*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["5:37"]
      #   Net::IMAP::SequenceSet["500:*"].limit(max: 37)
      #   #=> Net::IMAP::SequenceSet["37"]
      #
      # Related: #limit!
      def limit(max:)
        max = import_num(max)
        if    empty?                      then self.class.empty
        elsif !include_star? && max < min then self.class.empty
        elsif max(star: STAR_INT) <= max  then frozen? ? self : dup.freeze
        else                                   dup.limit!(max: max).freeze
        end
      end

      # Removes all members over +max+ and returns self.  If <tt>*</tt> is a
      # member, it will be converted to +max+.
      #
      # Related: #limit
      def limit!(max:)
        modifying! # short-circuit before querying
        star = include_star?
        max  = import_num(max)
        subtract_minmax [max + 1, STAR_INT]
        add_minmax      [max,     max     ] if star
        normalize!
      end

      # :call-seq: complement! -> self
      #
      # In-place set #complement.  Replaces the contents of this set with its
      # own #complement.  It will contain all possible values _except_ for those
      # currently in the set.
      #
      # Related: #complement
      def complement!
        modifying! # short-circuit before querying
        return replace(self.class.full) if empty?
        return clear                    if full?
        flat = minmaxes.flat_map { [_1 - 1, _2 + 1] }
        if flat.first < 1         then flat.shift else flat.unshift 1        end
        if STAR_INT   < flat.last then flat.pop   else flat.push    STAR_INT end
        replace_minmaxes flat.each_slice(2).to_a
        normalize!
      end

      # In-place set #intersection.  Removes any elements that are missing from
      # +other+ from this set, keeping only the #intersection, and returns
      # +self+.
      #
      # +other+ can be any object that would be accepted by ::new.
      #
      #     set = Net::IMAP::SequenceSet.new(1..5)
      #     set.intersect! [2, 4, 6]
      #     set #=> Net::IMAP::SequenceSet("2,4")
      #
      # Related: #intersection, #intersect?
      def intersect!(other)
        modifying! # short-circuit before processing input
        subtract SequenceSet.new(other).complement!
      end

      # In-place set #xor.  Adds any numbers in +other+ that are missing from
      # this set, removes any numbers in +other+ that are already in this set,
      # and returns +self+.
      #
      # +other+ can be any object that would be accepted by ::new.
      #
      #     set = Net::IMAP::SequenceSet.new(1..5)
      #     set.xor! [2, 4, 6]
      #     set #=> Net::IMAP::SequenceSet["1,3,5:6"]
      #
      # Related: #xor, #merge, #subtract
      def xor!(other)
        modifying! # short-circuit before processing input
        other = SequenceSet.new(other)
        copy  = dup
        merge(other).subtract(other.subtract(copy.complement!))
      end

      # Returns whether #string is fully normalized: entries have been sorted,
      # deduplicated, and coalesced, and all entries are in normal form.  See
      # SequenceSet@Ordered+and+Normalized+sets.
      #
      #   Net::IMAP::SequenceSet["1,3,5"].normalized?  #=> true
      #   Net::IMAP::SequenceSet["20:30"].normalized?  #=> true
      #
      #   Net::IMAP::SequenceSet["3,5,1"].normalized?  #=> false, not sorted
      #   Net::IMAP::SequenceSet["1,2,3"].normalized?  #=> false, not coalesced
      #   Net::IMAP::SequenceSet["1:5,2"].normalized?  #=> false, repeated number
      #
      #   Net::IMAP::SequenceSet["1:1"].normalized?    #=> false, number as range
      #   Net::IMAP::SequenceSet["5:1"].normalized?    #=> false, backwards range
      #
      # Returns +true+ if (and only if) #string is equal to #normalized_string:
      #   seqset = Net::IMAP::SequenceSet["1:3,5"]
      #   seqset.string             #=> "1:3,5"
      #   seqset.normalized_string  #=> "1:3,5"
      #   seqset.entries            #=> [1..3, 5]
      #   seqset.elements           #=> [1..3, 5]
      #   seqset.normalized?        #=> true
      #
      #   seqset = Net::IMAP::SequenceSet["3,1,2"]
      #   seqset.string             #=> "3,1,2"
      #   seqset.normalized_string  #=> "1:3"
      #   seqset.entries            #=> [3, 1, 2]
      #   seqset.elements           #=> [1..3]
      #   seqset.normalized?        #=> false
      #
      # Can return +false+ even when #entries and #elements are the same:
      #   seqset = Net::IMAP::SequenceSet["5:1"]
      #   seqset.string             #=> "5:1"
      #   seqset.normalized_string  #=> "1:5"
      #   seqset.entries            #=> [1..5]
      #   seqset.elements           #=> [1..5]
      #   seqset.normalized?        #=> false
      #
      # Note that empty sets are normalized, even though they are not #valid?:
      #   seqset = Net::IMAP::SequenceSet.empty
      #   seqset.normalized?        #=> true
      #   seqset.valid?             #=> false
      #
      # Related: #normalize, #normalize!, #normalized_string
      def normalized?
        @string.nil? || normal_string?(@string)
      end

      # Returns a SequenceSet with a normalized string representation: entries
      # have been sorted, deduplicated, and coalesced, and all entries
      # are in normal form.  Returns +self+ for frozen normalized sets, and a
      # normalized duplicate otherwise.
      #
      # See SequenceSet@Ordered+and+Normalized+sets.
      #
      #   Net::IMAP::SequenceSet["1:5,3:7,10:9,10:11"].normalize
      #   #=> Net::IMAP::SequenceSet["1:7,9:11"]
      #
      # Related: #normalize!, #normalized_string, #normalized?
      def normalize
        frozen? && normalized? ? self : remain_frozen(dup.normalize!)
      end

      # Resets #string to be sorted, deduplicated, and coalesced.  Returns
      # +self+.  See SequenceSet@Ordered+and+Normalized+sets.
      #
      # Related: #normalize, #normalized_string, #normalized?
      def normalize!
        modifying! # redundant check (normalizes the error message for JRuby)
        @string = nil
        self
      end

      # Returns a normalized +sequence-set+ string representation, sorted
      # and deduplicated.  Adjacent or overlapping elements will be merged into
      # a single larger range.  See SequenceSet@Ordered+and+Normalized+sets.
      #
      #   Net::IMAP::SequenceSet["1:5,3:7,10:9,10:11"].normalized_string
      #   #=> "1:7,9:11"
      #
      # Returns +nil+ when the set is empty.
      #
      # Related: #normalize!, #normalize, #string, #to_s, #normalized?
      def normalized_string
        export_runs(runs) unless runs.empty?
      end

      # Returns an inspection string for the SequenceSet.
      #
      #   Net::IMAP::SequenceSet.new.inspect
      #   #=> "Net::IMAP::SequenceSet()"
      #
      #   Net::IMAP::SequenceSet(1..5, 1024, 15, 2000).inspect
      #   #=> 'Net::IMAP::SequenceSet("1:5,15,1024,2000")'
      #
      # Frozen sets have slightly different output:
      #
      #   Net::IMAP::SequenceSet.empty.inspect
      #   #=> "Net::IMAP::SequenceSet.empty"
      #
      #   Net::IMAP::SequenceSet[1..5, 1024, 15, 2000].inspect
      #   #=> 'Net::IMAP::SequenceSet["1:5,15,1024,2000"]'
      #
      # Large sets (by number of #entries) have abridged output, with only the
      # first and last entries:
      #
      #   Net::IMAP::SequenceSet(((1..5000) % 2).to_a).inspect
      #   #=> #<Net::IMAP::SequenceSet 2500 entries "1,3,5,7,9,11,13,15,17,19,21,23,25,27,29,31,...(2468 entries omitted)...,4969,4971,4973,4975,4977,4979,4981,4983,4985,4987,4989,4991,4993,4995,4997,4999">
      #
      # Related: #to_s, #string
      def inspect
        case (count = count_entries)
        when 0
          (frozen? ? "%s.empty" : "%s()") % [self.class]
        when ..INSPECT_MAX_LEN
          (frozen? ? "%s[%p]" : "%s(%p)") % [self.class, to_s]
        else
          if @string
            head = @string[INSPECT_ABRIDGED_HEAD_RE]
            tail = @string[INSPECT_ABRIDGED_TAIL_RE]
          else
            head = export_runs(runs.first(INSPECT_TRUNCATE_LEN)) + ","
            tail = "," + export_runs(runs.last(INSPECT_TRUNCATE_LEN))
          end
          '#<%s %d entries "%s...(%d entries omitted)...%s"%s>' % [
            self.class, count,
            head, count - INSPECT_TRUNCATE_LEN * 2, tail,
            frozen? ? " (frozen)" : "",
          ]
        end
      end

      ##
      # :method: to_sequence_set
      # :call-seq: to_sequence_set -> self
      #
      # Returns +self+
      #
      # Related: ::try_convert

      # :nodoc: (work around rdoc bug)
      alias to_sequence_set itself

      # Unstable API: currently for internal use only (Net::IMAP#validate_data)
      def validate # :nodoc:
        empty? and raise DataFormatError, "empty sequence-set is invalid"
        self
      end

      # Unstable API: for internal use only (Net::IMAP#send_data)
      def send_data(imap, tag) # :nodoc:
        imap.__send__(:put_string, valid_string)
      end

      # For YAML serialization
      def encode_with(coder) # :nodoc:
        # we can perfectly reconstruct from the string
        coder['string'] = to_s
      end

      # For YAML deserialization
      def init_with(coder) # :nodoc:
        @set_data = new_set_data
        self.string = coder['string']
      end

      # :stopdoc:
      protected

      attr_reader :set_data

      alias runs set_data
      alias minmaxes runs

      private

      def remain_frozen(set) frozen? ? set.freeze : set end
      def remain_frozen_empty; frozen? ? SequenceSet.empty : SequenceSet.new end

      # frozen clones are shallow copied
      def initialize_clone(other)
        @set_data = other.dup_set_data unless other.frozen?
        super
      end

      def initialize_dup(other)
        @set_data = other.dup_set_data
        super
      end

      ######################################################################{{{2
      # Import methods

      def import_minmax(input)
        entry = input_try_convert input
        case entry
        when *STARS, Integer then [int = import_num(entry), int]
        when Range           then import_range_minmax(entry)
        when String          then parse_minmax(entry)
        else
          raise DataFormatError, "expected number or range, got %p" % [input]
        end
      end
      alias import_run import_minmax

      def import_runs(input)
        set = input_try_convert input
        case set
        when *STARS, Integer, Range then [import_run(set)]
        when String      then parse_runs set
        when SequenceSet then set.runs
        when Set         then set.map      { [import_num(_1)] * 2 }
        when Array       then set.flat_map { import_runs _1 }
        when nil         then []
        else
          raise DataFormatError, "expected nz-number, range, '*', Set, Array; " \
                                 "got %p" % [input]
        end
      end

      # unlike SequenceSet#try_convert, this returns an Integer, Range,
      # String, Set, Array, or... any type of object.
      def input_try_convert(input)
        SequenceSet.try_convert(input) ||
          Integer.try_convert(input) ||
          String.try_convert(input) ||
          input
      end

      # NOTE: input_try_convert must be called on input first
      def number_input?(input)
        case input
        when *STARS, Integer then true
        when String          then !input.include?(/[:,]/)
        end
      end

      def import_range_minmax(range)
        first = import_num(range.begin || 1)
        last  = import_num(range.end   || :*)
        last -= 1 if range.exclude_end? && range.end && last != STAR_INT
        unless first <= last
          raise DataFormatError, "invalid range for sequence-set: %p" % [range]
        end
        [first, last]
      end

      def import_num(obj) STARS.include?(obj) ? STAR_INT : nz_number(obj) end
      def nz_number(num) = NumValidator.coerce_nz_number(num)

      ######################################################################{{{2
      # Export methods

      def export_num(num) num == STAR_INT ? :* : num end

      def export_minmaxes(minmaxes)
        -minmaxes.map { export_minmax _1 }.join(",")
      end

      def export_minmax(minmax) minmax.uniq.map { export_num _1 }.join(":") end

      alias export_runs export_minmaxes
      alias export_run  export_minmax

      def export_minmax_entry((min, max))
        if    min == STAR_INT then :*
        elsif max == STAR_INT then min..
        elsif min == max      then min
        else                       min..max
        end
      end
      alias export_run_entry export_minmax_entry

      def each_number_in_minmax(min, max, &block)
        if    min == STAR_INT then yield :*
        elsif min == max      then yield min
        elsif max != STAR_INT then (min..max).each(&block)
        else
          raise RangeError, "#{SequenceSet} cannot enumerate range with '*'"
        end
      end

      ######################################################################{{{2
      # Parse methods

      def parse_runs(str) str.split(",", -1).map! { parse_run _1 } end
      def parse_minmax(str) parse_entry(str).minmax end
      alias parse_run parse_minmax

      def parse_entry(str)
        raise DataFormatError, "invalid sequence set string" if str.empty?
        str.split(":", 2).map! { import_num _1 }
      end

      # yields validated but unsorted [num] or [num, num]
      def each_parsed_entry(str)
        return to_enum(__method__, str) unless block_given?
        str&.split(",", -1) do |entry| yield parse_entry(entry) end
      end

      def normal_string?(str) normalized_entries? each_parsed_entry str end

      def normalized_entries?(entries)
        max = nil
        entries.each do |first, last|
          return false if last && last  <= first    # 1:1 or 2:1
          return false if max  && first <= max + 1  # 2,1 or 1,1 or 1,2
          max = last || first
        end
        true
      end

      ######################################################################{{{2
      # Ordered entry methods

      def count_entries
        @string ? @string.count(",") + 1 : runs.count
      end

      def each_entry_minmax(&block)
        return to_enum(__method__) unless block_given?
        if @string
          @string.split(",") do block.call parse_minmax _1 end
        else
          minmaxes.each(&block)
        end
        self
      end
      alias each_entry_run each_entry_minmax

      ######################################################################{{{2
      # Search methods

      def include_minmax?((min, max)) bsearch_range(min)&.cover?(min..max) end

      def intersect_minmax?((min, max))
        range = bsearch_range(min) and
          range.include?(min) || range.include?(max) || (min..max).cover?(range)
      end

      alias include_run?   include_minmax?
      alias intersect_run? intersect_minmax?

      def bsearch_index(num)  = minmaxes.bsearch_index { _2 >= num }
      def bsearch_minmax(num) = minmaxes.bsearch       { _2 >= num }
      def bsearch_range(num)  = (min, max = bsearch_minmax(num)) && (min..max)

      ######################################################################{{{2
      # Number indexing methods

      def seek_number_in_minmaxes(minmaxes, index)
        index = Integer(index.to_int)
        if index.negative?
          reverse_each_minmax_with_index(minmaxes) do |min, max, idx_min, idx_max|
            idx_min <= index and return export_num(min + (index - idx_min))
          end
        else
          each_minmax_with_index(minmaxes) do |min, _, idx_min, idx_max|
            index <= idx_max and return export_num(min + (index - idx_min))
          end
        end
        nil
      end

      def each_minmax_with_index(minmaxes)
        idx_min = 0
        minmaxes.each do |min, max|
          idx_max = idx_min + (max - min)
          yield min, max, idx_min, idx_max
          idx_min = idx_max + 1
        end
        idx_min
      end

      def reverse_each_minmax_with_index(minmaxes)
        idx_max = -1
        minmaxes.reverse_each do |min, max|
          yield min, max, (idx_min = idx_max - (max - min)), idx_max
          idx_max = idx_min - 1
        end
        idx_max
      end

      def slice_length(start, length)
        start  = Integer(start.to_int)
        length = Integer(length.to_int)
        raise ArgumentError, "length must be positive" unless length.positive?
        last = start + length - 1 unless start.negative? && start.abs <= length
        slice_range(start..last)
      end

      def slice_range(range)
        first = range.begin ||  0
        last  = range.end   || -1
        if range.exclude_end?
          return remain_frozen_empty if last.zero?
          last -= 1 if range.end && last != STAR_INT
        end
        if (first * last).positive? && last < first
          remain_frozen_empty
        elsif (min = at(first))
          max = at(last)
          max = :* if max.nil?
          if    max == :*  then self & (min..)
          elsif min <= max then self & (min..max)
          else                  remain_frozen_empty
          end
        end
      end

      ######################################################################{{{2
      # Core set data create/freeze/dup primitives

      def new_set_data    = []
      def freeze_set_data = set_data.each(&:freeze).freeze
      def dup_set_data    = set_data.map { _1.dup }
      protected :dup_set_data

      ######################################################################{{{2
      # Core set data query/enumeration primitives

      def min_num                 = minmaxes.first&.first
      def max_num                 = minmaxes.last&.last

      def min_at(idx)             = minmaxes[idx][0]
      def max_at(idx)             = minmaxes[idx][1]

      ######################################################################{{{2
      # Core set data modification primitives

      def set_min_at(idx, min)         = minmaxes[idx][0] = min
      def set_max_at(idx, max)         = minmaxes[idx][1] = max
      def replace_minmaxes(other)      = minmaxes.replace(other)
      def append_minmax(min, max)      = minmaxes << [min, max]
      def insert_minmax(idx, min, max) = minmaxes.insert idx, [min, max]
      def delete_run_at(idx)           = runs.delete_at(idx)
      def slice_runs!(...)             = runs.slice!(...)
      def truncate_runs!(idx)          = runs.slice!(idx..)

      ######################################################################{{{2
      # Update methods

      def modifying!
        if frozen?
          raise FrozenError, "can't modify frozen #{self.class}: %p" % [self]
        end
      end

      def add_minmaxes(minmaxes)
        minmaxes.each do |minmax|
          add_minmax minmax
        end
        self
      end

      def subtract_minmaxes(minmaxes)
        minmaxes.each do |minmax|
          subtract_minmax minmax
        end
        self
      end

      #
      #   --|=====| |=====new run=======|                 append
      #   ?????????-|=====new run=======|-|===lower===|-- insert
      #
      #             |=====new run=======|
      #   ---------??=======lower=======??--------------- noop
      #
      #   ---------??===lower==|--|==|                    join remaining
      #   ---------??===lower==|--|==|----|===upper===|-- join until upper
      #   ---------??===lower==|--|==|--|=====upper===|-- join to upper
      def add_minmax(minmax)
        modifying!
        min, max   = minmax
        lower_idx  = bsearch_index(min - 1)
        lmin, lmax = min_at(lower_idx), max_at(lower_idx) if lower_idx
        if    lmin.nil?        then append_minmax min, max
        elsif (max + 1) < lmin then insert_minmax lower_idx, min, max
        else  add_coalesced_minmax(lower_idx, lmin, lmax, min, max)
        end
      end

      def add_coalesced_minmax(lower_idx, lmin, lmax, min, max)
        return if lmin <= min && max <= lmax
        set_min_at lower_idx, (lmin = min) if min < lmin
        set_max_at lower_idx, (lmax = max) if lmax < max
        next_idx = lower_idx + 1
        return if next_idx == runs.count
        tmax_adj = lmax + 1
        if (upper_idx = bsearch_index(tmax_adj))
          if tmax_adj < min_at(upper_idx)
            upper_idx -= 1
          else
            set_max_at lower_idx, max_at(upper_idx)
          end
        end
        slice_runs! next_idx..upper_idx
      end

      #         |====subtracted run=======|
      # --|====|                               no more       1. noop
      # --|====|---------------------------|====lower====|-- 2. noop
      # -------|======lower================|---------------- 3. split
      # --------|=====lower================|---------------- 4. trim beginning
      #
      # -------|======lower====????????????----------------- trim lower
      # --------|=====lower====????????????----------------- delete lower
      #
      # -------??=====lower===============|----------------- 5. trim/delete one
      # -------??=====lower====|--|====|       no more       6. delete rest
      # -------??=====lower====|--|====|---|====upper====|-- 7. delete until
      # -------??=====lower====|--|====|--|=====upper====|-- 8. delete and trim
      def subtract_minmax(minmax)
        modifying!
        min, max   = minmax
        idx        = bsearch_index(min)
        lmin, lmax = min_at(idx), max_at(idx) if idx
        if    lmin.nil?  then nil # case 1.
        elsif max < lmin then nil # case 2.
        elsif max < lmax then trim_or_split_minmax  idx, lmin,       min, max
        else                  trim_or_delete_minmax idx, lmin, lmax, min, max
        end
      end

      def trim_or_split_minmax(idx, lmin, tmin, tmax)
        set_min_at idx, tmax + 1
        if lmin < tmin # split
          insert_minmax idx, lmin, tmin - 1
        end
      end

      def trim_or_delete_minmax(lower_idx, lmin, lmax, tmin, tmax)
        if lmin < tmin # trim lower
          lmax = set_max_at lower_idx, tmin - 1
          lower_idx += 1
        end
        if tmax == lmax                                 # case 5
          delete_run_at lower_idx
        elsif (upper_idx = bsearch_index(tmax + 1))
          if min_at(upper_idx) <= tmax                  # case 8
            set_min_at upper_idx, tmax + 1
          end
          slice_runs! lower_idx..upper_idx - 1          # cases 7 and 8
        else                                            # case 6
          truncate_runs! lower_idx
        end
      end

      alias add_runs      add_minmaxes
      alias add_run       add_minmax
      alias subtract_runs subtract_minmaxes
      alias subtract_run  subtract_minmax

      ######################################################################{{{2
      # intentionally defined after the class implementation

      FULL_SET_DATA = [[1, STAR_INT].freeze].freeze
      private_constant :FULL_SET_DATA

      EMPTY = new.freeze
      FULL  = self["1:*"]
      private_constant :EMPTY, :FULL

      # }}}
      # vim:foldmethod=marker
    end
  end
end
