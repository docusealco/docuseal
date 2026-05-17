# frozen_string_literal: true

# AccountLogo handles validation/sanitization of uploads before they hit
# ActiveStorage. Raster images pass through unchanged. SVGs are scrubbed of
# scripts, event-handler attributes, foreign-object elements, and external
# resource references — the standard XSS surface for inline-embedded SVG.
module AccountLogo
  Sanitized = Struct.new(:io, :filename, :content_type)

  # Allowed top-level/nested SVG-related element + attribute names that
  # carry external resource URIs. We don't enumerate every safe attribute —
  # we instead drop the known-dangerous ones by name pattern.
  EVENT_HANDLER_PREFIX = 'on'
  EXTERNAL_REF_ATTRS = %w[href xlink:href].freeze

  module_function

  def sanitize_upload(uploaded_file)
    content_type = uploaded_file.content_type.to_s

    if content_type == 'image/svg+xml'
      bytes = uploaded_file.read
      uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
      cleaned = sanitize_svg(bytes)
      Sanitized.new(StringIO.new(cleaned), uploaded_file.original_filename.to_s, 'image/svg+xml')
    else
      io = uploaded_file.respond_to?(:tempfile) ? uploaded_file.tempfile : uploaded_file
      Sanitized.new(io, uploaded_file.original_filename.to_s, content_type)
    end
  end

  # Public for spec testing.
  def sanitize_svg(svg_string)
    doc = Nokogiri::XML(svg_string) { |c| c.nonet.noblanks }

    doc.traverse do |node|
      next unless node.element?

      local = node.name.to_s.downcase.sub(/.*:/, '')
      if local == 'script' || local == 'foreignobject'
        node.remove
        next
      end

      node.attributes.each_value do |attr|
        name = attr.name.to_s
        downcased = name.downcase

        if downcased.start_with?(EVENT_HANDLER_PREFIX)
          node.remove_attribute(name)
          next
        end

        next unless EXTERNAL_REF_ATTRS.include?(downcased) || downcased.end_with?(':href')

        value = attr.value.to_s.strip
        node.remove_attribute(name) unless value.start_with?('#', 'data:')
      end
    end

    doc.to_xml
  end
end
