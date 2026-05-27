module ArabicLetterConnector

  @@charinfos = nil

  class CharacterInfo

  	attr_accessor :common , :formatted

	  def initialize(common, isolated, final, initial, medial, connects)
		  @common = common
      @formatted = {
        :isolated => isolated,
        :final    => final,
        :initial  => initial,
        :medial   => medial,
      }
      @connects = connects
	  end

    def connects?
      @connects
    end

  end

  # Determine the form of the current character (:isolated, :initial, :medial,
  # or :final), given the previous character and the next one. In Arabic, all
  # characters can connect with a previous character, but not all letters can
  # connect with the next character (this is determined by
  # CharacterInfo#connects?).
  def self.determine_form(previous_char, next_char)
    charinfos = self.charinfos
    if charinfos[previous_char] && charinfos[next_char]
      charinfos[previous_char].connects? ? :medial : :initial # If the current character does not connect, 
                                                              # its medial form will map to its final form,
                                                              # and its initial form will map to its isolated form.
    elsif charinfos[previous_char] # The next character is not an arabic character.
      charinfos[previous_char].connects? ? :final : :isolated 
    elsif charinfos[next_char] # The previous character is not an arabic character.
      :initial # If the current character does not connect, its initial form will map to its isolated form.
    else # Neither of the surrounding characters are arabic characters.
      :isolated
    end
  end

  def self.transform(str)
    res = ""
    charinfos = self.charinfos
    previous_char = nil
    current_char = nil
    next_char = nil
    consume_character = lambda do |char|
      previous_char = current_char
      current_char = next_char
      next_char = char
      return unless current_char
      if charinfos.keys.include?(current_char)
        form = determine_form(previous_char, next_char)
        res += charinfos[current_char].formatted[form]
      else
        res += current_char
      end
    end
    str.each_char { |char| consume_character.call(char) }
    consume_character.call(nil)
    return res
  end

  private

  def self.charinfos
    return @@charinfos unless @@charinfos.nil?
    @@charinfos = {}
    add("0627", "fe8d", "fe8e", "fe8d", "fe8e", false) # Alef
    add("0628", "fe8f", "fe90", "fe91", "fe92", true)  # Ba2
    add("062a", "fe95", "fe96", "fe97", "fe98", true)  # Ta2
    add("062b", "fe99", "fe9a", "fe9b", "fe9c", true)  # Tha2
    add("062c", "fe9d", "fe9e", "fe9f", "fea0", true)  # Jeem
    add("062d", "fea1", "fea2", "fea3", "fea4", true)  # 7a2
    add("062e", "fea5", "fea6", "fea7", "fea8", true)  # 7'a2
    add("062f", "fea9", "feaa", "fea9", "feaa", false) # Dal
    add("0630", "feab", "feac", "feab", "feac", false) # Thal
    add("0631", "fead", "feae", "fead", "feae", false) # Ra2
    add("0632", "feaf", "feb0", "feaf", "feb0", false) # Zain
    add("0633", "feb1", "feb2", "feb3", "feb4", true)  # Seen
    add("0634", "feb5", "feb6", "feb7", "feb8", true)  # Sheen
    add("0635", "feb9", "feba", "febb", "febc", true)  # 9ad
    add("0636", "febd", "febe", "febf", "fec0", true)  # 9'ad
    add("0637", "fec1", "fec2", "fec3", "fec4", true)  # 6a2
    add("0638", "fec5", "fec6", "fec7", "fec8", true)  # 6'a2
    add("0639", "fec9", "feca", "fecb", "fecc", true)  # 3ain
    add("063a", "fecd", "fece", "fecf", "fed0", true)  # 3'ain
    add("0641", "fed1", "fed2", "fed3", "fed4", true)  # Fa2
    add("0642", "fed5", "fed6", "fed7", "fed8", true)  # Qaf
    add("0643", "fed9", "feda", "fedb", "fedc", true)  # Kaf
    add("0644", "fedd", "fede", "fedf", "fee0", true)  # Lam
    add("0645", "fee1", "fee2", "fee3", "fee4", true)  # Meem
    add("0646", "fee5", "fee6", "fee7", "fee8", true)  # Noon
    add("0647", "fee9", "feea", "feeb", "feec", true)  # Ha2
    add("0648", "feed", "feee", "feed", "feee", false) # Waw
    add("064a", "fef1", "fef2", "fef3", "fef4", true)  # Ya2
    add("0621", "fe80", "fe80", "fe80", "fe80", false) # Hamza
    add("0622", "fe81", "fe82", "fe81", "fe82", false) # Alef Madda
    add("0623", "fe83", "fe84", "fe83", "fe84", false) # Alef Hamza Above
    add("0624", "fe85", "fe86", "fe85", "fe86", false) # Waw Hamza
    add("0625", "fe87", "fe88", "fe87", "fe88", false) # Alef Hamza Below
    add("0626", "fe89", "fe8a", "fe8b", "fe8c", true)  # Ya2 Hamza
    add("0629", "fe93", "fe94", "fe93", "fe94", false) # Ta2 Marbu6a
    add("0640", "0640", "0640", "0640", "0640", true)  # Tatweel
    add("0649", "feef", "fef0", "feef", "fef0", false) # Alef Layyina
    @@charinfos
  end

  def self.add(common, isolated, final, initial, medial, connects)
    charinfo = CharacterInfo.new(
      [common.hex].pack("U"),
      [isolated.hex].pack("U"),
      [final.hex].pack("U"),
      [initial.hex].pack("U"),
      [medial.hex].pack("U"),
      connects
    )
    @@charinfos[charinfo.common] = charinfo
  end

end
