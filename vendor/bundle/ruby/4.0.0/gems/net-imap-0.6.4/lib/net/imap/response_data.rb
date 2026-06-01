# frozen_string_literal: true

module Net
  class IMAP < Protocol
    autoload :ESearchResult,    "#{__dir__}/esearch_result"
    autoload :FetchData,        "#{__dir__}/fetch_data"
    autoload :UIDFetchData,     "#{__dir__}/fetch_data"
    autoload :SearchResult,     "#{__dir__}/search_result"
    autoload :AppendUIDData,    "#{__dir__}/uidplus_data"
    autoload :CopyUIDData,      "#{__dir__}/uidplus_data"
    autoload :VanishedData,     "#{__dir__}/vanished_data"

    # Net::IMAP::ContinuationRequest represents command continuation requests.
    #
    # The command continuation request response is indicated by a "+" token
    # instead of a tag.  This form of response indicates that the server is
    # ready to accept the continuation of a command from the client.  The
    # remainder of this response is a line of text.
    #
    class ContinuationRequest < Struct.new(:data, :raw_data)
      ##
      # method: data
      # :call-seq: data -> ResponseText
      #
      # Returns a ResponseText object

      ##
      # method: raw_data
      # :call-seq: raw_data -> string
      #
      # the raw response data
    end

    # Net::IMAP::UntaggedResponse represents untagged responses.
    #
    # Data transmitted by the server to the client and status responses
    # that do not indicate command completion are prefixed with the token
    # <tt>"*"</tt>, and are called untagged responses.
    #
    class UntaggedResponse < Struct.new(:name, :data, :raw_data)
      ##
      # method: name
      # :call-seq: name -> string
      #
      # The uppercase response name, e.g. "FLAGS", "LIST", "FETCH", etc.

      ##
      # method: data
      # :call-seq: data -> object or nil
      #
      # The parsed response data, e.g: an array of flag symbols, an array of
      # capabilities strings, a ResponseText object, a MailboxList object, a
      # FetchData object, a Namespaces object, etc.  The response #name
      # determines what form the data can take.

      ##
      # method: raw_data
      # :call-seq: raw_data -> string
      #
      # The raw response data.
    end

    # Net::IMAP::IgnoredResponse represents intentionally ignored responses.
    #
    # This includes untagged response "NOOP" sent by e.g. Zimbra to avoid
    # some clients to close the connection.
    #
    # It matches no IMAP standard.
    class IgnoredResponse < UntaggedResponse
    end

    # **Note:** This represents an intentionally _unstable_ API.  Where
    # instances of this class are returned, future releases may return a
    # different (incompatible) object <em>without deprecation or warning</em>.
    #
    # Net::IMAP::UnparsedData represents data for unknown response types or
    # unknown extensions to response types without a well-defined extension
    # grammar.  UnparsedData represents the portion of the response which the
    # parser has skipped over, without attempting to parse it.
    #
    #    parser = Net::IMAP::ResponseParser.new
    #    response = parser.parse "* X-UNKNOWN-TYPE can't parse this\r\n"
    #    response => Net::IMAP::UntaggedResponse(
    #      name: "X-UNKNOWN-TYPE",
    #      data: Net::IMAP::UnparsedData(unparsed_data: "can't parse this"),
    #    )
    #
    # See also: UnparsedNumericResponseData, ExtensionData, IgnoredResponse,
    # InvalidParseData.
    class UnparsedData < Struct.new(:unparsed_data)
      ##
      # method: unparsed_data
      # :call-seq: unparsed_data -> string
      #
      # The unparsed data
    end

    # **Note:** This represents an intentionally _unstable_ API.  Where
    # instances of this class are returned, future releases may return a
    # different (incompatible) object <em>without deprecation or warning</em>.
    #
    # When the response parser encounters a recoverable error,
    # Net::IMAP::InvalidParseData represents that portion of the response which
    # could not be parsed, allowing the parser to parse the remainder of the
    # response.  InvalidParseData is always associated with a ResponseParseError
    # which has been rescued.
    #
    # This could be caused by a malformed server response, by a bug in
    # Net::IMAP::ResponseParser, or by an unsupported extension to the response
    # syntax.  For example, if a server supports +UIDPLUS+, but sends an invalid
    # +COPYUID+ response code:
    #
    #    parser = Net::IMAP::ResponseParser.new
    #    parsed = parser.parse "* OK [COPYUID 701  ] copied one message\r\n"
    #    parsed => {
    #      data: Net::IMAP::ResponseText(
    #        code: Net::IMAP::ResponseCode(
    #          name: "COPYUID",
    #          data: Net::IMAP::InvalidParseData(
    #            parse_error: Net::IMAP::ResponseParseError,
    #            unparsed_data: "701  ",
    #            parsed_data: nil,
    #          )
    #        )
    #      )
    #    }
    #
    # In this example, although <tt>[COPYUID 701  ]</tt> uses valid syntax for a
    # _generic_ ResponseCode, it is _invalid_ syntax for a +COPYUID+ response
    # code.
    #
    # See also: UnparsedData, ExtensionData
    class InvalidParseData < Data.define(:parse_error, :unparsed_data, :parsed_data)
      ##
      # method: parse_error
      # :call-seq: parse_error -> ResponseParseError
      #
      # Returns the rescued ResponseParseError.

      ##
      # method: unparsed_data
      # :call-seq: unparsed_data -> string
      #
      # Returns the raw string which was skipped over by the parser.

      ##
      # method: parsed_data
      #
      # May return a partial parse result for unparsed_data, which had already
      # been parsed before the parse_error.
    end

    # **Note:** This represents an intentionally _unstable_ API.  Where
    # instances of this class are returned, future releases may return a
    # different (incompatible) object <em>without deprecation or warning</em>.
    #
    # Net::IMAP::UnparsedNumericResponseData represents data for unhandled
    # response types with a numeric prefix.  See the documentation for #number.
    #
    #    parser = Net::IMAP::ResponseParser.new
    #    response = parser.parse "* 123 X-UNKNOWN-TYPE can't parse this\r\n"
    #    response => Net::IMAP::UntaggedResponse(
    #      name: "X-UNKNOWN-TYPE",
    #      data: Net::IMAP::UnparsedNumericData(
    #        number: 123,
    #        unparsed_data: "can't parse this"
    #      ),
    #    )
    #
    # See also: UnparsedData, ExtensionData, IgnoredResponse, InvalidParseData
    class UnparsedNumericResponseData < Struct.new(:number, :unparsed_data)
      ##
      # method: number
      # :call-seq: number -> integer
      #
      # Returns a numeric response data prefix, when available.
      #
      # Many response types are prefixed with a non-negative #number.  For
      # message data, #number may represent a sequence number or a UID.  For
      # mailbox data, #number may represent a message count.

      ##
      # method: unparsed_data
      # :call-seq: unparsed_data -> string
      #
      # The unparsed data, not including #number or UntaggedResponse#name.
    end

    # **Note:** This represents an intentionally _unstable_ API.  Where
    # instances of this class are returned, future releases may return a
    # different (incompatible) object <em>without deprecation or warning</em>.
    #
    # Net::IMAP::ExtensionData represents data that is parsable according to the
    # forward-compatible extension syntax in RFC3501, RFC4466, or RFC9051, but
    # isn't directly known or understood by Net::IMAP yet.
    #
    # See also: UnparsedData, UnparsedNumericResponseData, IgnoredResponse
    class ExtensionData < Struct.new(:data)
      ##
      # method: data
      # :call-seq: data -> string
      #
      # The parsed extension data.
    end

    # Net::IMAP::TaggedResponse represents tagged responses.
    #
    # The server completion result response indicates the success or
    # failure of the operation.  It is tagged with the same tag as the
    # client command which began the operation.
    #
    class TaggedResponse < Struct.new(:tag, :name, :data, :raw_data)
      ##
      # method: tag
      # :call-seq: tag -> string
      #
      # Returns the command tag

      ##
      # method: name
      # :call-seq: name -> string
      #
      # Returns the name, one of "OK", "NO", or "BAD".

      ##
      # method: data
      # :call-seq: data -> ResponseText
      #
      # Returns a ResponseText object

      ##
      # method: raw_data
      # :call-seq: raw_data -> string
      #
      # The raw response data.
    end

    # ResponseText represents texts of responses.
    #
    # The text may be prefixed by a ResponseCode.
    #
    # ResponseText is returned from TaggedResponse#data or
    # UntaggedResponse#data for
    # {"status responses"}[https://www.rfc-editor.org/rfc/rfc3501#section-7.1]:
    # * every TaggedResponse, name[rdoc-ref:TaggedResponse#name] is always
    #   "+OK+", "+NO+", or "+BAD+".
    # * any UntaggedResponse when name[rdoc-ref:UntaggedResponse#name] is
    #   "+OK+", "+NO+", "+BAD+", "+PREAUTH+", or "+BYE+".
    #
    # Note that these "status responses" are confusingly _not_ the same as the
    # +STATUS+ UntaggedResponse (see IMAP#status and StatusData).
    class ResponseText < Struct.new(:code, :text)
      # Used to avoid an allocation when ResponseText is empty
      EMPTY = new(nil, "").freeze

      ##
      # method: code
      # :call-seq: code -> ResponseCode or nil
      #
      # Returns a ResponseCode, if the response contains one

      ##
      # method: text
      # :call-seq: text -> string
      #
      # Returns the response text, not including any response code
    end

    # ResponseCode represents an \IMAP response code, which can be retrieved
    # from ResponseText#code for
    # {"status responses"}[https://www.rfc-editor.org/rfc/rfc3501#section-7.1]:
    # * every TaggedResponse, name[rdoc-ref:TaggedResponse#name] is always
    #   "+OK+", "+NO+", or "+BAD+".
    # * any UntaggedResponse when name[rdoc-ref:UntaggedResponse#name] is
    #   "+OK+", "+NO+", "+BAD+", "+PREAUTH+", or "+BYE+".
    #
    # Note that these "status responses" are confusingly _not_ the same as the
    # +STATUS+ UntaggedResponse (see IMAP#status and StatusData).
    #
    # Some response codes come with additional data which will be parsed by
    # Net::IMAP.  Others return +nil+ for #data, but are used as a
    # machine-readable annotation for the human-readable ResponseText#text in
    # the same response.
    #
    # Untagged response code #data is pushed directly onto Net::IMAP#responses,
    # keyed by #name, unless it is removed by the command that generated it.
    # Use Net::IMAP#add_response_handler to view tagged response codes for
    # command methods that do not return their TaggedResponse.
    #
    # == Standard response codes
    #
    # \IMAP extensions may define new codes and the data that comes with them.
    # The IANA {IMAP Response
    # Codes}[https://www.iana.org/assignments/imap-response-codes/imap-response-codes.xhtml]
    # registry has links to specifications for all standard response codes.
    #
    # === +IMAP4rev1+ response codes
    # See [IMAP4rev1[https://www.rfc-editor.org/rfc/rfc3501]] {§7.1, "Server
    # Responses - Status
    # Responses"}[https://www.rfc-editor.org/rfc/rfc3501#section-7.1] for full
    # definitions of the basic set of IMAP4rev1 response codes:
    # * +ALERT+, the ResponseText#text contains a special alert that MUST be
    #   brought to the user's attention.
    # * +BADCHARSET+, #data will be an array of charset strings, or +nil+.
    # * +CAPABILITY+, #data will be an array of capability strings.
    # * +PARSE+, the ResponseText#text presents an error parsing a message's
    #   \[RFC5322] or [MIME-IMB] headers.
    # * +PERMANENTFLAGS+, followed by an array of flags.  System flags will be
    #   symbols, and keyword flags will be strings.  See
    #   rdoc-ref:Net::IMAP@System+flags
    # * +READ-ONLY+, the mailbox was selected read-only, or changed to read-only
    # * +READ-WRITE+, the mailbox was selected read-write, or changed to
    #   read-write
    # * +TRYCREATE+, when #append or #copy fail because the target mailbox
    #   doesn't exist.
    # * +UIDNEXT+, #data is an Integer, the next UID value of the mailbox.  See
    #   [{IMAP4rev1}[https://www.rfc-editor.org/rfc/rfc3501]],
    #   {§2.3.1.1, "Unique Identifier (UID) Message
    #   Attribute}[https://www.rfc-editor.org/rfc/rfc3501#section-2.3.1.1].
    # * +UIDVALIDITY+, #data is an Integer, the UID validity value of the
    #   mailbox.  See [{IMAP4rev1}[https://www.rfc-editor.org/rfc/rfc3501]],
    #   {§2.3.1.1, "Unique Identifier (UID) Message
    #   Attribute}[https://www.rfc-editor.org/rfc/rfc3501#section-2.3.1.1].
    # * +UNSEEN+, #data is an Integer, the number of messages which do not have
    #   the <tt>\Seen</tt> flag set.
    #   <em>DEPRECATED by IMAP4rev2.</em>
    #
    # === +BINARY+ extension
    # See {[RFC3516]}[https://www.rfc-editor.org/rfc/rfc3516].
    # * +UNKNOWN-CTE+, with a tagged +NO+ response, when the server does not
    #   known how to decode a CTE (content-transfer-encoding).  #data is +nil+.
    #   See IMAP#fetch.
    #
    # === +UIDPLUS+ extension
    # See {[RFC4315 §3]}[https://www.rfc-editor.org/rfc/rfc4315#section-3].
    # * +APPENDUID+, #data is AppendUIDData.  See IMAP#append.
    # * +COPYUID+, #data is CopyUIDData.  See IMAP#copy.
    # * +UIDNOTSTICKY+, #data is +nil+.  See IMAP#select.
    #
    # === +SEARCHRES+ extension
    # See {[RFC5182]}[https://www.rfc-editor.org/rfc/rfc5182].
    # * +NOTSAVED+, with a tagged +NO+ response, when the search result variable
    #   is not saved.  #data is +nil+.
    #
    # === +RFC5530+ response codes
    # See {[RFC5530]}[https://www.rfc-editor.org/rfc/rfc5530], "IMAP Response
    # Codes" for the definition of the following response codes, which are all
    # machine-readable annotations for the human-readable ResponseText#text, and
    # have +nil+ #data of their own:
    # * +UNAVAILABLE+
    # * +AUTHENTICATIONFAILED+
    # * +AUTHORIZATIONFAILED+
    # * +EXPIRED+
    # * +PRIVACYREQUIRED+
    # * +CONTACTADMIN+
    # * +NOPERM+
    # * +INUSE+
    # * +EXPUNGEISSUED+
    # * +CORRUPTION+
    # * +SERVERBUG+
    # * +CLIENTBUG+
    # * +CANNOT+
    # * +LIMIT+
    # * +OVERQUOTA+
    # * +ALREADYEXISTS+
    # * +NONEXISTENT+
    #
    # === +QRESYNC+ extension
    # See {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
    # * +CLOSED+, returned when the currently selected mailbox is closed
    #   implicitly by selecting or examining another mailbox.  #data is +nil+.
    #
    # === +IMAP4rev2+ response codes
    # See {[RFC9051]}[https://www.rfc-editor.org/rfc/rfc9051] {§7.1, "Server
    # Responses - Status
    # Responses"}[https://www.rfc-editor.org/rfc/rfc9051#section-7.1] for full
    # descriptions of IMAP4rev2 response codes.  IMAP4rev2 includes all of the
    # response codes listed above (except "+UNSEEN+") and adds the following:
    # * +HASCHILDREN+, with a tagged +NO+ response, when a mailbox delete failed
    #   because the server doesn't allow deletion of mailboxes with children.
    #   #data is +nil+.
    #
    # === <tt>QUOTA=RES-*</tt> response codes
    # See {[RFC9208]}[https://www.rfc-editor.org/rfc/rfc9208.html#section-4.3].
    # * +OVERQUOTA+ (also in RFC5530[https://www.rfc-editor.org/rfc/rfc5530]),
    #   with a tagged +NO+ response to an +APPEND+/+COPY+/+MOVE+ command when
    #   the command would put the target mailbox over any quota, and with an
    #   untagged +NO+ when a mailbox exceeds a soft quota (which may be caused
    #   be external events).  #data is +nil+.
    #
    # === +CONDSTORE+ extension
    # See {[RFC7162]}[https://www.rfc-editor.org/rfc/rfc7162.html].
    # * +NOMODSEQ+, when selecting a mailbox that does not support
    #   mod-sequences.  #data is +nil+.  See IMAP#select.
    # * +HIGHESTMODSEQ+, #data is an Integer, the highest mod-sequence value of
    #   all messages in the mailbox.  See IMAP#select.
    # * +MODIFIED+, #data is a SequenceSet, the messages that have been modified
    #   since the +UNCHANGEDSINCE+ mod-sequence given to +STORE+ or <tt>UID
    #   STORE</tt>.
    #
    # === +OBJECTID+ extension
    # See {[RFC8474]}[https://www.rfc-editor.org/rfc/rfc8474.html].
    # * +MAILBOXID+, #data is a string
    #
    # == Extension compatibility
    #
    # Response codes are backwards compatible:  Servers are allowed to send new
    # response codes even if the client has not enabled the extension that
    # defines them.  When ResponseParser does not know how to parse the response
    # code data, #data may return the unparsed string, ExtensionData, or
    # UnparsedData.  When ResponseParser attempts but fails to parse the
    # response code data, #data returns InvalidParseData.
    class ResponseCode < Struct.new(:name, :data)
      ##
      # method: name
      # :call-seq: name -> string
      #
      # Returns the response code name, such as "ALERT", "PERMANENTFLAGS", or
      # "UIDVALIDITY".

      ##
      # method: data
      # :call-seq: data -> object or nil
      #
      # Returns the parsed response code data, e.g: an array of capabilities
      # strings, an array of character set strings, a list of permanent flags,
      # an Integer, etc.  The response #name determines what form the response
      # code #data can take.
      #
      # When ResponseParser does not know how to parse the response code data,
      # #data may return the unparsed string, ExtensionData, or UnparsedData.
      # When ResponseParser attempts but fails to parse the response code data,
      # #data returns InvalidParseData.
    end

    # MailboxList represents the data of an untagged +LIST+ response, for a
    # _single_ mailbox path.  IMAP#list returns an array of MailboxList objects.
    #
    class MailboxList < Struct.new(:attr, :delim, :name)
      ##
      # method: attr
      # :call-seq: attr -> array of Symbols
      #
      # Returns the name attributes. Each name attribute is a symbol capitalized
      # by String#capitalize, such as :Noselect (not :NoSelect).  For the
      # semantics of each attribute, see:
      # * Net::IMAP@Basic+Mailbox+Attributes
      # * Net::IMAP@Mailbox+role+Attributes
      # * The IANA {IMAP Mailbox Name Attributes
      #   registry}[https://www.iana.org/assignments/imap-mailbox-name-attributes/imap-mailbox-name-attributes.xhtml]
      #   has links to specifications for all standard mailbox attributes.

      ##
      # method: delim
      # :call-seq: delim -> single character string
      #
      # Returns the hierarchy delimiter for the mailbox path.

      ##
      # method: name
      # :call-seq: name -> string
      #
      # Returns the mailbox name.
    end

    # MailboxQuota represents the data of an untagged +QUOTA+ response.
    #
    # IMAP#getquota returns an array of MailboxQuota objects.
    #
    # Net::IMAP#getquotaroot returns an array containing both MailboxQuotaRoot
    # and MailboxQuota objects.
    #
    # == Required capability
    #
    # Requires +QUOTA+ [RFC2087[https://www.rfc-editor.org/rfc/rfc2087]]
    # or <tt>QUOTA=RES-STORAGE</tt>
    # [RFC9208[https://www.rfc-editor.org/rfc/rfc9208]] capability.
    class MailboxQuota < Struct.new(:mailbox, :usage, :quota)
      ##
      # method: mailbox
      # :call-seq: mailbox -> string
      #
      # The quota root with the associated quota.
      #
      # NOTE: this was mistakenly named "mailbox".  But the quota root's name may
      # differ from the mailbox.  A single quota root may cover multiple
      # mailboxes, and a single mailbox may be governed by multiple quota roots.

      # The quota root with the associated quota.
      alias quota_root mailbox

      ##
      # method: usage
      # :call-seq: usage -> Integer
      #
      # Current storage usage of the mailbox.

      ##
      # method: quota
      # :call-seq: quota -> Integer
      #
      # Storage limit imposed on the mailbox.
      #
    end

    # MailboxQuotaRoot represents the data of an untagged +QUOTAROOT+ response.
    #
    # IMAP#getquotaroot returns an array containing both MailboxQuotaRoot and
    # MailboxQuota objects.
    #
    # == Required capability
    # Requires +QUOTA+ [RFC2087[https://www.rfc-editor.org/rfc/rfc2087]]
    # capability.
    class MailboxQuotaRoot < Struct.new(:mailbox, :quotaroots)
      ##
      # method: mailbox
      # :call-seq: mailbox -> string
      #
      # The mailbox with the associated quota.

      ##
      # method: mailbox
      # :call-seq: quotaroots -> array of strings
      #
      # Zero or more quotaroots that affect the quota on the specified mailbox.
    end

    # MailboxACLItem represents the data of an untagged +ACL+ response.
    #
    # IMAP#getacl returns an array of MailboxACLItem objects.
    #
    # == Required capability
    # Requires +ACL+ [RFC4314[https://www.rfc-editor.org/rfc/rfc4314]]
    # capability.
    class MailboxACLItem < Struct.new(:user, :rights, :mailbox)
      ##
      # method: mailbox
      # :call-seq: mailbox -> string
      #
      # The mailbox to which the indicated #user has the specified #rights.

      ##
      # method: user
      # :call-seq: user -> string
      #
      # Login name that has certain #rights to the #mailbox that was specified
      # with the getacl command.

      ##
      # method: rights
      # :call-seq: rights -> string
      #
      # The access rights the indicated #user has to the #mailbox.
    end

    # Namespace represents a _single_ namespace, contained inside a Namespaces
    # object.
    #
    # == Required capability
    # Requires either +NAMESPACE+ [RFC2342[https://www.rfc-editor.org/rfc/rfc2342]]
    # or +IMAP4rev2+ capability.
    class Namespace < Struct.new(:prefix, :delim, :extensions)
      ##
      # method: prefix
      # :call-seq: prefix -> string
      #
      # Returns the namespace prefix string.

      ##
      # method: delim
      # :call-seq: delim -> single character string or nil
      #
      # Returns a hierarchy delimiter character, if it exists.

      ##
      # method: extensions
      # :call-seq: extensions -> Hash[String, Array[String]]
      #
      # A hash of parameters mapped to arrays of strings, for extensibility.
      # Extension parameter semantics would be defined by the extension.
    end

    # Namespaces represents the data of an untagged +NAMESPACE+ response,
    # returned by IMAP#namespace.
    #
    # Contains lists of #personal, #shared, and #other namespaces.
    #
    # == Required capability
    # Requires either +NAMESPACE+ [RFC2342[https://www.rfc-editor.org/rfc/rfc2342]]
    # or +IMAP4rev2+ capability.
    class Namespaces < Struct.new(:personal, :other, :shared)
      ##
      # method: personal
      # :call-seq: personal -> array of Namespace
      #
      # Returns an array of Personal Namespace objects.

      ##
      # method: other
      # :call-seq: other -> array of Namespace
      #
      # Returns an array of Other Users' Namespace objects.

      ##
      # method: shared
      # :call-seq: shared -> array of Namespace
      #
      # Returns an array of Shared Namespace objects.
    end

    # StatusData represents the contents of an untagged +STATUS+ response.
    #
    # IMAP#status returns the contents of #attr.
    class StatusData < Struct.new(:mailbox, :attr)
      ##
      # method: mailbox
      # :call-seq: mailbox -> string
      #
      # The mailbox name.

      ##
      # method: attr
      # :call-seq: attr -> Hash[String, Integer]
      #
      # A hash.  Each key is one of "MESSAGES", "RECENT", "UIDNEXT",
      # "UIDVALIDITY", "UNSEEN". Each value is a number.
    end

    # Net::IMAP::Envelope represents envelope structures of messages.
    #
    # [Note]
    #   When the #sender and #reply_to fields are absent or empty, they will
    #   return the same value as #from.  Also, fields may return values that are
    #   invalid for well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
    #   messages when the message is malformed or a draft message.
    #
    # See [{IMAP4rev1 §7.4.2}[https://www.rfc-editor.org/rfc/rfc3501#section-7.4.2]]
    # and [{IMAP4rev2 §7.5.2}[https://www.rfc-editor.org/rfc/rfc9051#section-7.5.2]]
    # for full description of the envelope fields, and
    # Net::IMAP@Message+envelope+and+body+structure for other relevant RFCs.
    #
    # Returned by FetchData#envelope
    class Envelope < Struct.new(:date, :subject, :from, :sender, :reply_to,
                                :to, :cc, :bcc, :in_reply_to, :message_id)
      ##
      # method: date
      # call-seq: date -> string
      #
      # Returns a string that represents the +Date+ header.
      #
      # [Note]
      #   For a well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
      #   message, the #date field must not be +nil+.  However it can be +nil+
      #   for a malformed or draft message.

      ##
      # method: subject
      # call-seq: subject -> string or nil
      #
      # Returns a string that represents the +Subject+ header, if it is present.
      #
      # [Note]
      #   Servers should return +nil+ when the header is absent and an empty
      #   string when it is present but empty.  Some servers may return a +nil+
      #   envelope member in the "present but empty" case.  Clients should treat
      #   +nil+ and empty string as identical.

      ##
      # method: from
      # call-seq: from -> array of Net::IMAP::Address or nil
      #
      # Returns an array of Address that represents the +From+ header.
      #
      # If the +From+ header is absent, or is present but empty, the server
      # returns +nil+ for this envelope field.
      #
      # [Note]
      #   For a well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
      #   message, the #from field must not be +nil+.  However it can be +nil+
      #   for a malformed or draft message.

      ##
      # method: sender
      # call-seq: sender -> array of Net::IMAP::Address or nil
      #
      # Returns an array of Address that represents the +Sender+ header.
      #
      # [Note]
      #   If the <tt>Sender</tt> header is absent, or is present but empty, the
      #   server sets this field to be the same value as #from.  Therefore, in a
      #   well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] message,
      #   the #sender envelope field must not be +nil+.  However it can be
      #   +nil+ for a malformed or draft message.

      ##
      # method: reply_to
      # call-seq: reply_to -> array of Net::IMAP::Address or nil
      #
      # Returns an array of Address that represents the <tt>Reply-To</tt>
      # header.
      #
      # [Note]
      #   If the <tt>Reply-To</tt> header is absent, or is present but empty,
      #   the server sets this field to be the same value as #from.  Therefore,
      #   in a well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
      #   message, the #reply_to envelope field must not be +nil+.  However it
      #   can be +nil+ for a malformed or draft message.

      ##
      # method: to
      # call-seq: to -> array of Net::IMAP::Address
      #
      # Returns an array of Address that represents the +To+ header.

      ##
      # method: cc
      # call-seq: cc -> array of Net::IMAP::Address
      #
      # Returns an array of Address that represents the +Cc+ header.

      ##
      # method: bcc
      # call-seq: bcc -> array of Net::IMAP::Address
      #
      # Returns an array of Address that represents the +Bcc+ header.

      ##
      # method: in_reply_to
      # call-seq: in_reply_to -> string
      #
      # Returns a string that represents the <tt>In-Reply-To</tt> header.
      #
      # [Note]
      #   For a well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
      #   message, the #in_reply_to field, if present, must not be empty.  But
      #   it can still return an empty string for malformed messages.
      #
      #   Servers should return +nil+ when the header is absent and an empty
      #   string when it is present but empty.  Some servers may return a +nil+
      #   envelope member in the "present but empty" case.  Clients should treat
      #   +nil+ and empty string as identical.

      ##
      # method: message_id
      # call-seq: message_id -> string
      #
      # Returns a string that represents the <tt>Message-ID</tt>.
      #
      # [Note]
      #   For a well-formed [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]]
      #   message, the #message_id field, if present, must not be empty.  But it
      #   can still return an empty string for malformed messages.
      #
      #   Servers should return +nil+ when the header is absent and an empty
      #   string when it is present but empty.  Some servers may return a +nil+
      #   envelope member in the "present but empty" case.  Clients should treat
      #   +nil+ and empty string as identical.
    end

    # Net::IMAP::Address represents an electronic mail address, which has been
    # parsed into its component parts by the server.  Address objects are
    # returned within Envelope fields.
    #
    # == Group syntax
    #
    # When the #host field is +nil+, this is a special form of address structure
    # that indicates the [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] group
    # syntax.  If the #mailbox name field is also +nil+, this is an end-of-group
    # marker (semicolon in RFC-822 syntax).  If the #mailbox name field is
    # non-+NIL+, this is the start of a group marker, and the mailbox #name
    # field holds the group name phrase.
    class Address < Struct.new(:name, :route, :mailbox, :host)
      ##
      # method: name
      # :call-seq: name -> string or nil
      #
      # Returns the [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] address
      # +display-name+ (or the mailbox +phrase+ in the RFC-822 grammar).

      ##
      # method: route
      # :call-seq: route -> string or nil
      #
      # Returns the route from RFC-822 route-addr.
      #
      # Note:: Generating this obsolete route addressing syntax is not allowed
      #        by [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]].  However,
      #        addresses with this syntax must still be accepted and parsed.

      ##
      # method: mailbox
      # :call-seq: mailbox -> string or nil
      #
      # Returns the [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] address
      # +local-part+, if #host is not +nil+.
      #
      # When #host is +nil+, this returns
      # an [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] group name and a +nil+
      # mailbox indicates the end of a group.

      ##
      # method: host
      # :call-seq: host -> string or nil
      #
      # Returns the [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] addr-spec
      # +domain+ name.
      #
      # +nil+ indicates [RFC5322[https://www.rfc-editor.org/rfc/rfc5322]] group
      # syntax.
    end

    # Net::IMAP::ContentDisposition represents Content-Disposition fields.
    #
    class ContentDisposition < Struct.new(:dsp_type, :param)
      ##
      # method: dsp_type
      # :call-seq: dsp_type -> string
      #
      # Returns the content disposition type, as defined by
      # [DISPOSITION[https://www.rfc-editor.org/rfc/rfc2183]].

      ##
      # method: param
      # :call-seq: param -> hash
      #
      # Returns a hash representing parameters of the Content-Disposition
      # field, as defined by [DISPOSITION[https://www.rfc-editor.org/rfc/rfc2183]].
    end

    # Net::IMAP::ThreadMember represents a thread-node returned
    # by Net::IMAP#thread.
    #
    class ThreadMember < Struct.new(:seqno, :children)
      ##
      # method: seqno
      # :call-seq: seqno -> Integer
      #
      # The message sequence number.

      ##
      # method: children
      # :call-seq: children -> array of ThreadMember
      #
      # An array of Net::IMAP::ThreadMember objects for mail items that are
      # children of this in the thread.

      # Returns a SequenceSet containing #seqno and all #children's seqno,
      # recursively.
      def to_sequence_set
        SequenceSet.new all_seqnos
      end

      protected

      def all_seqnos(node = self)
        [node.seqno].concat node.children.flat_map { _1.all_seqnos }
      end

    end

    # Net::IMAP::BodyStructure is included by all of the structs that can be
    # returned from a <tt>"BODYSTRUCTURE"</tt> or <tt>"BODY"</tt>
    # FetchData#attr value.  Although these classes don't share a base class,
    # this module can be used to pattern match all of them.
    #
    # See {[IMAP4rev1] §7.4.2}[https://www.rfc-editor.org/rfc/rfc3501#section-7.4.2]
    # and {[IMAP4rev2] §7.5.2}[https://www.rfc-editor.org/rfc/rfc9051#section-7.5.2-4.9]
    # for full description of all +BODYSTRUCTURE+ fields, and also
    # Net::IMAP@Message+envelope+and+body+structure for other relevant RFCs.
    #
    # == Classes that include BodyStructure
    # BodyTypeBasic:: Represents any message parts that are not handled by
    #                 BodyTypeText, BodyTypeMessage, or BodyTypeMultipart.
    # BodyTypeText:: Used by <tt>text/*</tt> parts.  Contains all of the
    #                BodyTypeBasic fields.
    # BodyTypeMessage:: Used by <tt>message/rfc822</tt> and
    #                   <tt>message/global</tt> parts.  Contains all of the
    #                   BodyTypeBasic fields.  Other <tt>message/*</tt> types
    #                   should use BodyTypeBasic.
    # BodyTypeMultipart:: for <tt>multipart/*</tt> parts
    #
    module BodyStructure
    end

    # Net::IMAP::BodyTypeBasic represents basic body structures of messages and
    # message parts, unless they have a <tt>Content-Type</tt> that is handled by
    # BodyTypeText, BodyTypeMessage, or BodyTypeMultipart.
    #
    # See {[IMAP4rev1] §7.4.2}[https://www.rfc-editor.org/rfc/rfc3501#section-7.4.2]
    # and {[IMAP4rev2] §7.5.2}[https://www.rfc-editor.org/rfc/rfc9051#section-7.5.2-4.9]
    # for full description of all +BODYSTRUCTURE+ fields, and also
    # Net::IMAP@Message+envelope+and+body+structure for other relevant RFCs.
    #
    class BodyTypeBasic < Struct.new(:media_type, :subtype,
                                     :param, :content_id,
                                     :description, :encoding, :size,
                                     :md5, :disposition, :language,
                                     :location,
                                     :extension)
      include BodyStructure

      ##
      # method: media_type
      # :call-seq: media_type -> string
      #
      # The top-level media type as defined in
      # [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]].

      ##
      # method: subtype
      # :call-seq: subtype -> string
      #
      # The media subtype name as defined in
      # [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]].

      ##
      # method: param
      # :call-seq: param -> string
      #
      # Returns a hash that represents parameters as defined in
      # [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]].

      ##
      # method: content_id
      # :call-seq: content_id -> string
      #
      # Returns a string giving the content id as defined
      # in [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]]
      # {§7}[https://www.rfc-editor.org/rfc/rfc2045#section-7].

      ##
      # method: description
      # :call-seq: description -> string
      #
      # Returns a string giving the content description as defined
      # in [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]]
      # {§8}[https://www.rfc-editor.org/rfc/rfc2045#section-8].

      ##
      # method: encoding
      # :call-seq: encoding -> string
      #
      # Returns a string giving the content transfer encoding as defined
      # in [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]]
      # {§6}[https://www.rfc-editor.org/rfc/rfc2045#section-6].

      ##
      # method: size
      # :call-seq: size -> integer
      #
      # Returns a number giving the size of the body in octets.

      ##
      # method: md5
      # :call-seq: md5 -> string
      #
      # Returns a string giving the body MD5 value as defined in
      # [MD5[https://www.rfc-editor.org/rfc/rfc1864]].

      ##
      # method: disposition
      # :call-seq: disposition -> ContentDisposition
      #
      # Returns a ContentDisposition object giving the content
      # disposition, as defined by
      # [DISPOSITION[https://www.rfc-editor.org/rfc/rfc2183]].

      ##
      # method: language
      # :call-seq: language -> string
      #
      # Returns a string or an array of strings giving the body
      # language value as defined in
      # [LANGUAGE-TAGS[https://www.rfc-editor.org/info/rfc3282]].

      #--
      ##
      # method: location
      # :call-seq: location -> string
      #
      # A string list giving the body content URI as defined in
      # [LOCATION[https://www.rfc-editor.org/info/rfc2557]].
      #++

      ##
      # method: extension
      # :call-seq: extension -> string
      #
      # Returns extension data.  The +BODYSTRUCTURE+ fetch attribute
      # contains extension data, but +BODY+ does not.

      ##
      # :call-seq: multipart? -> false
      #
      # BodyTypeBasic is not used for multipart MIME parts.
      def multipart?
        return false
      end

      # :call-seq: media_subtype -> subtype
      #
      # >>>
      #   [Obsolete]
      #     Use +subtype+ instead.  Calling this will generate a warning message
      #     to +stderr+, then return the value of +subtype+.
      #--
      # TODO: why not just keep this as an alias?  Would "media_subtype" be used
      # for something else?
      #++
      def media_subtype
        warn("media_subtype is obsolete, use subtype instead.\n",
             uplevel: 1, category: :deprecated)
        return subtype
      end
    end

    # Net::IMAP::BodyTypeText represents the body structures of messages and
    # message parts, when <tt>Content-Type</tt> is <tt>text/*</tt>.
    #
    # BodyTypeText contains all of the fields of BodyTypeBasic.  See
    # BodyTypeBasic for documentation of the following:
    # * {media_type}[rdoc-ref:BodyTypeBasic#media_type]
    # * subtype[rdoc-ref:BodyTypeBasic#subtype]
    # * param[rdoc-ref:BodyTypeBasic#param]
    # * {content_id}[rdoc-ref:BodyTypeBasic#content_id]
    # * description[rdoc-ref:BodyTypeBasic#description]
    # * encoding[rdoc-ref:BodyTypeBasic#encoding]
    # * size[rdoc-ref:BodyTypeBasic#size]
    #
    class BodyTypeText < Struct.new(:media_type, :subtype,
                                    :param, :content_id,
                                    :description, :encoding, :size,
                                    :lines,
                                    :md5, :disposition, :language,
                                    :location,
                                    :extension)
      include BodyStructure

      ##
      # method: lines
      # :call-seq: lines -> Integer
      #
      # Returns the size of the body in text lines.

      ##
      # :call-seq: multipart? -> false
      #
      # BodyTypeText is not used for multipart MIME parts.
      def multipart?
        return false
      end

      # Obsolete: use +subtype+ instead.  Calling this will
      # generate a warning message to +stderr+, then return
      # the value of +subtype+.
      def media_subtype
        warn("media_subtype is obsolete, use subtype instead.\n",
             uplevel: 1, category: :deprecated)
        return subtype
      end
    end

    # Net::IMAP::BodyTypeMessage represents the body structures of messages and
    # message parts, when <tt>Content-Type</tt> is <tt>message/rfc822</tt> or
    # <tt>message/global</tt>.
    #
    # BodyTypeMessage contains all of the fields of BodyTypeBasic.  See
    # BodyTypeBasic for documentation of the following fields:
    # * {media_type}[rdoc-ref:BodyTypeBasic#media_type]
    # * subtype[rdoc-ref:BodyTypeBasic#subtype]
    # * param[rdoc-ref:BodyTypeBasic#param]
    # * {content_id}[rdoc-ref:BodyTypeBasic#content_id]
    # * description[rdoc-ref:BodyTypeBasic#description]
    # * encoding[rdoc-ref:BodyTypeBasic#encoding]
    # * size[rdoc-ref:BodyTypeBasic#size]
    class BodyTypeMessage < Struct.new(:media_type, :subtype,
                                       :param, :content_id,
                                       :description, :encoding, :size,
                                       :envelope, :body, :lines,
                                       :md5, :disposition, :language,
                                       :location,
                                       :extension)
      include BodyStructure

      ##
      # method: envelope
      # :call-seq: envelope -> Envelope
      #
      # Returns a Net::IMAP::Envelope giving the envelope structure.

      ##
      # method: body
      # :call-seq: body -> BodyStructure
      #
      # Returns a Net::IMAP::BodyStructure for the message's body structure.

      ##
      # :call-seq: multipart? -> false
      #
      # BodyTypeMessage is not used for multipart MIME parts.
      def multipart?
        return false
      end

      # Obsolete: use +subtype+ instead.  Calling this will
      # generate a warning message to +stderr+, then return
      # the value of +subtype+.
      def media_subtype
        warn("media_subtype is obsolete, use subtype instead.\n", uplevel: 1)
        return subtype
      end
    end

    # Net::IMAP::BodyTypeMultipart represents body structures of messages and
    # message parts, when <tt>Content-Type</tt> is <tt>multipart/*</tt>.
    class BodyTypeMultipart < Struct.new(:media_type, :subtype,
                                         :parts,
                                         :param, :disposition, :language,
                                         :location,
                                         :extension)
      include BodyStructure

      ##
      # method: media_type
      # call-seq: media_type -> "multipart"
      #
      # BodyTypeMultipart is only used with <tt>multipart/*</tt> media types.

      ##
      # method: subtype
      # call-seq: subtype -> string
      #
      # Returns the content subtype name
      # as defined in [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]].

      ##
      # method: parts
      # call-seq: parts -> array of BodyStructure objects
      #
      # Returns an array with a BodyStructure object for each part contained in
      # this part.

      ##
      # method: param
      # call-seq: param -> hash
      #
      # Returns a hash that represents parameters
      # as defined in [MIME-IMB[https://www.rfc-editor.org/rfc/rfc2045]].

      ##
      # method: disposition
      # call-seq: disposition -> ContentDisposition
      #
      # Returns a Net::IMAP::ContentDisposition object giving the content
      # disposition.

      ##
      # method: language
      # :call-seq: language -> string
      #
      # Returns a string or an array of strings giving the body
      # language value as defined in
      # [LANGUAGE-TAGS[https://www.rfc-editor.org/info/rfc3282]].

      ##
      # method: extension
      # call-seq: extension -> array
      #
      # Returns extension data as an array of numbers strings, and nested
      # arrays (of numbers, strings, etc).

      ##
      # :call-seq: multipart? -> true
      #
      # BodyTypeMultipart is used for multipart MIME parts.
      def multipart?
        return true
      end

      ##
      # Obsolete: use +subtype+ instead.  Calling this will
      # generate a warning message to +stderr+, then return
      # the value of +subtype+.
      def media_subtype
        warn("media_subtype is obsolete, use subtype instead.\n",
             uplevel: 1, category: :deprecated)
        return subtype
      end
    end

  end
end
