# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # Net::IMAP::VanishedData represents the contents of a +VANISHED+ response,
    # which is described by the
    # {QRESYNC}[https://www.rfc-editor.org/rfc/rfc7162.html] extension.
    # [{RFC7162 §3.2.10}[https://www.rfc-editor.org/rfc/rfc7162.html#section-3.2.10]].
    #
    # +VANISHED+ responses replace +EXPUNGE+ responses when either the
    # {QRESYNC}[https://www.rfc-editor.org/rfc/rfc7162.html] or the
    # {UIDONLY}[https://www.rfc-editor.org/rfc/rfc9586.html] extension has been
    # enabled.
    class VanishedData < Data.define(:uids, :earlier)

      # Returns a new VanishedData object.
      #
      # * +uids+ will be converted by SequenceSet.[].
      # * +earlier+ will be converted to +true+ or +false+
      def initialize(uids:, earlier:)
        uids    = SequenceSet[uids] unless uids.equal? SequenceSet.empty
        earlier = !!earlier
        super
      end

      ##
      # :attr_reader: uids
      #
      # SequenceSet of UIDs that have been permanently removed from the mailbox.

      ##
      # :attr_reader: earlier
      #
      # +true+ when the response was caused by Net::IMAP#uid_fetch with
      # <tt>vanished: true</tt> or Net::IMAP#select/Net::IMAP#examine with
      # <tt>qresync: true</tt>.
      #
      # +false+ when the response is used to announce message removals within an
      # already selected mailbox.

      # rdoc doesn't handle attr aliases nicely. :(
      alias earlier? earlier # :nodoc:
      ##
      # :attr_reader: earlier?
      #
      # Alias for #earlier.

      # Returns an Array of all of the UIDs in #uids.
      #
      # See SequenceSet#numbers.
      def to_a; uids.numbers end

      # Yields each UID in #uids and returns +self+.  Returns an Enumerator when
      # no block is given.
      #
      # See SequenceSet#each_number.
      def each(&)
        return to_enum unless block_given?
        uids.each_number(&)
        self
      end
    end
  end
end
