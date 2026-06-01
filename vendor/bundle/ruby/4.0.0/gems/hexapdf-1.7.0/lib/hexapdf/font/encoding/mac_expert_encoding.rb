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

      # The MacExpertEncoding for Latin texts.
      #
      # See: PDF2.0 sD.4
      class MacExpertEncoding < Base

        def initialize #:nodoc:
          super
          @encoding_name = :MacExpertEncoding
          @code_to_name = {
            0276 => :AEsmall,
            0207 => :Aacutesmall,
            0211 => :Acircumflexsmall,
            0047 => :Acutesmall,
            0212 => :Adieresissmall,
            0210 => :Agravesmall,
            0214 => :Aringsmall,
            0141 => :Asmall,
            0213 => :Atildesmall,
            0363 => :Brevesmall,
            0142 => :Bsmall,
            0256 => :Caronsmall,
            0215 => :Ccedillasmall,
            0311 => :Cedillasmall,
            0136 => :Circumflexsmall,
            0143 => :Csmall,
            0254 => :Dieresissmall,
            0372 => :Dotaccentsmall,
            0144 => :Dsmall,
            0216 => :Eacutesmall,
            0220 => :Ecircumflexsmall,
            0221 => :Edieresissmall,
            0217 => :Egravesmall,
            0145 => :Esmall,
            0104 => :Ethsmall,
            0146 => :Fsmall,
            0140 => :Gravesmall,
            0147 => :Gsmall,
            0150 => :Hsmall,
            0042 => :Hungarumlautsmall,
            0222 => :Iacutesmall,
            0224 => :Icircumflexsmall,
            0225 => :Idieresissmall,
            0223 => :Igravesmall,
            0151 => :Ismall,
            0152 => :Jsmall,
            0153 => :Ksmall,
            0302 => :Lslashsmall,
            0154 => :Lsmall,
            0364 => :Macronsmall,
            0155 => :Msmall,
            0156 => :Nsmall,
            0226 => :Ntildesmall,
            0317 => :OEsmall,
            0227 => :Oacutesmall,
            0231 => :Ocircumflexsmall,
            0232 => :Odieresissmall,
            0362 => :Ogoneksmall,
            0230 => :Ogravesmall,
            0277 => :Oslashsmall,
            0157 => :Osmall,
            0233 => :Otildesmall,
            0160 => :Psmall,
            0161 => :Qsmall,
            0373 => :Ringsmall,
            0162 => :Rsmall,
            0247 => :Scaronsmall,
            0163 => :Ssmall,
            0271 => :Thornsmall,
            0176 => :Tildesmall,
            0164 => :Tsmall,
            0234 => :Uacutesmall,
            0236 => :Ucircumflexsmall,
            0237 => :Udieresissmall,
            0235 => :Ugravesmall,
            0165 => :Usmall,
            0166 => :Vsmall,
            0167 => :Wsmall,
            0170 => :Xsmall,
            0264 => :Yacutesmall,
            0330 => :Ydieresissmall,
            0171 => :Ysmall,
            0275 => :Zcaronsmall,
            0172 => :Zsmall,
            0046 => :ampersandsmall,
            0201 => :asuperior,
            0365 => :bsuperior,
            0251 => :centinferior,
            0043 => :centoldstyle,
            0202 => :centsuperior,
            0072 => :colon,
            0173 => :colonmonetary,
            0054 => :comma,
            0262 => :commainferior,
            0370 => :commasuperior,
            0266 => :dollarinferior,
            0044 => :dollaroldstyle,
            0045 => :dollarsuperior,
            0353 => :dsuperior,
            0245 => :eightinferior,
            0070 => :eightoldstyle,
            0241 => :eightsuperior,
            0344 => :esuperior,
            0326 => :exclamdownsmall,
            0041 => :exclamsmall,
            0126 => :ff,
            0131 => :ffi,
            0132 => :ffl,
            0127 => :fi,
            0320 => :figuredash,
            0114 => :fiveeighths,
            0260 => :fiveinferior,
            0065 => :fiveoldstyle,
            0336 => :fivesuperior,
            0130 => :fl,
            0242 => :fourinferior,
            0064 => :fouroldstyle,
            0335 => :foursuperior,
            0057 => :fraction,
            0055 => :hyphen,
            0137 => :hypheninferior,
            0321 => :hyphensuperior,
            0351 => :isuperior,
            0361 => :lsuperior,
            0367 => :msuperior,
            0273 => :nineinferior,
            0071 => :nineoldstyle,
            0341 => :ninesuperior,
            0366 => :nsuperior,
            0053 => :onedotenleader,
            0112 => :oneeighth,
            0174 => :onefitted,
            0110 => :onehalf,
            0301 => :oneinferior,
            0061 => :oneoldstyle,
            0107 => :onequarter,
            0332 => :onesuperior,
            0116 => :onethird,
            0257 => :osuperior,
            0133 => :parenleftinferior,
            0050 => :parenleftsuperior,
            0135 => :parenrightinferior,
            0051 => :parenrightsuperior,
            0056 => :period,
            0263 => :periodinferior,
            0371 => :periodsuperior,
            0300 => :questiondownsmall,
            0077 => :questionsmall,
            0345 => :rsuperior,
            0175 => :rupiah,
            0073 => :semicolon,
            0115 => :seveneighths,
            0246 => :seveninferior,
            0067 => :sevenoldstyle,
            0340 => :sevensuperior,
            0244 => :sixinferior,
            0066 => :sixoldstyle,
            0337 => :sixsuperior,
            0040 => :space,
            0352 => :ssuperior,
            0113 => :threeeighths,
            0243 => :threeinferior,
            0063 => :threeoldstyle,
            0111 => :threequarters,
            0075 => :threequartersemdash,
            0334 => :threesuperior,
            0346 => :tsuperior,
            0052 => :twodotenleader,
            0252 => :twoinferior,
            0062 => :twooldstyle,
            0333 => :twosuperior,
            0117 => :twothirds,
            0274 => :zeroinferior,
            0060 => :zerooldstyle,
            0342 => :zerosuperior,
          }
        end

      end

    end
  end
end
