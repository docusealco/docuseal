module Rouge
  module Lexers
    class Bicep < Rouge::RegexLexer
      tag 'bicep'
      filenames '*.bicep'

      title "Bicep"
      desc 'Bicep is a domain-specific language (DSL) that uses declarative syntax to deploy Azure resources.'

      def self.keywords
        @keywords ||= Set.new %w(
          as assert existing extends extension false for from func if import in metadata module 
          none null output param provider resource targetScope test true type using var void with
        )
      end

      def self.datatypes
        @datatypes ||= Set.new %w(array bool int object string)
      end

      def self.functions
        @functions ||= Set.new %w(
          array base64 base64ToJson base64ToString bool cidrHost cidrSubnet concat contains dataUri
          dataUriToString dateTimeAdd dateTimeFromEpoch dateTimeToEpoch deployer deployment empty endsWith
          environment extensionResourceId fail filter first flatten format getSecret groupBy guid indexOf int
          intersection items join json last lastIndexOf length list* listAccountSas listKeys listSecrets loadFileAsBase64
          loadJsonContent loadTextContent loadYamlContent managementGroup managementGroupResourceId map mapValue max min
          newGuid objectKeys padLeft parseCidr pickZones range readEnvironmentVariable reduce reference replace resourceGroup
          resourceId shallowMerge skip sort split startsWith string subscription subscriptionResourceId substring take tenant
          tenantResourceId toLogicalZone toLower toObject toPhysicalZone toUpper trim union uniqueString uri uriComponent
          uriComponentToString utcNow
        )
      end

      operators = %w(+ - * / % < <= > >= == != =~ !~ && || ! ?? ... .?)

      punctuations = %w(( ) { } [ ] , : ; = .)

      state :root do
        mixin :comments

        # Match strings
        rule %r/'/, Str::Single, :string

        # Match numbers
        rule %r/\b\d+\b/, Num

        # Rules for sets of reserved keywords
        rule %r/\b\w+\b/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.datatypes.include? m[0]
            token Keyword::Type
          elsif self.class.functions.include? m[0]
            token Name::Function
          else
            token Name
          end
        end

        # Match operators
        rule %r/#{operators.map { |o| Regexp.escape(o) }.join('|')}/, Operator

        # Enter a state when encountering an opening curly bracket
        rule %r/{/, Punctuation::Indicator, :block

        # Match punctuation
        rule %r/#{punctuations.map { |p| Regexp.escape(p) }.join('|')}/, Punctuation

        # Match identifiers
        rule %r/[a-zA-Z_]\w*/, Name

        # Match decorators
        rule %r/@[a-zA-Z_]\w*/, Name::Decorator

        # Ignore whitespace
        rule %r/\s+/, Text
      end
      
      state :comments do
        rule %r(//[^\n\r]+), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :string do
        rule %r/[^'$}]+/, Str::Single
        rule %r/\$(?!\{)/, Str::Single
        rule %r/\$[\{]/, Str::Interpol, :interp
        rule %r/\'/, Str::Single, :pop!
        rule %r/\$+/, Str::Single
      end

      state :interp do
        rule %r/\}/, Str::Interpol, :pop!
        mixin :root
      end

      # State for matching code blocks between curly brackets
      state :block do
        # Match property names
        rule %r/\b([a-zA-Z_]\w*)\b(?=\s*:)/, Name::Property

        # Match closing curly brackets
        rule %r/}/, Punctuation::Indicator, :pop!

        # Include the root state for nested tokens
        mixin :root
      end
    end
  end
end
