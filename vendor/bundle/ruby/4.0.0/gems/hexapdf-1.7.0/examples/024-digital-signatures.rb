# # Images
#
# This example shows how to embed images into a PDF document, directly on a
# page's canvas and through the high-level [HexaPDF::Composer].
#
# Usage:
# : `ruby digital-signatures.rb`
#

require 'hexapdf'
require HexaPDF.data_dir + '/cert/demo_cert.rb'

doc = if ARGV[0]
        HexaPDF::Document.open(ARGV[0])
      else
        HexaPDF::Document.new.pages.add.document
      end
doc.sign("digital-signatures.pdf",
         reason: 'Some reason',
         certificate: HexaPDF.demo_cert.cert,
         key: HexaPDF.demo_cert.key,
         certificate_chain: [HexaPDF.demo_cert.sub_ca,
                             HexaPDF.demo_cert.root_ca])
