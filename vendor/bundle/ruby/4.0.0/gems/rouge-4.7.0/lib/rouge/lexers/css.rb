# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CSS < RegexLexer
      title "CSS"
      desc "Cascading Style Sheets, used to style web pages"

      tag 'css'
      filenames '*.css'
      mimetypes 'text/css'

      # Documentation: https://www.w3.org/TR/CSS21/syndata.html#characters

      identifier = /[\p{L}_-][\p{Word}\p{Cf}-]*/
      number = /-?(?:[0-9]+(\.[0-9]+)?|\.[0-9]+)/

      def self.properties
        @properties ||= Set.new %w(
          additive-symbols align-content align-items align-self
          alignment-adjust alignment-baseline all anchor-point animation
          animation-composition animation-delay animation-direction
          animation-duration animation-fill-mode animation-iteration-count
          animation-name animation-play-state animation-timing-function
          appearance aspect-ratio azimuth backface-visibility background
          background-attachment background-blend-mode
          background-clip background-color background-image
          background-origin background-position
          background-repeat background-size baseline-shift
          binding bleed bookmark-label bookmark-level bookmark-state
          bookmark-target border border-bottom border-bottom-color
          border-bottom-left-radius border-bottom-right-radius
          border-bottom-style border-bottom-width border-collapse
          border-color border-image border-image-outset border-image-repeat
          border-image-slice border-image-source border-image-width
          border-left border-left-color border-left-style border-left-width
          border-radius border-right border-right-color border-right-style
          border-right-width border-spacing border-style border-top
          border-top-color border-top-left-radius border-top-right-radius
          border-top-style border-top-width border-width bottom box-align
          box-decoration-break box-direction box-flex box-flex-group
          box-lines box-ordinal-group box-orient box-pack box-shadow
          box-sizing break-after break-before break-inside caption-side
          clear clip clip-path clip-rule color color-profile column-count
          column-fill column-gap column-rule column-rule-color
          column-rule-style column-rule-width column-span column-width
          columns content container container-name container-type
          counter-increment counter-reset counter-set crop cue
          cue-after cue-before cursor direction display dominant-baseline
          drop-initial-after-adjust drop-initial-after-align
          drop-initial-before-adjust drop-initial-before-align
          drop-initial-size drop-initial-value elevation empty-cells fallback
          filter fit fit-position flex flex-basis flex-direction flex-flow
          flex-grow flex-shrink flex-wrap float float-offset font
          font-display font-family font-feature-settings font-kerning
          font-language-override font-size font-size-adjust font-stretch
          font-style font-synthesis font-variant font-variant-alternates
          font-variant-caps font-variant-east-asian font-variant-ligatures
          font-variant-numeric font-variant-position font-weight gap
          grid-area grid-auto-columns grid-auto-flow grid-auto-rows
          grid-column grid-column-end grid-column-start grid-row
          grid-row-end grid-row-start grid-template grid-template-areas
          grid-template-columns grid-template-rows hanging-punctuation
          height hyphenate-after hyphenate-before hyphenate-character
          hyphenate-lines hyphenate-resource hyphens icon image-orientation
          image-rendering image-resolution ime-mode inherits initial-value
          inline-box-align inset isolation justify-content justify-items
          justify-self left letter-spacing line-break line-height
          line-stacking line-stacking-ruby line-stacking-shift
          line-stacking-strategy list-style list-style-image
          list-style-position list-style-type margin margin-bottom
          margin-left margin-right margin-top mark mark-after mark-before
          marker-offset marks marquee-direction marquee-loop
          marquee-play-count marquee-speed marquee-style
          mask mask-clip mask-composite mask-image mask-mode
          mask-origin mask-position mask-repeat mask-size mask-type
          max-height max-width min-height min-width mix-blend-mode
          move-to nav-down nav-index nav-left nav-right nav-up negative
          object-fit object-position offset offset-anchor offset-distance
          offset-path offset-position offset-rotate opacity order orphans
          outline outline-color outline-offset outline-style outline-width
          overflow overflow-style overflow-wrap overflow-x overflow-y pad
          padding padding-bottom padding-left padding-right padding-top page
          page-break-after page-break-before page-break-inside page-policy
          pause pause-after pause-before perspective perspective-origin
          phonemes pitch pitch-range place-content place-items place-self
          play-during pointer-events position prefix presentation-level
          punctuation-trim quotes range rendering-intent resize rest
          rest-after rest-before richness right rotate rotation rotation-point
          row-gap ruby-align ruby-overhang ruby-position ruby-span scale
          scroll-behavior scroll-margin scroll-margin-block
          scroll-margin-block-end scroll-margin-block-start
          scroll-margin-bottom scroll-margin-inline scroll-margin-inline-end
          scroll-margin-inline-start scroll-margin-left scroll-margin-right
          scroll-margin-top scroll-padding-top scroll-padding-right
          scroll-padding-bottom scroll-padding-left scroll-padding
          scroll-padding-block-end scroll-padding-block-start
          scroll-padding-block scroll-padding-inline-end
          scroll-padding-inline-start scroll-padding-inline
          scroll-snap-type scroll-snap-align scroll-snap-stop
          shape-outside shape-margin shape-image-threshold shape-rendering
          size speak speak-as speak-header speak-numeral speak-punctuation
          speech-rate src stress string-set suffix symbols syntax system
          tab-size table-layout target target-name target-new target-position
          text-align text-align-last text-combine-horizontal
          text-decoration text-decoration-color text-decoration-line
          text-decoration-skip text-decoration-style text-emphasis
          text-emphasis-color text-emphasis-position text-emphasis-style
          text-height text-indent text-justify text-orientation
          text-outline text-overflow text-rendering text-shadow
          text-space-collapse text-transform text-underline-position
          text-wrap top transform transform-origin transform-style
          transition transition-delay transition-duration
          transition-property transition-timing-function translate
          unicode-bidi vertical-align visibility voice-balance
          voice-duration voice-family voice-pitch voice-pitch-range
          voice-range voice-rate voice-stress voice-volume volume
          white-space widows width word-break word-spacing word-wrap
          writing-mode z-index
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          above absolute accumulate add additive all alpha alphabetic
          alternate alternate-reverse always armenian aural auto auto-fill
          auto-fit avoid backwards balance baseline behind below bidi-override
          blink block bold bolder border-box both bottom bottom break-spaces
          capitalize center center-left center-right circle cjk-ideographic
          close-quote closest-corner closest-side collapse
          color color-burn color-dodge column column-reverse
          condensed contain content content-box continuous cover crop cross
          crosshair cursive cyclic darken dashed decimal decimal-leading-zero
          default difference digits disc dotted double e-resize
          ease ease-in ease-in-out ease-out embed end exclude exclusion
          expanded extends extra-condensed extra-expanded fantasy
          farthest-corner farthest-side far-left far-right
          fast faster fill fixed flat flex flex-end flex-start
          forwards georgian grid groove hard-light hebrew help hidden
          hide high higher hiragana hiragana-iroha horizontal hue icon
          infinite inherit inline inline-block inline-flex inline-grid
          inline-size inline-table inset inside intersect isolate italic
          justify katakana katakana-iroha landscape large larger left
          left-side leftwards level lighten lighter line-through linear
          list-item loud low lower lower-alpha lower-greek lower-roman
          lowercase ltr luminance luminosity mandatory match-source medium
          message-box middle mix monospace multiply n-resize narrower
          ne-resize no-close-quote no-open-quote no-repeat none normal
          nowrap numeric nw-resize oblique once open-quote outset outside
          overlay overline paused pointer portrait pre preserve-3d pre-line
          pre-wrap proximity px relative repeat-x repeat-y replace reverse
          ridge right right-side rightwards row row-reverse rtl running
          s-resize sans-serif saturation scale-down screen scroll
          se-resize semi-condensed semi-expanded separate serif show
          sides silent size slow slower small-caps small-caption smaller
          smooth soft soft-light solid space-around space-between
          space-evenly span spell-out square start static status-bar sticky
          stretch sub subtract super sw-resize swap symbolic table
          table-caption table-cell table-column table-column-group
          table-footer-group table-header-group table-row table-row-group
          text text-bottom text-top thick thin top transparent
          ultra-condensed ultra-expanded underline upper-alpha upper-latin
          upper-roman uppercase vertical visible w-resize wait wider wrap
          wrap-reverse x x-fast x-high x-large x-loud x-low x-small x-soft
          xx-large xx-small yes y z
        )
      end

      def self.colors
        @colors ||= Set.new %w(
          aliceblue antiquewhite aqua aquamarine azure beige bisque black
          blanchedalmond blue blueviolet brown burlywood cadetblue
          chartreuse chocolate coral cornflowerblue cornsilk crimson cyan
          darkblue darkcyan darkgoldenrod darkgray darkgreen darkkhaki
          darkmagenta darkolivegreen darkorange darkorchid darkred
          darksalmon darkseagreen darkslateblue darkslategray darkturquoise
          darkviolet deeppink deepskyblue dimgray dodgerblue firebrick
          floralwhite forestgreen fuchsia gainsboro ghostwhite gold
          goldenrod gray green greenyellow honeydew hotpink indianred
          indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon
          lightblue lightcoral lightcyan lightgoldenrodyellow lightgreen
          lightgrey lightpink lightsalmon lightseagreen lightskyblue
          lightslategray lightsteelblue lightyellow lime limegreen linen
          magenta maroon mediumaquamarine mediumblue mediumorchid
          mediumpurple mediumseagreen mediumslateblue mediumspringgreen
          mediumturquoise mediumvioletred midnightblue mintcream mistyrose
          moccasin navajowhite navy oldlace olive olivedrab orange
          orangered orchid palegoldenrod palegreen paleturquoise
          palevioletred papayawhip peachpuff peru pink plum powderblue
          purple red rosybrown royalblue saddlebrown salmon sandybrown
          seagreen seashell sienna silver skyblue slateblue slategray snow
          springgreen steelblue tan teal thistle tomato
          turquoise violet wheat white whitesmoke yellow yellowgreen
        )
      end

      def self.functions
        @functions ||= Set.new %w(
          abs acos annotation asin atan atan2 attr blur brightness calc
          character-variant circle clamp color color-mix conic-gradient
          contrast cos counter counters cubic-bezier drop-shadow ellipse
          env exp fit-content format grayscale hsl hsla hue-rotate hwb hypot
          image-set inset invert lab lch linear linear-gradient log matrix
          matrix3d max min minmax mod oklab oklch opacity ornaments path
          perspective polygon pow radial-gradient ray rect rem repeat
          repeating-conic-gradient repeating-linear-gradient
          repeating-radial-gradient rgb rgba rotate rotate3d rotatex
          rotatey rotatez round saturate scale scale3d scalex scaley scalez
          sepia sign sin skewx skewy sqrt steps styleset
          stylistic swash tan translate translate3d translatex translatey
          translatez url var xywh
        )
      end

      # source: http://www.w3.org/TR/CSS21/syndata.html#vendor-keyword-history
      def self.vendor_prefixes
        @vendor_prefixes ||= Set.new %w(
          -ah- -atsc- -hp- -khtml- -moz- -ms- -o- -rim- -ro- -tc- -wap-
          -webkit- -xv- mso- prince-
        )
      end

      state :root do
        mixin :basics
        rule %r/{/, Punctuation, :stanza
        rule %r/:[:]?#{identifier}/, Name::Decorator
        rule %r/\.#{identifier}/, Name::Class
        rule %r/##{identifier}/, Name::Function
        rule %r/@#{identifier}/, Keyword, :at_rule
        rule identifier, Name::Tag
        rule %r([~^*!%&\[\]()<>|+=@:;,./?-]), Operator
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Single
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Double
        rule %r/[0-9]{1,3}\%/, Num
      end

      state :value do
        mixin :basics
        rule %r/#[0-9a-f]{3,8}/i, Name::Other # colors
        rule %r/#{number}(?:%|(?:px|pt|pc|in|cm|mm|Q|em|rem|ex|ch|vw|vh|vmin|vmax|fr|dpi|dpcm|dppx|deg|grad|rad|turn|s|ms|Hz|kHz)\b)?/, Num
        rule %r/[\[\]():.,]/, Punctuation
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Single
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Double
        rule %r/(true|false)/i, Name::Constant
        rule %r/\-\-#{identifier}/, Literal
        rule %r([*+/-]), Operator
        rule(identifier) do |m|
          if self.class.colors.include? m[0].downcase
            token Name::Other
          elsif self.class.builtins.include? m[0].downcase
            token Name::Builtin
          elsif self.class.functions.include? m[0].downcase
            token Name::Function
          else
            token Name
          end
        end
      end

      state :at_rule do
        rule %r/(?:<=|>=|~=|\|=|\^=|\$=|\*=|<|>|=)/, Operator
        rule %r/{(?=\s*#{identifier}\s*:)/m, Punctuation, :at_stanza
        rule %r/{/, Punctuation, :at_body
        rule %r/;/, Punctuation, :pop!
        mixin :value
      end

      state :at_body do
        mixin :at_content
        mixin :root
      end

      state :at_stanza do
        mixin :at_content
        mixin :stanza
      end

      state :at_content do
        rule %r/}/ do
          token Punctuation
          pop! 2
        end
      end

      state :basics do
        rule %r/\s+/m, Text
        rule %r(/\*(?:.*?)\*/)m, Comment
      end

      state :stanza do
        mixin :basics
        rule %r/}/, Punctuation, :pop!
        rule %r/(#{identifier})(\s*)(:)/m do |m|
          name_tok = if self.class.properties.include? m[1]
            Name::Label
          elsif self.class.vendor_prefixes.any? { |p| m[1].start_with?(p) }
            Name::Label
          else
            Name::Property
          end

          groups name_tok, Text, Punctuation

          push :stanza_value
        end
      end

      state :stanza_value do
        rule %r/;/, Punctuation, :pop!
        rule(/(?=})/) { pop! }
        rule %r/!\s*important\b/, Comment::Preproc
        rule %r/^@.*?$/, Comment::Preproc
        mixin :value
      end
    end
  end
end
