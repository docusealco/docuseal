# frozen_string_literal: true

module RailsI18n
  module Transliteration
    module Ukrainian
      class << self
        def rule
          lambda do |string|
            next '' unless string

            string.gsub(/./) do |char|
              # Regexp.last_match is local to the thread and method scope
              # of the method that did the pattern match.
              @pre_match, @post_match = $`, $'

              case char
              when 'Ж'
                lookahead_upcase 'ZH'
              when 'Х'
                lookahead_upcase 'KH'
              when 'Ц'
                lookahead_upcase 'TS'
              when 'Ч'
                lookahead_upcase 'CH'
              when 'Ш'
                lookahead_upcase 'SH'
              when 'Щ'
                lookahead_upcase 'SHCH'
              when 'г'
                behind =~ /[зЗ]/ ? 'gh' : 'h'
              when 'Г'
                behind =~ /[зЗ]/ ? lookahead_upcase('GH') : 'H'
              when 'є'
                letter?(behind) ? 'ie' : 'ye'
              when 'Є'
                letter?(behind) ? lookahead_upcase('IE') : lookahead_upcase('YE')
              when 'ї'
                letter?(behind) ? 'i' : 'yi'
              when 'Ї'
                letter?(behind) ? 'I' : lookahead_upcase('YI')
              when 'й'
                letter?(behind) ? 'i' : 'y'
              when 'Й'
                letter?(behind) ? 'I' : 'Y'
              when 'ю'
                letter?(behind) ? 'iu' : 'yu'
              when 'Ю'
                letter?(behind) ? lookahead_upcase('IU') : lookahead_upcase('YU')
              when 'я'
                letter?(behind) ? 'ia' : 'ya'
              when 'Я'
                letter?(behind) ? lookahead_upcase('IA') : lookahead_upcase('YA')
              when "'"
                # remove apostrophe inside a word
                letter?(behind) && letter?(ahead) ? '' : "'"
              else
                straight_lookup[char] || char
              end
            end
          end
        end

        private

        def behind
          @pre_match && @pre_match[-1]
        end

        def ahead
          @post_match && @post_match[0]
        end

        def downcased?(symbol)
          symbol =~ downcased_regexp
        end

        def downcased_regexp
          @downcased_regexp ||= /[а-яґєії]/
        end

        # apostrophe can be inside a word
        def letter?(symbol)
          symbol =~ letter_regexp
        end

        def letter_regexp
          @letter_regexp ||= /[а-яґєіїА-ЯҐЄІЇ'’]/
        end

        def lookahead_upcase(word)
          downcased?(ahead) ? word.capitalize : word.upcase
        end

        def straight_lookup
          @straight_lookup ||= {
            'а'=>'a','б'=>'b','в'=>'v','ґ'=>'g','д'=>'d','е'=>'e','ж'=>'zh',
            'з'=>'z','и'=>'y','і'=>'i','к'=>'k','л'=>'l','м'=>'m','н'=>'n','о'=>'o',
            'п'=>'p','р'=>'r','с'=>'s','т'=>'t','у'=>'u','ф'=>'f','х'=>'kh','ц'=>'ts',
            'ч'=>'ch','ш'=>'sh','щ'=>'shch','ь'=>'','’'=>'',
            'А'=>'A','Б'=>'B','В'=>'V','Ґ'=>'G','Д'=>'D','Е'=>'E',
            'З'=>'Z','И'=>'Y','І'=>'I','К'=>'K','Л'=>'L','М'=>'M','Н'=>'N','О'=>'O',
            'П'=>'P','Р'=>'R','С'=>'S','Т'=>'T','У'=>'U','Ф'=>'F','Ь'=>''
          }
        end
      end
    end

    # (c) Yaroslav Markin, Julian "julik" Tarkhanov and Co
    # https://github.com/yaroslav/russian/blob/master/lib/russian/transliteration.rb
    module Russian
      class << self
        def rule
          lambda do |string|
            next '' unless string

            chars = string.scan(%r{#{multi_keys.join '|'}|\w|.})

            result = +""

            chars.each_with_index do |char, index|
              if upper.has_key?(char) && lower.has_key?(chars[index+1])
                # combined case
                result << upper[char].downcase.capitalize
              elsif upper.has_key?(char)
                result << upper[char]
              elsif lower.has_key?(char)
                result << lower[char]
              else
                result << char
              end
            end

            result
          end
        end

        private

        # use instance variables instead of constants to prevent warnings
        # on re-evaling after I18n.reload!

        def upper
          @upper ||= begin
            upper_single = {
              "Ґ"=>"G","Ё"=>"YO","Є"=>"E","Ї"=>"YI","І"=>"I",
              "А"=>"A","Б"=>"B","В"=>"V","Г"=>"G",
              "Д"=>"D","Е"=>"E","Ж"=>"ZH","З"=>"Z","И"=>"I",
              "Й"=>"Y","К"=>"K","Л"=>"L","М"=>"M","Н"=>"N",
              "О"=>"O","П"=>"P","Р"=>"R","С"=>"S","Т"=>"T",
              "У"=>"U","Ф"=>"F","Х"=>"H","Ц"=>"TS","Ч"=>"CH",
              "Ш"=>"SH","Щ"=>"SCH","Ъ"=>"'","Ы"=>"Y","Ь"=>"",
              "Э"=>"E","Ю"=>"YU","Я"=>"YA",
            }

            (upper_single.merge(upper_multi)).freeze
          end
        end

        def lower
          @lower ||= begin
            lower_single = {
              "і"=>"i","ґ"=>"g","ё"=>"yo","№"=>"#","є"=>"e",
              "ї"=>"yi","а"=>"a","б"=>"b",
              "в"=>"v","г"=>"g","д"=>"d","е"=>"e","ж"=>"zh",
              "з"=>"z","и"=>"i","й"=>"y","к"=>"k","л"=>"l",
              "м"=>"m","н"=>"n","о"=>"o","п"=>"p","р"=>"r",
              "с"=>"s","т"=>"t","у"=>"u","ф"=>"f","х"=>"h",
              "ц"=>"ts","ч"=>"ch","ш"=>"sh","щ"=>"sch","ъ"=>"'",
              "ы"=>"y","ь"=>"","э"=>"e","ю"=>"yu","я"=>"ya",
            }

            (lower_single.merge(lower_multi)).freeze
          end
        end

        def upper_multi
          @upper_multi ||= { "ЬЕ"=>"IE", "ЬЁ"=>"IE" }
        end

        def lower_multi
          @lower_multi ||= { "ье"=>"ie", "ьё"=>"ie" }
        end

        def multi_keys
          @multi_keys ||= (lower_multi.merge(upper_multi)).keys.sort_by {|s| s.length}.reverse.freeze
        end
      end
    end
  end
end

