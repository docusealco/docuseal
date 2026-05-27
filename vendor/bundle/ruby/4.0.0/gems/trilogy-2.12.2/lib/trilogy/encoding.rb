# frozen_string_literal: true

class Trilogy
  module Encoding
    RUBY_ENCODINGS = {
      "big5"     => "Big5",
      "dec8"     => nil,
      "cp850"    => "CP850",
      "hp8"      => nil,
      "koi8r"    => "KOI8-R",
      "latin1"   => "ISO-8859-1",
      "latin2"   => "ISO-8859-2",
      "swe7"     => nil,
      "ascii"    => "US-ASCII",
      "ujis"     => "eucJP-ms",
      "sjis"     => "Shift_JIS",
      "hebrew"   => "ISO-8859-8",
      "tis620"   => "TIS-620",
      "euckr"    => "EUC-KR",
      "koi8u"    => "KOI8-R",
      "gb2312"   => "GB2312",
      "greek"    => "ISO-8859-7",
      "cp1250"   => "Windows-1250",
      "gbk"      => "GBK",
      "latin5"   => "ISO-8859-9",
      "armscii8" => nil,
      "utf8"     => "UTF-8",
      "ucs2"     => "UTF-16BE",
      "cp866"    => "IBM866",
      "keybcs2"  => nil,
      "macce"    => "macCentEuro",
      "macroman" => "macRoman",
      "cp852"    => "CP852",
      "latin7"   => "ISO-8859-13",
      "utf8mb4"  => "UTF-8",
      "cp1251"   => "Windows-1251",
      "utf16"    => "UTF-16",
      "cp1256"   => "Windows-1256",
      "cp1257"   => "Windows-1257",
      "utf32"    => "UTF-32",
      "binary"   => "ASCII-8BIT",
      "geostd8"  => nil,
      "cp932"    => "Windows-31J",
      "eucjpms"  => "eucJP-ms",
      "utf16le"  => "UTF-16LE",
      "gb18030"  => "GB18030",
    }.freeze

    CHARSETS = {
      "big5"     => CHARSET_BIG5_CHINESE_CI,
      "cp850"    => CHARSET_CP850_GENERAL_CI,
      "koi8r"    => CHARSET_KOI8R_GENERAL_CI,
      "latin1"   => CHARSET_LATIN1_GENERAL_CI,
      "latin2"   => CHARSET_LATIN2_GENERAL_CI,
      "ascii"    => CHARSET_ASCII_GENERAL_CI,
      "ujis"     => CHARSET_UJIS_JAPANESE_CI,
      "sjis"     => CHARSET_SJIS_JAPANESE_CI,
      "hebrew"   => CHARSET_HEBREW_GENERAL_CI,
      "tis620"   => CHARSET_TIS620_THAI_CI,
      "euckr"    => CHARSET_EUCKR_KOREAN_CI,
      "koi8u"    => CHARSET_KOI8U_GENERAL_CI,
      "gb2312"   => CHARSET_GB2312_CHINESE_CI,
      "greek"    => CHARSET_GREEK_GENERAL_CI,
      "cp1250"   => CHARSET_CP1250_GENERAL_CI,
      "gbk"      => CHARSET_GBK_CHINESE_CI,
      "latin5"   => CHARSET_LATIN5_TURKISH_CI,
      "utf8"     => CHARSET_UTF8_GENERAL_CI,
      "ucs2"     => CHARSET_UCS2_GENERAL_CI,
      "cp866"    => CHARSET_CP866_GENERAL_CI,
      "cp932"    => CHARSET_CP932_JAPANESE_CI,
      "eucjpms"  => CHARSET_EUCJPMS_JAPANESE_CI,
      "utf16le"  => CHARSET_UTF16_GENERAL_CI,
      "gb18030"  => CHARSET_GB18030_CHINESE_CI,
      "macce"    => CHARSET_MACCE_GENERAL_CI,
      "macroman" => CHARSET_MACROMAN_GENERAL_CI,
      "cp852"    => CHARSET_CP852_GENERAL_CI,
      "latin7"   => CHARSET_LATIN7_GENERAL_CI,
      "utf8mb4"  => CHARSET_UTF8MB4_GENERAL_CI,
      "cp1251"   => CHARSET_CP1251_GENERAL_CI,
      "utf16"    => CHARSET_UTF16_GENERAL_CI,
      "cp1256"   => CHARSET_CP1256_GENERAL_CI,
      "cp1257"   => CHARSET_CP1257_GENERAL_CI,
      "utf32"    => CHARSET_UTF32_GENERAL_CI,
      "binary"   => CHARSET_BINARY,
    }.freeze

    def self.find(mysql_encoding)
      unless rb_encoding = RUBY_ENCODINGS[mysql_encoding]
        raise ArgumentError, "Unknown or unsupported encoding: #{mysql_encoding}"
      end

      ::Encoding.find(rb_encoding)
    end

    def self.charset(mysql_encoding)
      CHARSETS[mysql_encoding]
    end
  end
end
