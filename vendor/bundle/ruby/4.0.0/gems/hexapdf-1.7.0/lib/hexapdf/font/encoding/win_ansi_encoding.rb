# -*- encoding: utf-8; frozen_string_literal: true -*-
#
#--
# This file is part of HexaPDF.
#
# HexaPDF - A Versatile PDF Creation and Manipulation Library For Ruby
# Copyright (C) 2014-2025 Thomas Leitner
#
# HexaPDF is free software: you can redistribute it and/or modify it
# under the terms of the GNU Affero General Public License version 3 as
# published by the Free Software Foundation with the addition of the
# following permission added to Section 15 as permitted in Section 7(a):
# FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
# THOMAS LEITNER, THOMAS LEITNER DISCLAIMS THE WARRANTY OF NON
# INFRINGEMENT OF THIRD PARTY RIGHTS.
#
# HexaPDF is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public
# License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with HexaPDF. If not, see <http://www.gnu.org/licenses/>.
#
# The interactive user interfaces in modified source and object code
# versions of HexaPDF must display Appropriate Legal Notices, as required
# under Section 5 of the GNU Affero General Public License version 3.
#
# In accordance with Section 7(b) of the GNU Affero General Public
# License, a covered work must retain the producer line in every PDF that
# is created or manipulated using HexaPDF.
#
# If the GNU Affero General Public License doesn't fit your need,
# commercial licenses are available at <https://gettalong.at/hexapdf/>.
#++

require 'hexapdf/font/encoding/base'

module HexaPDF
  module Font
    module Encoding

      # The Windows Code Page 1252, the standard Windows encoding for Latin texts.
      #
      # See: PDF2.0 sD.1, sD.2
      class WinAnsiEncoding < Base

        def initialize #:nodoc:
          super
          @encoding_name = :WinAnsiEncoding
          @code_to_name = {
            0101 => :A,
            0306 => :AE,
            0301 => :Aacute,
            0302 => :Acircumflex,
            0304 => :Adieresis,
            0300 => :Agrave,
            0305 => :Aring,
            0303 => :Atilde,
            0102 => :B,
            0103 => :C,
            0307 => :Ccedilla,
            0104 => :D,
            0105 => :E,
            0311 => :Eacute,
            0312 => :Ecircumflex,
            0313 => :Edieresis,
            0310 => :Egrave,
            0320 => :Eth,
            0200 => :Euro,
            0106 => :F,
            0107 => :G,
            0110 => :H,
            0111 => :I,
            0315 => :Iacute,
            0316 => :Icircumflex,
            0317 => :Idieresis,
            0314 => :Igrave,
            0112 => :J,
            0113 => :K,
            0114 => :L,
            0115 => :M,
            0116 => :N,
            0321 => :Ntilde,
            0117 => :O,
            0214 => :OE,
            0323 => :Oacute,
            0324 => :Ocircumflex,
            0326 => :Odieresis,
            0322 => :Ograve,
            0330 => :Oslash,
            0325 => :Otilde,
            0120 => :P,
            0121 => :Q,
            0122 => :R,
            0123 => :S,
            0212 => :Scaron,
            0124 => :T,
            0336 => :Thorn,
            0125 => :U,
            0332 => :Uacute,
            0333 => :Ucircumflex,
            0334 => :Udieresis,
            0331 => :Ugrave,
            0126 => :V,
            0127 => :W,
            0130 => :X,
            0131 => :Y,
            0335 => :Yacute,
            0237 => :Ydieresis,
            0132 => :Z,
            0216 => :Zcaron,
            0141 => :a,
            0341 => :aacute,
            0342 => :acircumflex,
            0264 => :acute,
            0344 => :adieresis,
            0346 => :ae,
            0340 => :agrave,
            0046 => :ampersand,
            0345 => :aring,
            0136 => :asciicircum,
            0176 => :asciitilde,
            0052 => :asterisk,
            0100 => :at,
            0343 => :atilde,
            0142 => :b,
            0134 => :backslash,
            0174 => :bar,
            0173 => :braceleft,
            0175 => :braceright,
            0133 => :bracketleft,
            0135 => :bracketright,
            0246 => :brokenbar,
            0225 => :bullet,
            0143 => :c,
            0347 => :ccedilla,
            0270 => :cedilla,
            0242 => :cent,
            0210 => :circumflex,
            0072 => :colon,
            0054 => :comma,
            0251 => :copyright,
            0244 => :currency,
            0144 => :d,
            0206 => :dagger,
            0207 => :daggerdbl,
            0260 => :degree,
            0250 => :dieresis,
            0367 => :divide,
            0044 => :dollar,
            0145 => :e,
            0351 => :eacute,
            0352 => :ecircumflex,
            0353 => :edieresis,
            0350 => :egrave,
            0070 => :eight,
            0205 => :ellipsis,
            0227 => :emdash,
            0226 => :endash,
            0075 => :equal,
            0360 => :eth,
            0041 => :exclam,
            0241 => :exclamdown,
            0146 => :f,
            0065 => :five,
            0203 => :florin,
            0064 => :four,
            0147 => :g,
            0337 => :germandbls,
            0140 => :grave,
            0076 => :greater,
            0253 => :guillemotleft,
            0273 => :guillemotright,
            0213 => :guilsinglleft,
            0233 => :guilsinglright,
            0150 => :h,
            0055 => :hyphen,
            0151 => :i,
            0355 => :iacute,
            0356 => :icircumflex,
            0357 => :idieresis,
            0354 => :igrave,
            0152 => :j,
            0153 => :k,
            0154 => :l,
            0074 => :less,
            0254 => :logicalnot,
            0155 => :m,
            0257 => :macron,
            0265 => :mu,
            0327 => :multiply,
            0156 => :n,
            0071 => :nine,
            0361 => :ntilde,
            0043 => :numbersign,
            0157 => :o,
            0363 => :oacute,
            0364 => :ocircumflex,
            0366 => :odieresis,
            0234 => :oe,
            0362 => :ograve,
            0061 => :one,
            0275 => :onehalf,
            0274 => :onequarter,
            0271 => :onesuperior,
            0252 => :ordfeminine,
            0272 => :ordmasculine,
            0370 => :oslash,
            0365 => :otilde,
            0160 => :p,
            0266 => :paragraph,
            0050 => :parenleft,
            0051 => :parenright,
            0045 => :percent,
            0056 => :period,
            0267 => :periodcentered,
            0211 => :perthousand,
            0053 => :plus,
            0261 => :plusminus,
            0161 => :q,
            0077 => :question,
            0277 => :questiondown,
            0042 => :quotedbl,
            0204 => :quotedblbase,
            0223 => :quotedblleft,
            0224 => :quotedblright,
            0221 => :quoteleft,
            0222 => :quoteright,
            0202 => :quotesinglbase,
            0047 => :quotesingle,
            0162 => :r,
            0256 => :registered,
            0163 => :s,
            0232 => :scaron,
            0247 => :section,
            0073 => :semicolon,
            0067 => :seven,
            0066 => :six,
            0057 => :slash,
            0040 => :space,
            0243 => :sterling,
            0164 => :t,
            0376 => :thorn,
            0063 => :three,
            0276 => :threequarters,
            0263 => :threesuperior,
            0230 => :tilde,
            0231 => :trademark,
            0062 => :two,
            0262 => :twosuperior,
            0165 => :u,
            0372 => :uacute,
            0373 => :ucircumflex,
            0374 => :udieresis,
            0371 => :ugrave,
            0137 => :underscore,
            0166 => :v,
            0167 => :w,
            0170 => :x,
            0171 => :y,
            0375 => :yacute,
            0377 => :ydieresis,
            0245 => :yen,
            0172 => :z,
            0236 => :zcaron,
            0060 => :zero,
            # additions due to PDF2.0 sD.2 footnote 5,6
            0240 => :space,
            0255 => :hyphen,
          }
          # additions due to PDF2.0 sD.2 footnote 3
          041.upto(255) do |i|
            next if @code_to_name.key?(i)
            @code_to_name[i] = :bullet
          end
        end

      end

    end
  end
end
