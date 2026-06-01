# frozen_string_literal: true

module Net
  class IMAP < Protocol

    # >>>
    #   *NOTE:* <em>AppendUIDData replaced UIDPlusData for +APPENDUID+ in the
    #   +0.6.0+ release.</em>  To use AppendUIDData before +0.6.0+, set
    #   Config#parser_use_deprecated_uidplus_data to +false+.
    #
    # AppendUIDData represents the ResponseCode#data that accompanies the
    # +APPENDUID+ {response code}[rdoc-ref:ResponseCode].
    #
    # A server that supports +UIDPLUS+ (or +IMAP4rev2+) should send
    # AppendUIDData inside every TaggedResponse returned by the
    # append[rdoc-ref:Net::IMAP#append] command---unless the target mailbox
    # reports +UIDNOTSTICKY+.
    #
    # == Required capability
    # Requires either +UIDPLUS+ [RFC4315[https://www.rfc-editor.org/rfc/rfc4315]]
    # or +IMAP4rev2+ capability.
    class AppendUIDData < Data.define(:uidvalidity, :assigned_uids)
      def initialize(uidvalidity:, assigned_uids:)
        uidvalidity   = Integer(uidvalidity)
        assigned_uids = SequenceSet[assigned_uids]
        NumValidator.ensure_nz_number(uidvalidity)
        if assigned_uids.include_star?
          raise DataFormatError, "uid-set cannot contain '*'"
        end
        super
      end

      ##
      # attr_reader: uidvalidity
      # :call-seq: uidvalidity -> nonzero uint32
      #
      # The UIDVALIDITY of the destination mailbox.

      ##
      # attr_reader: assigned_uids
      #
      # A SequenceSet with the newly assigned UIDs of the appended messages.

      # Returns the number of messages that have been appended.
      def size
        assigned_uids.count_with_duplicates
      end
    end

    # >>>
    #   *NOTE:* <em>CopyUIDData replaced UIDPlusData for +COPYUID+ in the
    #   +0.6.0+ release.</em>  To use CopyUIDData before +0.6.0+, set
    #   Config#parser_use_deprecated_uidplus_data to +false+.
    #
    # CopyUIDData represents the ResponseCode#data that accompanies the
    # +COPYUID+ {response code}[rdoc-ref:ResponseCode].
    #
    # A server that supports +UIDPLUS+ (or +IMAP4rev2+) should send CopyUIDData
    # in response to
    # copy[rdoc-ref:Net::IMAP#copy], {uid_copy}[rdoc-ref:Net::IMAP#uid_copy],
    # move[rdoc-ref:Net::IMAP#copy], and {uid_move}[rdoc-ref:Net::IMAP#uid_move]
    # commands---unless the destination mailbox reports +UIDNOTSTICKY+.
    #
    # Note that copy[rdoc-ref:Net::IMAP#copy] and
    # {uid_copy}[rdoc-ref:Net::IMAP#uid_copy] return CopyUIDData in their
    # TaggedResponse.  But move[rdoc-ref:Net::IMAP#copy] and
    # {uid_move}[rdoc-ref:Net::IMAP#uid_move] _should_ send CopyUIDData in an
    # UntaggedResponse response before sending their TaggedResponse.  However
    # some servers do send CopyUIDData in the TaggedResponse for +MOVE+
    # commands---this complies with the older +UIDPLUS+ specification but is
    # discouraged by the +MOVE+ extension and disallowed by +IMAP4rev2+.
    #
    # == Required capability
    # Requires either +UIDPLUS+ [RFC4315[https://www.rfc-editor.org/rfc/rfc4315]]
    # or +IMAP4rev2+ capability.
    class CopyUIDData < Data.define(:uidvalidity, :source_uids, :assigned_uids)
      def initialize(uidvalidity:, source_uids:, assigned_uids:)
        uidvalidity   = Integer(uidvalidity)
        source_uids   = SequenceSet[source_uids]
        assigned_uids = SequenceSet[assigned_uids]
        NumValidator.ensure_nz_number(uidvalidity)
        if source_uids.include_star? || assigned_uids.include_star?
          raise DataFormatError, "uid-set cannot contain '*'"
        elsif source_uids.count_with_duplicates != assigned_uids.count_with_duplicates
          raise DataFormatError, "mismatched uid-set sizes for %s and %s" % [
            source_uids, assigned_uids
          ]
        end
        super
      end

      ##
      # attr_reader: uidvalidity
      #
      # The +UIDVALIDITY+ of the destination mailbox (a nonzero unsigned 32 bit
      # integer).

      ##
      # attr_reader: source_uids
      #
      # A SequenceSet with the original UIDs of the copied or moved messages.

      ##
      # attr_reader: assigned_uids
      #
      # A SequenceSet with the newly assigned UIDs of the copied or moved
      # messages.

      # Returns the number of messages that have been copied or moved.
      # source_uids and the assigned_uids will both the same number of UIDs.
      def size
        assigned_uids.count_with_duplicates
      end

      # :call-seq:
      #   assigned_uid_for(source_uid) -> uid
      #   self[source_uid] -> uid
      #
      # Returns the UID in the destination mailbox for the message that was
      # copied from +source_uid+ in the source mailbox.
      #
      # This is the reverse of #source_uid_for.
      #
      # Related: source_uid_for, each_uid_pair, uid_mapping
      def assigned_uid_for(source_uid)
        idx = source_uids.find_ordered_index(source_uid) and
          assigned_uids.ordered_at(idx)
      end
      alias :[] :assigned_uid_for

      # :call-seq:
      #   source_uid_for(assigned_uid) -> uid
      #
      # Returns the UID in the source mailbox for the message that was copied to
      # +assigned_uid+ in the source mailbox.
      #
      # This is the reverse of #assigned_uid_for.
      #
      # Related: assigned_uid_for, each_uid_pair, uid_mapping
      def source_uid_for(assigned_uid)
        idx = assigned_uids.find_ordered_index(assigned_uid) and
          source_uids.ordered_at(idx)
      end

      # Yields a pair of UIDs for each copied message.  The first is the
      # message's UID in the source mailbox and the second is the UID in the
      # destination mailbox.
      #
      # Returns an enumerator when no block is given.
      #
      # Please note the warning on uid_mapping before calling methods like
      # +to_h+ or +to_a+ on the returned enumerator.
      #
      # Related: uid_mapping, assigned_uid_for, source_uid_for
      def each_uid_pair
        return enum_for(__method__) unless block_given?
        source_uids.each_ordered_number.lazy
          .zip(assigned_uids.each_ordered_number.lazy) do
            |source_uid, assigned_uid|
            yield source_uid, assigned_uid
          end
      end
      alias each_pair each_uid_pair
      alias each      each_uid_pair

      # :call-seq: uid_mapping -> hash
      #
      # Returns a hash mapping each source UID to the newly assigned destination
      # UID.
      #
      # <em>*Warning:*</em> The hash that is created may consume _much_ more
      # memory than the data used to create it.  When handling responses from an
      # untrusted server, check #size before calling this method.
      #
      # Related: each_uid_pair, assigned_uid_for, source_uid_for
      def uid_mapping
        each_uid_pair.to_h
      end

    end

  end
end
