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

      # The built-in encoding of the Symbol font.
      #
      # See: PDF2.0 sD.5
      class SymbolEncoding < Base

        def initialize #:nodoc:
          super
          @code_to_name = {
            0101 => :Alpha,
            0102 => :Beta,
            0103 => :Chi,
            0104 => :Delta,
            0105 => :Epsilon,
            0110 => :Eta,
            0240 => :Euro,
            0107 => :Gamma,
            0301 => :Ifraktur,
            0111 => :Iota,
            0113 => :Kappa,
            0114 => :Lambda,
            0115 => :Mu,
            0116 => :Nu,
            0127 => :Omega,
            0117 => :Omicron,
            0106 => :Phi,
            0120 => :Pi,
            0131 => :Psi,
            0302 => :Rfraktur,
            0122 => :Rho,
            0123 => :Sigma,
            0124 => :Tau,
            0121 => :Theta,
            0125 => :Upsilon,
            0241 => :Upsilon1,
            0130 => :Xi,
            0132 => :Zeta,
            0300 => :aleph,
            0141 => :alpha,
            0046 => :ampersand,
            0320 => :angle,
            0341 => :angleleft,
            0361 => :angleright,
            0273 => :approxequal,
            0253 => :arrowboth,
            0333 => :arrowdblboth,
            0337 => :arrowdbldown,
            0334 => :arrowdblleft,
            0336 => :arrowdblright,
            0335 => :arrowdblup,
            0257 => :arrowdown,
            0276 => :arrowhorizex,
            0254 => :arrowleft,
            0256 => :arrowright,
            0255 => :arrowup,
            0275 => :arrowvertex,
            0052 => :asteriskmath,
            0174 => :bar,
            0142 => :beta,
            0173 => :braceleft,
            0175 => :braceright,
            0354 => :bracelefttp,
            0355 => :braceleftmid,
            0356 => :braceleftbt,
            0374 => :bracerighttp,
            0375 => :bracerightmid,
            0376 => :bracerightbt,
            0357 => :braceex,
            0133 => :bracketleft,
            0135 => :bracketright,
            0351 => :bracketlefttp,
            0352 => :bracketleftex,
            0353 => :bracketleftbt,
            0371 => :bracketrighttp,
            0372 => :bracketrightex,
            0373 => :bracketrightbt,
            0267 => :bullet,
            0277 => :carriagereturn,
            0143 => :chi,
            0304 => :circlemultiply,
            0305 => :circleplus,
            0247 => :club,
            0072 => :colon,
            0054 => :comma,
            0100 => :congruent,
            0343 => :copyrightsans,
            0323 => :copyrightserif,
            0260 => :degree,
            0144 => :delta,
            0250 => :diamond,
            0270 => :divide,
            0327 => :dotmath,
            0070 => :eight,
            0316 => :element,
            0274 => :ellipsis,
            0306 => :emptyset,
            0145 => :epsilon,
            0075 => :equal,
            0272 => :equivalence,
            0150 => :eta,
            0041 => :exclam,
            0044 => :existential,
            0065 => :five,
            0246 => :florin,
            0064 => :four,
            0244 => :fraction,
            0147 => :gamma,
            0321 => :gradient,
            0076 => :greater,
            0263 => :greaterequal,
            0251 => :heart,
            0245 => :infinity,
            0362 => :integral,
            0363 => :integraltp,
            0364 => :integralex,
            0365 => :integralbt,
            0307 => :intersection,
            0151 => :iota,
            0153 => :kappa,
            0154 => :lambda,
            0074 => :less,
            0243 => :lessequal,
            0331 => :logicaland,
            0330 => :logicalnot,
            0332 => :logicalor,
            0340 => :lozenge,
            0055 => :minus,
            0242 => :minute,
            0155 => :mu,
            0264 => :multiply,
            0071 => :nine,
            0317 => :notelement,
            0271 => :notequal,
            0313 => :notsubset,
            0156 => :nu,
            0043 => :numbersign,
            0167 => :omega,
            0166 => :omega1,
            0157 => :omicron,
            0061 => :one,
            0050 => :parenleft,
            0051 => :parenright,
            0346 => :parenlefttp,
            0347 => :parenleftex,
            0350 => :parenleftbt,
            0366 => :parenrighttp,
            0367 => :parenrightex,
            0370 => :parenrightbt,
            0266 => :partialdiff,
            0045 => :percent,
            0056 => :period,
            0136 => :perpendicular,
            0146 => :phi,
            0152 => :phi1,
            0160 => :pi,
            0053 => :plus,
            0261 => :plusminus,
            0325 => :product,
            0314 => :propersubset,
            0311 => :propersuperset,
            0265 => :proportional,
            0171 => :psi,
            0077 => :question,
            0326 => :radical,
            0140 => :radicalex,
            0315 => :reflexsubset,
            0312 => :reflexsuperset,
            0342 => :registersans,
            0322 => :registerserif,
            0162 => :rho,
            0262 => :second,
            0073 => :semicolon,
            0067 => :seven,
            0163 => :sigma,
            0126 => :sigma1,
            0176 => :similar,
            0066 => :six,
            0057 => :slash,
            0040 => :space,
            0252 => :spade,
            0047 => :suchthat,
            0345 => :summation,
            0164 => :tau,
            0134 => :therefore,
            0161 => :theta,
            0112 => :theta1,
            0063 => :three,
            0344 => :trademarksans,
            0324 => :trademarkserif,
            0062 => :two,
            0137 => :underscore,
            0310 => :union,
            0042 => :universal,
            0165 => :upsilon,
            0303 => :weierstrass,
            0170 => :xi,
            0060 => :zero,
            0172 => :zeta,
          }
        end

      end

    end
  end
end
