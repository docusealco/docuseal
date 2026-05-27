#ifndef TRILOGY_CHARSET_H
#define TRILOGY_CHARSET_H

#define TRILOGY_CHARSETS(XX)                                                                                           \
    XX(TRILOGY_CHARSET_NONE, 0)                                                                                        \
    XX(TRILOGY_CHARSET_BIG5_CHINESE_CI, 1)                                                                             \
    XX(TRILOGY_CHARSET_LATIN2_CZECH_CS, 2)                                                                             \
    XX(TRILOGY_CHARSET_DEC8_SWEDISH_CI, 3)                                                                             \
    XX(TRILOGY_CHARSET_CP850_GENERAL_CI, 4)                                                                            \
    XX(TRILOGY_CHARSET_LATIN1_GERMAN1_CI, 5)                                                                           \
    XX(TRILOGY_CHARSET_HP8_ENGLISH_CI, 6)                                                                              \
    XX(TRILOGY_CHARSET_KOI8R_GENERAL_CI, 7)                                                                            \
    XX(TRILOGY_CHARSET_LATIN1_SWEDISH_CI, 8)                                                                           \
    XX(TRILOGY_CHARSET_LATIN2_GENERAL_CI, 9)                                                                           \
    XX(TRILOGY_CHARSET_SWE7_SWEDISH_CI, 10)                                                                            \
    XX(TRILOGY_CHARSET_ASCII_GENERAL_CI, 11)                                                                           \
    XX(TRILOGY_CHARSET_UJIS_JAPANESE_CI, 12)                                                                           \
    XX(TRILOGY_CHARSET_SJIS_JAPANESE_CI, 13)                                                                           \
    XX(TRILOGY_CHARSET_CP1251_BULGARIAN_CI, 14)                                                                        \
    XX(TRILOGY_CHARSET_LATIN1_DANISH_CI, 15)                                                                           \
    XX(TRILOGY_CHARSET_HEBREW_GENERAL_CI, 16)                                                                          \
    XX(TRILOGY_CHARSET_TIS620_THAI_CI, 18)                                                                             \
    XX(TRILOGY_CHARSET_EUCKR_KOREAN_CI, 19)                                                                            \
    XX(TRILOGY_CHARSET_LATIN7_ESTONIAN_CS, 20)                                                                         \
    XX(TRILOGY_CHARSET_LATIN2_HUNGARIAN_CI, 21)                                                                        \
    XX(TRILOGY_CHARSET_KOI8U_GENERAL_CI, 22)                                                                           \
    XX(TRILOGY_CHARSET_CP1251_UKRAINIAN_CI, 23)                                                                        \
    XX(TRILOGY_CHARSET_GB2312_CHINESE_CI, 24)                                                                          \
    XX(TRILOGY_CHARSET_GREEK_GENERAL_CI, 25)                                                                           \
    XX(TRILOGY_CHARSET_CP1250_GENERAL_CI, 26)                                                                          \
    XX(TRILOGY_CHARSET_LATIN2_CROATIAN_CI, 27)                                                                         \
    XX(TRILOGY_CHARSET_GBK_CHINESE_CI, 28)                                                                             \
    XX(TRILOGY_CHARSET_CP1257_LITHUANIAN_CI, 29)                                                                       \
    XX(TRILOGY_CHARSET_LATIN5_TURKISH_CI, 30)                                                                          \
    XX(TRILOGY_CHARSET_LATIN1_GERMAN2_CI, 31)                                                                          \
    XX(TRILOGY_CHARSET_ARMSCII8_GENERAL_CI, 32)                                                                        \
    XX(TRILOGY_CHARSET_UTF8_GENERAL_CI, 33)                                                                            \
    XX(TRILOGY_CHARSET_CP1250_CZECH_CS, 34)                                                                            \
    XX(TRILOGY_CHARSET_UCS2_GENERAL_CI, 35)                                                                            \
    XX(TRILOGY_CHARSET_CP866_GENERAL_CI, 36)                                                                           \
    XX(TRILOGY_CHARSET_KEYBCS2_GENERAL_CI, 37)                                                                         \
    XX(TRILOGY_CHARSET_MACCE_GENERAL_CI, 38)                                                                           \
    XX(TRILOGY_CHARSET_MACROMAN_GENERAL_CI, 39)                                                                        \
    XX(TRILOGY_CHARSET_CP852_GENERAL_CI, 40)                                                                           \
    XX(TRILOGY_CHARSET_LATIN7_GENERAL_CI, 41)                                                                          \
    XX(TRILOGY_CHARSET_LATIN7_GENERAL_CS, 42)                                                                          \
    XX(TRILOGY_CHARSET_MACCE_BIN, 43)                                                                                  \
    XX(TRILOGY_CHARSET_CP1250_CROATIAN_CI, 44)                                                                         \
    XX(TRILOGY_CHARSET_UTF8MB4_GENERAL_CI, 45)                                                                         \
    XX(TRILOGY_CHARSET_UTF8MB4_BIN, 46)                                                                                \
    XX(TRILOGY_CHARSET_LATIN1_BIN, 47)                                                                                 \
    XX(TRILOGY_CHARSET_LATIN1_GENERAL_CI, 48)                                                                          \
    XX(TRILOGY_CHARSET_LATIN1_GENERAL_CS, 49)                                                                          \
    XX(TRILOGY_CHARSET_CP1251_BIN, 50)                                                                                 \
    XX(TRILOGY_CHARSET_CP1251_GENERAL_CI, 51)                                                                          \
    XX(TRILOGY_CHARSET_CP1251_GENERAL_CS, 52)                                                                          \
    XX(TRILOGY_CHARSET_MACROMAN_BIN, 53)                                                                               \
    XX(TRILOGY_CHARSET_UTF16_GENERAL_CI, 54)                                                                           \
    XX(TRILOGY_CHARSET_UTF16_BIN, 55)                                                                                  \
    XX(TRILOGY_CHARSET_CP1256_GENERAL_CI, 57)                                                                          \
    XX(TRILOGY_CHARSET_CP1257_BIN, 58)                                                                                 \
    XX(TRILOGY_CHARSET_CP1257_GENERAL_CI, 59)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_GENERAL_CI, 60)                                                                           \
    XX(TRILOGY_CHARSET_UTF32_BIN, 61)                                                                                  \
    XX(TRILOGY_CHARSET_BINARY, 63)                                                                                     \
    XX(TRILOGY_CHARSET_ARMSCII8_BIN, 64)                                                                               \
    XX(TRILOGY_CHARSET_ASCII_BIN, 65)                                                                                  \
    XX(TRILOGY_CHARSET_CP1250_BIN, 66)                                                                                 \
    XX(TRILOGY_CHARSET_CP1256_BIN, 67)                                                                                 \
    XX(TRILOGY_CHARSET_CP866_BIN, 68)                                                                                  \
    XX(TRILOGY_CHARSET_DEC8_BIN, 69)                                                                                   \
    XX(TRILOGY_CHARSET_GREEK_BIN, 70)                                                                                  \
    XX(TRILOGY_CHARSET_HEBREW_BIN, 71)                                                                                 \
    XX(TRILOGY_CHARSET_HP8_BIN, 72)                                                                                    \
    XX(TRILOGY_CHARSET_KEYBCS2_BIN, 73)                                                                                \
    XX(TRILOGY_CHARSET_KOI8R_BIN, 74)                                                                                  \
    XX(TRILOGY_CHARSET_KOI8U_BIN, 75)                                                                                  \
    XX(TRILOGY_CHARSET_LATIN2_BIN, 77)                                                                                 \
    XX(TRILOGY_CHARSET_LATIN5_BIN, 78)                                                                                 \
    XX(TRILOGY_CHARSET_LATIN7_BIN, 79)                                                                                 \
    XX(TRILOGY_CHARSET_CP850_BIN, 80)                                                                                  \
    XX(TRILOGY_CHARSET_CP852_BIN, 81)                                                                                  \
    XX(TRILOGY_CHARSET_SWE7_BIN, 82)                                                                                   \
    XX(TRILOGY_CHARSET_UTF8_BIN, 83)                                                                                   \
    XX(TRILOGY_CHARSET_BIG5_BIN, 84)                                                                                   \
    XX(TRILOGY_CHARSET_EUCKR_BIN, 85)                                                                                  \
    XX(TRILOGY_CHARSET_GB2312_BIN, 86)                                                                                 \
    XX(TRILOGY_CHARSET_GBK_BIN, 87)                                                                                    \
    XX(TRILOGY_CHARSET_SJIS_BIN, 88)                                                                                   \
    XX(TRILOGY_CHARSET_TIS620_BIN, 89)                                                                                 \
    XX(TRILOGY_CHARSET_UCS2_BIN, 90)                                                                                   \
    XX(TRILOGY_CHARSET_UJIS_BIN, 91)                                                                                   \
    XX(TRILOGY_CHARSET_GEOSTD8_GENERAL_CI, 92)                                                                         \
    XX(TRILOGY_CHARSET_GEOSTD8_BIN, 93)                                                                                \
    XX(TRILOGY_CHARSET_LATIN1_SPANISH_CI, 94)                                                                          \
    XX(TRILOGY_CHARSET_CP932_JAPANESE_CI, 95)                                                                          \
    XX(TRILOGY_CHARSET_CP932_BIN, 96)                                                                                  \
    XX(TRILOGY_CHARSET_EUCJPMS_JAPANESE_CI, 97)                                                                        \
    XX(TRILOGY_CHARSET_EUCJPMS_BIN, 98)                                                                                \
    XX(TRILOGY_CHARSET_CP1250_POLISH_CI, 99)                                                                           \
    XX(TRILOGY_CHARSET_UTF16_UNICODE_CI, 101)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_ICELANDIC_CI, 102)                                                                        \
    XX(TRILOGY_CHARSET_UTF16_LATVIAN_CI, 103)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_ROMANIAN_CI, 104)                                                                         \
    XX(TRILOGY_CHARSET_UTF16_SLOVENIAN_CI, 105)                                                                        \
    XX(TRILOGY_CHARSET_UTF16_POLISH_CI, 106)                                                                           \
    XX(TRILOGY_CHARSET_UTF16_ESTONIAN_CI, 107)                                                                         \
    XX(TRILOGY_CHARSET_UTF16_SPANISH_CI, 108)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_SWEDISH_CI, 109)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_TURKISH_CI, 110)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_CZECH_CI, 111)                                                                            \
    XX(TRILOGY_CHARSET_UTF16_DANISH_CI, 112)                                                                           \
    XX(TRILOGY_CHARSET_UTF16_LITHUANIAN_CI, 113)                                                                       \
    XX(TRILOGY_CHARSET_UTF16_SLOVAK_CI, 114)                                                                           \
    XX(TRILOGY_CHARSET_UTF16_SPANISH2_CI, 115)                                                                         \
    XX(TRILOGY_CHARSET_UTF16_ROMAN_CI, 116)                                                                            \
    XX(TRILOGY_CHARSET_UTF16_PERSIAN_CI, 117)                                                                          \
    XX(TRILOGY_CHARSET_UTF16_ESPERANTO_CI, 118)                                                                        \
    XX(TRILOGY_CHARSET_UTF16_HUNGARIAN_CI, 119)                                                                        \
    XX(TRILOGY_CHARSET_UTF16_SINHALA_CI, 120)                                                                          \
    XX(TRILOGY_CHARSET_UCS2_UNICODE_CI, 128)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_ICELANDIC_CI, 129)                                                                         \
    XX(TRILOGY_CHARSET_UCS2_LATVIAN_CI, 130)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_ROMANIAN_CI, 131)                                                                          \
    XX(TRILOGY_CHARSET_UCS2_SLOVENIAN_CI, 132)                                                                         \
    XX(TRILOGY_CHARSET_UCS2_POLISH_CI, 133)                                                                            \
    XX(TRILOGY_CHARSET_UCS2_ESTONIAN_CI, 134)                                                                          \
    XX(TRILOGY_CHARSET_UCS2_SPANISH_CI, 135)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_SWEDISH_CI, 136)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_TURKISH_CI, 137)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_CZECH_CI, 138)                                                                             \
    XX(TRILOGY_CHARSET_UCS2_DANISH_CI, 139)                                                                            \
    XX(TRILOGY_CHARSET_UCS2_LITHUANIAN_CI, 140)                                                                        \
    XX(TRILOGY_CHARSET_UCS2_SLOVAK_CI, 141)                                                                            \
    XX(TRILOGY_CHARSET_UCS2_SPANISH2_CI, 142)                                                                          \
    XX(TRILOGY_CHARSET_UCS2_ROMAN_CI, 143)                                                                             \
    XX(TRILOGY_CHARSET_UCS2_PERSIAN_CI, 144)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_ESPERANTO_CI, 145)                                                                         \
    XX(TRILOGY_CHARSET_UCS2_HUNGARIAN_CI, 146)                                                                         \
    XX(TRILOGY_CHARSET_UCS2_SINHALA_CI, 147)                                                                           \
    XX(TRILOGY_CHARSET_UCS2_GENERAL_MYSQL500_CI, 159)                                                                  \
    XX(TRILOGY_CHARSET_UTF32_UNICODE_CI, 160)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_ICELANDIC_CI, 161)                                                                        \
    XX(TRILOGY_CHARSET_UTF32_LATVIAN_CI, 162)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_ROMANIAN_CI, 163)                                                                         \
    XX(TRILOGY_CHARSET_UTF32_SLOVENIAN_CI, 164)                                                                        \
    XX(TRILOGY_CHARSET_UTF32_POLISH_CI, 165)                                                                           \
    XX(TRILOGY_CHARSET_UTF32_ESTONIAN_CI, 166)                                                                         \
    XX(TRILOGY_CHARSET_UTF32_SPANISH_CI, 167)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_SWEDISH_CI, 168)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_TURKISH_CI, 169)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_CZECH_CI, 170)                                                                            \
    XX(TRILOGY_CHARSET_UTF32_DANISH_CI, 171)                                                                           \
    XX(TRILOGY_CHARSET_UTF32_LITHUANIAN_CI, 172)                                                                       \
    XX(TRILOGY_CHARSET_UTF32_SLOVAK_CI, 173)                                                                           \
    XX(TRILOGY_CHARSET_UTF32_SPANISH2_CI, 174)                                                                         \
    XX(TRILOGY_CHARSET_UTF32_ROMAN_CI, 175)                                                                            \
    XX(TRILOGY_CHARSET_UTF32_PERSIAN_CI, 176)                                                                          \
    XX(TRILOGY_CHARSET_UTF32_ESPERANTO_CI, 177)                                                                        \
    XX(TRILOGY_CHARSET_UTF32_HUNGARIAN_CI, 178)                                                                        \
    XX(TRILOGY_CHARSET_UTF32_SINHALA_CI, 179)                                                                          \
    XX(TRILOGY_CHARSET_UTF8_UNICODE_CI, 192)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_ICELANDIC_CI, 193)                                                                         \
    XX(TRILOGY_CHARSET_UTF8_LATVIAN_CI, 194)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_ROMANIAN_CI, 195)                                                                          \
    XX(TRILOGY_CHARSET_UTF8_SLOVENIAN_CI, 196)                                                                         \
    XX(TRILOGY_CHARSET_UTF8_POLISH_CI, 197)                                                                            \
    XX(TRILOGY_CHARSET_UTF8_ESTONIAN_CI, 198)                                                                          \
    XX(TRILOGY_CHARSET_UTF8_SPANISH_CI, 199)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_SWEDISH_CI, 200)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_TURKISH_CI, 201)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_CZECH_CI, 202)                                                                             \
    XX(TRILOGY_CHARSET_UTF8_DANISH_CI, 203)                                                                            \
    XX(TRILOGY_CHARSET_UTF8_LITHUANIAN_CI, 204)                                                                        \
    XX(TRILOGY_CHARSET_UTF8_SLOVAK_CI, 205)                                                                            \
    XX(TRILOGY_CHARSET_UTF8_SPANISH2_CI, 206)                                                                          \
    XX(TRILOGY_CHARSET_UTF8_ROMAN_CI, 207)                                                                             \
    XX(TRILOGY_CHARSET_UTF8_PERSIAN_CI, 208)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_ESPERANTO_CI, 209)                                                                         \
    XX(TRILOGY_CHARSET_UTF8_HUNGARIAN_CI, 210)                                                                         \
    XX(TRILOGY_CHARSET_UTF8_SINHALA_CI, 211)                                                                           \
    XX(TRILOGY_CHARSET_UTF8_GENERAL_MYSQL500_CI, 223)                                                                  \
    XX(TRILOGY_CHARSET_UTF8MB4_UNICODE_CI, 224)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_ICELANDIC_CI, 225)                                                                      \
    XX(TRILOGY_CHARSET_UTF8MB4_LATVIAN_CI, 226)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_ROMANIAN_CI, 227)                                                                       \
    XX(TRILOGY_CHARSET_UTF8MB4_SLOVENIAN_CI, 228)                                                                      \
    XX(TRILOGY_CHARSET_UTF8MB4_POLISH_CI, 229)                                                                         \
    XX(TRILOGY_CHARSET_UTF8MB4_ESTONIAN_CI, 230)                                                                       \
    XX(TRILOGY_CHARSET_UTF8MB4_SPANISH_CI, 231)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_SWEDISH_CI, 232)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_TURKISH_CI, 233)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_CZECH_CI, 234)                                                                          \
    XX(TRILOGY_CHARSET_UTF8MB4_DANISH_CI, 235)                                                                         \
    XX(TRILOGY_CHARSET_UTF8MB4_LITHUANIAN_CI, 236)                                                                     \
    XX(TRILOGY_CHARSET_UTF8MB4_SLOVAK_CI, 237)                                                                         \
    XX(TRILOGY_CHARSET_UTF8MB4_SPANISH2_CI, 238)                                                                       \
    XX(TRILOGY_CHARSET_UTF8MB4_ROMAN_CI, 239)                                                                          \
    XX(TRILOGY_CHARSET_UTF8MB4_PERSIAN_CI, 240)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_ESPERANTO_CI, 241)                                                                      \
    XX(TRILOGY_CHARSET_UTF8MB4_HUNGARIAN_CI, 242)                                                                      \
    XX(TRILOGY_CHARSET_UTF8MB4_SINHALA_CI, 243)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_GERMAN2_CI, 244)                                                                        \
    XX(TRILOGY_CHARSET_UTF8MB4_CROATIAN_CI, 245)                                                                       \
    XX(TRILOGY_CHARSET_UTF8MB4_UNICODE_520_CI, 246)                                                                    \
    XX(TRILOGY_CHARSET_UTF8MB4_VIETNAMESE_CI, 247)                                                                     \
    XX(TRILOGY_CHARSET_GB18030_CHINESE_CI, 248)                                                                        \
    XX(TRILOGY_CHARSET_GB18030_BIN_CI, 249)                                                                            \
    XX(TRILOGY_CHARSET_GB18030_UNICODE_520_CI, 250)                                                                    \
    XX(TRILOGY_CHARSET_UTF8MB4_0900_AI_CI, 255)

typedef enum {
#define XX(name, code) name = code,
    TRILOGY_CHARSETS(XX)
#undef XX
        TRILOGY_CHARSET_MAX
} TRILOGY_CHARSET_t;

#define TRILOGY_ENCODINGS(XX)                                                                                          \
    XX(TRILOGY_ENCODING_NONE)                                                                                          \
    XX(TRILOGY_ENCODING_BIG5)                                                                                          \
    XX(TRILOGY_ENCODING_LATIN2)                                                                                        \
    XX(TRILOGY_ENCODING_DEC8)                                                                                          \
    XX(TRILOGY_ENCODING_CP850)                                                                                         \
    XX(TRILOGY_ENCODING_LATIN1)                                                                                        \
    XX(TRILOGY_ENCODING_HP8)                                                                                           \
    XX(TRILOGY_ENCODING_KOI8R)                                                                                         \
    XX(TRILOGY_ENCODING_SWE7)                                                                                          \
    XX(TRILOGY_ENCODING_ASCII)                                                                                         \
    XX(TRILOGY_ENCODING_UJIS)                                                                                          \
    XX(TRILOGY_ENCODING_SJIS)                                                                                          \
    XX(TRILOGY_ENCODING_CP1251)                                                                                        \
    XX(TRILOGY_ENCODING_HEBREW)                                                                                        \
    XX(TRILOGY_ENCODING_TIS620)                                                                                        \
    XX(TRILOGY_ENCODING_EUCKR)                                                                                         \
    XX(TRILOGY_ENCODING_LATIN7)                                                                                        \
    XX(TRILOGY_ENCODING_KOI8U)                                                                                         \
    XX(TRILOGY_ENCODING_GB2312)                                                                                        \
    XX(TRILOGY_ENCODING_GREEK)                                                                                         \
    XX(TRILOGY_ENCODING_CP1250)                                                                                        \
    XX(TRILOGY_ENCODING_GBK)                                                                                           \
    XX(TRILOGY_ENCODING_CP1257)                                                                                        \
    XX(TRILOGY_ENCODING_LATIN5)                                                                                        \
    XX(TRILOGY_ENCODING_ARMSCII8)                                                                                      \
    XX(TRILOGY_ENCODING_UTF8)                                                                                          \
    XX(TRILOGY_ENCODING_UCS2)                                                                                          \
    XX(TRILOGY_ENCODING_CP866)                                                                                         \
    XX(TRILOGY_ENCODING_KEYBCS2)                                                                                       \
    XX(TRILOGY_ENCODING_MACCE)                                                                                         \
    XX(TRILOGY_ENCODING_MACROMAN)                                                                                      \
    XX(TRILOGY_ENCODING_CP852)                                                                                         \
    XX(TRILOGY_ENCODING_UTF8MB4)                                                                                       \
    XX(TRILOGY_ENCODING_UTF16)                                                                                         \
    XX(TRILOGY_ENCODING_CP1256)                                                                                        \
    XX(TRILOGY_ENCODING_UTF32)                                                                                         \
    XX(TRILOGY_ENCODING_BINARY)                                                                                        \
    XX(TRILOGY_ENCODING_GEOSTD8)                                                                                       \
    XX(TRILOGY_ENCODING_CP932)                                                                                         \
    XX(TRILOGY_ENCODING_EUCJPMS)

typedef enum {
#define XX(enc) enc,
    TRILOGY_ENCODINGS(XX)
#undef XX
        TRILOGY_ENCODING_MAX
} TRILOGY_ENCODING_t;

/* trilogy_encoding_from_charset - Lookup the TRILOGY_ENCODING_t for a
 * TRILOGY_CHARSET_t collation.
 *
 * charset - A TRILOGY_CHARSET_t value.
 *
 * Returns an TRILOGY_ENCODING_t matching the collation passed in via `charset`.
 */
TRILOGY_ENCODING_t trilogy_encoding_from_charset(TRILOGY_CHARSET_t charset);

#endif
