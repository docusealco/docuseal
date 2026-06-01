# -*- encoding: utf-8 -*-

require 'hexapdf/font/type1'

FONT_TIMES = HexaPDF::Font::Type1::Font.from_afm(File.join(HexaPDF.data_dir, 'afm', "Times-Roman.afm"))
FONT_SYMBOL = HexaPDF::Font::Type1::Font.from_afm(File.join(HexaPDF.data_dir, 'afm', "Symbol.afm"))
