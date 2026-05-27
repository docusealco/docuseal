# encoding: utf-8

# Copyright 2010-2013 Ayumu Nojima (野島 歩) and Martin J. Dürst (duerst@it.aoyama.ac.jp)
# available under the same licence as Ruby itself
# (see http://www.ruby-lang.org/en/LICENSE.txt)

class Eprun
  class << self

    ## Constant for max hash capacity to avoid DoS attack
    MAX_HASH_LENGTH = 18000 # enough for all test cases, otherwise tests get slow

    ## Regular Expressions and Hash Constants
    REGEXP_D = Regexp.compile(REGEXP_D_STRING, Regexp::EXTENDED)
    REGEXP_C = Regexp.compile(REGEXP_C_STRING, Regexp::EXTENDED)
    REGEXP_K = Regexp.compile(REGEXP_K_STRING, Regexp::EXTENDED)

    NF_HASH_D = Hash.new do |hash, key|
      hash.delete hash.first[0] if hash.length > MAX_HASH_LENGTH # prevent DoS attack
      hash[key] = Eprun.nfd_one(key).pack("U*")
    end

    NF_HASH_C = Hash.new do |hash, key|
      hash.delete hash.first[0] if hash.length > MAX_HASH_LENGTH # prevent DoS attack
      hash[key] = Eprun.nfc_one(key).pack("U*")
    end

    NF_HASH_K = Hash.new do |hash, key|
      hash.delete hash.first[0] if hash.length > MAX_HASH_LENGTH # prevent DoS attack
      hash[key] = Eprun.nfkd_one(key).pack("U*")
    end

    def nf_hash_d
      NF_HASH_D
    end

    def nf_hash_c
      NF_HASH_C
    end

    def nf_hash_k
      NF_HASH_K
    end

    ## Constants For Hangul
    SBASE = 0xAC00
    LBASE = 0x1100
    VBASE = 0x1161
    TBASE = 0x11A7
    LCOUNT = 19
    VCOUNT = 21
    TCOUNT = 28
    NCOUNT = VCOUNT * TCOUNT
    SCOUNT = LCOUNT * NCOUNT

    def get_codepoints(source)
      if source.is_a?(Array)
        source
      elsif source.is_a?(String)
        source.unpack("U*")
      else
        raise ArgumentError, "Source must be a string or an array."
      end
    end

    ## Hangul Algorithm
    def hangul_decomp_one(target)
      cps = get_codepoints(target)
      sIndex = cps.first - SBASE
      return target if sIndex < 0 || sIndex >= SCOUNT
      l = LBASE + sIndex / NCOUNT
      v = VBASE + (sIndex % NCOUNT) / TCOUNT
      t = TBASE + sIndex % TCOUNT
      (t == TBASE ? [l, v] : [l, v, t]) + cps[1..-1]
    end

    def hangul_comp_one(string)
      cps = get_codepoints(string)
      length = cps.length

      in_range = length > 1 &&
        0 <= (lead = cps[0] - LBASE) &&
        lead < LCOUNT &&
        0 <= (vowel = cps[1] - VBASE) &&
        vowel < VCOUNT

      if in_range
        lead_vowel = SBASE + (lead * VCOUNT + vowel) * TCOUNT
        if length > 2 && 0 <= (trail = cps[2] - TBASE) && trail < TCOUNT
          [lead_vowel + trail] + cps[3..-1]
        else
          [lead_vowel] + cps[2..-1]
        end
      else
        string
      end
    end

    ## Canonical Ordering
    def canonical_ordering_one(string)
      cps = get_codepoints(string)
      sorting = cps.collect { |c| [c, CLASS_TABLE[c]] }

      (sorting.length - 2).downto(0) do |i| # bubble sort
        (0..i).each do |j|
          later_class = sorting[j + 1].last
          if 0 < later_class && later_class < sorting[j].last
            sorting[j], sorting[j + 1] = sorting[j + 1], sorting[j]
          end
        end
      end
      sorting.collect(&:first)
    end

    ## Normalization Forms for Patterns (not whole Strings)
    def nfd_one(string)
      cps = get_codepoints(string)
      cps = cps.inject([]) do |ret, cp|
        if decomposition = DECOMPOSITION_TABLE[cp]
          ret += decomposition
        else
          ret << cp
        end
      end

      canonical_ordering_one(hangul_decomp_one(cps))
    end

    def nfkd_one(string)
      cps = get_codepoints(string)
      final_cps = []
      position = 0
      while position < cps.length
        if decomposition = KOMPATIBLE_TABLE[cps[position]]
          final_cps += nfkd_one(decomposition)
        else
          final_cps << cps[position]
        end
        position += 1
      end
      final_cps
    end

    def nfc_one(string)
      nfd_cps = nfd_one(string)
      start = nfd_cps[0]
      last_class = CLASS_TABLE[start] - 1
      accents = []
      nfd_cps[1..-1].each do |accent_cp|
        accent_class = CLASS_TABLE[accent_cp]
        if last_class < accent_class && composite = COMPOSITION_TABLE[[start, accent_cp]]
          start = composite
        else
          accents << accent_cp
          last_class = accent_class
        end
      end
      hangul_comp_one([start] + accents)
    end

    def normalize(string, form = :nfc)
      case form
        when :nfc then
          string.gsub(REGEXP_C) { |s| NF_HASH_C[s] }
        when :nfd then
          string.gsub(REGEXP_D) { |s| NF_HASH_D[s] }
        when :nfkc then
          string.gsub(REGEXP_K) { |s| NF_HASH_K[s] }.gsub(REGEXP_C) { |s| NF_HASH_C[s] }
        when :nfkd then
          string.gsub(REGEXP_K) { |s| NF_HASH_K[s] }.gsub(REGEXP_D) { |s| NF_HASH_D[s] }
        else
          raise ArgumentError, "Invalid normalization form #{form}."
      end
    end

    def normalized?(string, form = :nfc)
      case form
      when :nfc then
        string.scan REGEXP_C do |match|
          return false if NF_HASH_C[match] != match
        end
        true
      when :nfd then
        string.scan REGEXP_D do |match|
          return false if NF_HASH_D[match] != match
        end
        true
      when :nfkc then
        normalized?(string, :nfc) && string !~ REGEXP_K
      when :nfkd then
        normalized?(string, :nfd) && string !~ REGEXP_K
      else
        raise ArgumentError, "Invalid normalization form #{form}."
      end
    end

  end
end # class
