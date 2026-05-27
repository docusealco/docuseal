# frozen_string_literal: true

module Net
  class IMAP
    # An "extended search" response (+ESEARCH+).  ESearchResult should be
    # returned (instead of SearchResult) by IMAP#search, IMAP#uid_search,
    # IMAP#sort, and IMAP#uid_sort under any of the following conditions:
    #
    # * Return options were specified for IMAP#search or IMAP#uid_search.
    #   The server must support a search extension which allows
    #   RFC4466[https://www.rfc-editor.org/rfc/rfc4466.html] +return+ options,
    #   such as +ESEARCH+, +PARTIAL+, or +IMAP4rev2+.
    # * Return options were specified for IMAP#sort or IMAP#uid_sort.
    #   The server must support the +ESORT+ extension
    #   {[RFC5267]}[https://www.rfc-editor.org/rfc/rfc5267.html#section-3].
    #
    #   *NOTE:* IMAP#search and IMAP#uid_search do not support +ESORT+ yet.
    # * The server supports +IMAP4rev2+ but _not_ +IMAP4rev1+, or +IMAP4rev2+
    #   has been enabled.  +IMAP4rev2+ requires +ESEARCH+ results.
    #
    # Note that some servers may claim to support a search extension which
    # requires an +ESEARCH+ result, such as +PARTIAL+, but still only return a
    # +SEARCH+ result when +return+ options are specified.
    #
    # Some search extensions may result in the server sending ESearchResult
    # responses after the initiating command has completed.  Use
    # IMAP#add_response_handler to handle these responses.
    #
    # ==== Compatibility with SearchResult
    #
    # Note that both SearchResult and ESearchResult implement +each+, +to_a+,
    # and +to_sequence_set+.  These methods can be used regardless of whether
    # the server returns +SEARCH+ or +ESEARCH+ data (or no data).
    class ESearchResult < Data.define(:tag, :uid, :data)
      def initialize(tag: nil, uid: nil, data: nil)
        tag  => String       | nil; tag = -tag if tag
        uid  => true | false | nil; uid = !!uid
        data => Array        | nil; data ||= []; data.freeze
        super
      end

      # :call-seq: to_a -> Array of integers
      #
      # When either #all or #partial contains a SequenceSet of message sequence
      # numbers or UIDs, +to_a+ returns that set as an array of integers.
      #
      # When both #all and #partial are +nil+, either because the server
      # returned no results or because neither +ALL+ or +PARTIAL+ were included
      # in the IMAP#search +RETURN+ options, #to_a returns an empty array.
      #
      # Note that SearchResult also implements +to_a+, so it can be used without
      # checking if the server returned +SEARCH+ or +ESEARCH+ data.
      #
      # Related: #each, #to_sequence_set, #all, #partial
      def to_a; to_sequence_set.numbers end

      # :call-seq: to_sequence_set -> SequenceSet or nil
      #
      # When either #all or #partial contains a SequenceSet of message sequence
      # numbers or UIDs, +to_sequence_set+ returns that sequence set.
      #
      # When both #all and #partial are +nil+, either because the server
      # returned no results or because neither +ALL+ or +PARTIAL+ were included
      # in the IMAP#search +RETURN+ options, #to_sequence_set returns
      # SequenceSet.empty.
      #
      # Note that SearchResult also implements +to_sequence_set+, so it can be
      # used without checking if the server returned +SEARCH+ or +ESEARCH+ data.
      #
      # Related: #each, #to_a, #all, #partial
      def to_sequence_set
        all || partial&.to_sequence_set || SequenceSet.empty
      end

      # When either #all or #partial contains a SequenceSet of message sequence
      # numbers or UIDs, +each+ yields each integer in the set.
      #
      # When both #all and #partial are +nil+, either because the server
      # returned no results or because +ALL+ and +PARTIAL+ were not included in
      # the IMAP#search +RETURN+ options, #each does not yield.
      #
      # Note that SearchResult also implements +#each+, so it can be used
      # without checking if the server returned +SEARCH+ or +ESEARCH+ data.
      #
      # Related: #to_sequence_set, #to_a, #all, #partial
      def each(&)
        return to_enum(__callee__) unless block_given?
        to_sequence_set.each_number(&)
        self
      end

      ##
      # attr_reader: tag
      #
      # The tag string for the command that caused this response to be returned.
      #
      # When +nil+, this response was not caused by a particular command.

      ##
      # attr_reader: uid
      #
      # Indicates whether #data in this response refers to UIDs (when +true+) or
      # to message sequence numbers (when +false+).

      ##
      alias uid? uid

      ##
      # attr_reader: data
      #
      # Search return data, as an array of <tt>[name, value]</tt> pairs.  Most
      # return data corresponds to a search +return+ option with the same name.
      #
      # Note that some return data names may be used more than once per result.
      #
      # This data can be more simply retrieved by #min, #max, #all, #count,
      # #modseq, and other methods.

      # :call-seq: min -> integer or nil
      #
      # The lowest message number/UID that satisfies the SEARCH criteria.
      #
      # Returns +nil+ when the associated search command has no results, or when
      # the +MIN+ return option wasn't specified.
      #
      # Requires +ESEARCH+ {[RFC4731]}[https://www.rfc-editor.org/rfc/rfc4731.html#section-3.1] or
      # +IMAP4rev2+ {[RFC9051]}[https://www.rfc-editor.org/rfc/rfc9051.html#section-7.3.4].
      def min;        data.assoc("MIN")&.last        end

      # :call-seq: max -> integer or nil
      #
      # The highest message number/UID that satisfies the SEARCH criteria.
      #
      # Returns +nil+ when the associated search command has no results, or when
      # the +MAX+ return option wasn't specified.
      #
      # Requires +ESEARCH+ {[RFC4731]}[https://www.rfc-editor.org/rfc/rfc4731.html#section-3.1] or
      # +IMAP4rev2+ {[RFC9051]}[https://www.rfc-editor.org/rfc/rfc9051.html#section-7.3.4].
      def max;        data.assoc("MAX")&.last        end

      # :call-seq: all -> sequence set or nil
      #
      # A SequenceSet containing all message sequence numbers or UIDs that
      # satisfy the SEARCH criteria.
      #
      # Returns +nil+ when the associated search command has no results, or when
      # the +ALL+ return option was not specified but other return options were.
      #
      # Requires +ESEARCH+ {[RFC4731]}[https://www.rfc-editor.org/rfc/rfc4731.html#section-3.1] or
      # +IMAP4rev2+ {[RFC9051]}[https://www.rfc-editor.org/rfc/rfc9051.html#section-7.3.4].
      #
      # See also: #to_a
      def all;        data.assoc("ALL")&.last        end

      # :call-seq: count -> integer or nil
      #
      # Returns the number of messages that satisfy the SEARCH criteria.
      #
      # Returns +nil+ when the associated search command has no results, or when
      # the +COUNT+ return option wasn't specified.
      #
      # Requires +ESEARCH+ {[RFC4731]}[https://www.rfc-editor.org/rfc/rfc4731.html#section-3.1] or
      # +IMAP4rev2+ {[RFC9051]}[https://www.rfc-editor.org/rfc/rfc9051.html#section-7.3.4].
      def count;      data.assoc("COUNT")&.last      end

      # :call-seq: modseq -> integer or nil
      #
      # The highest +mod-sequence+ of all messages being returned.
      #
      # Returns +nil+ when the associated search command has no results, or when
      # the +MODSEQ+ search criterion wasn't specified.
      #
      # Note that there is no search +return+ option for +MODSEQ+.  It will be
      # returned whenever the +CONDSTORE+ extension has been enabled.  Using the
      # +MODSEQ+ search criteria will implicitly enable +CONDSTORE+.
      #
      # Requires +CONDSTORE+ {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html]
      # and +ESEARCH+ {[RFC4731]}[https://www.rfc-editor.org/rfc/rfc4731.html#section-3.2].
      def modseq;     data.assoc("MODSEQ")&.last     end

      # Returned by ESearchResult#partial.
      #
      # Requires +PARTIAL+ {[RFC9394]}[https://www.rfc-editor.org/rfc/rfc9394.html]
      # or <tt>CONTEXT=SEARCH</tt>/<tt>CONTEXT=SORT</tt>
      # {[RFC5267]}[https://www.rfc-editor.org/rfc/rfc5267.html]
      #
      # See also: #to_a
      class PartialResult < Data.define(:range, :results)
        def initialize(range:, results:)
          range   => Range
          results = SequenceSet[results] unless results.nil?
          super
        end

        ##
        # method: range
        # :call-seq: range -> range

        ##
        # method: results
        # :call-seq: results -> sequence set or nil

        # Converts #results to an array of integers.
        #
        # See also: ESearchResult#to_a.
        def to_a; results&.numbers || [] end

        alias to_sequence_set results
      end

      # :call-seq: partial -> PartialResult or nil
      #
      # A PartialResult containing a subset of the message sequence numbers or
      # UIDs that satisfy the SEARCH criteria.
      #
      # Requires +PARTIAL+ {[RFC9394]}[https://www.rfc-editor.org/rfc/rfc9394.html]
      # or <tt>CONTEXT=SEARCH</tt>/<tt>CONTEXT=SORT</tt>
      # {[RFC5267]}[https://www.rfc-editor.org/rfc/rfc5267.html]
      #
      # See also: #to_a
      def partial;    data.assoc("PARTIAL")&.last    end

    end
  end
end
