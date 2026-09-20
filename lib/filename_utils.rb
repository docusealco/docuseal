# frozen_string_literal: true

module FilenameUtils
  DANGEROUS_EXTENSIONS = %w[
    exe com bat cmd scr pif vbs vbe js jse wsf wsh msi msp
    hta cpl jar app deb rpm dmg pkg mpkg dll so dylib sys
    inf reg ps1 psm1 psd1 ps1xml psc1 pssc vb vba
    sh bash zsh fish run out bin elf gadget workflow lnk scf
    url desktop application action apk ipa xap appx
    appxbundle msix msixbundle diagcab diagpkg msc ocx
    drv ins isp mst paf prf shb shs slk ws wsc inf1 inf2
  ].freeze

  DANGEROUS_EXTENSIONS_REGEXP = /\.(#{Regexp.union(DANGEROUS_EXTENSIONS).source})\W*\z/i

  module_function

  def dangerous_extension(filename)
    ActiveStorage::Filename.wrap(filename).sanitized[DANGEROUS_EXTENSIONS_REGEXP, 1]&.downcase
  end
end
