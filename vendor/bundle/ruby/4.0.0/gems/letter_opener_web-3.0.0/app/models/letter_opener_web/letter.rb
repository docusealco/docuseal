# frozen_string_literal: true

module LetterOpenerWeb
  class Letter
    attr_reader :id, :sent_at

    def self.letters_location
      @letters_location ||= LetterOpenerWeb.config.letters_location
    end

    def self.letters_location=(directory)
      LetterOpenerWeb.configure { |config| config.letters_location = directory }
      @letters_location = nil
    end

    def self.search
      letters = Dir.glob("#{LetterOpenerWeb.config.letters_location}/*").map do |folder|
        new(id: File.basename(folder), sent_at: File.mtime(folder))
      end
      letters.sort_by(&:sent_at).reverse
    end

    def self.find(id)
      new(id: id)
    end

    def self.destroy_all
      FileUtils.rm_rf(LetterOpenerWeb.config.letters_location)
    end

    def initialize(params)
      @id      = params.fetch(:id)
      @sent_at = params[:sent_at]
    end

    def headers
      html = read_file(:rich) if style_exists?('rich')
      html ||= read_file(:plain)

      # NOTE: This is ugly, we should look into using nokogiri and making that a
      # dependency of this gem
      match_data = html.match(%r{<body>\s*<div[^>]+id="container">\s*<div[^>]+id="message_headers">\s*(<dl>.+</dl>)}m)
      return remove_attachments_link(match_data[1]).html_safe if match_data && match_data[1].present?

      'UNABLE TO PARSE HEADERS'
    end

    def plain_text
      @plain_text ||= adjust_link_targets(read_file(:plain))
    end

    def rich_text
      @rich_text ||= adjust_link_targets(read_file(:rich))
    end

    def to_param
      id
    end

    def default_style
      style_exists?('rich') ? 'rich' : 'plain'
    end

    def attachments
      @attachments ||= Dir["#{base_dir}/attachments/*"].each_with_object({}) do |file, hash|
        hash[File.basename(file)] = File.expand_path(file)
      end
    end

    def delete
      return unless valid?

      FileUtils.rm_rf(base_dir.to_s)
    end

    def valid?
      exists? && base_dir_within_letters_location?
    end

    private

    def remove_attachments_link(headers)
      xml = REXML::Document.new(headers)
      label_element = xml.root.elements.find { |e| e.get_text&.value&.match?(/attachments:/i) }

      if label_element
        xml.root.delete_element(label_element.next_element) # the list of attachments
        xml.root.delete_element(label_element)
      end

      xml.to_s
    end

    def base_dir
      LetterOpenerWeb.config.letters_location.join(id).cleanpath
    end

    def read_file(style)
      File.read("#{base_dir}/#{style}.html")
    end

    def style_exists?(style)
      File.exist?("#{base_dir}/#{style}.html")
    end

    def exists?
      File.exist?(base_dir)
    end

    def base_dir_within_letters_location?
      base_dir.to_s.start_with?(LetterOpenerWeb.config.letters_location.to_s)
    end

    def adjust_link_targets(contents)
      # We cannot feed the whole file to a XML parser as some mails are
      # "complete" (as in they have the whole <html> structure) and letter_opener
      # prepends some information about the mail being sent, making REXML
      # complain about it
      contents.scan(%r{<a\s[^>]+>(?:.|\s)*?</a>}).each do |link|
        fixed_link = fix_link_html(link)
        xml        = REXML::Document.new(fixed_link).root
        next if xml.attributes['href'] =~ /(plain|rich).html/

        xml.attributes['target'] = '_blank'
        xml.add_text('') unless xml.text
        contents.gsub!(link, xml.to_s)
      end
      contents
    end

    def fix_link_html(link_html)
      # REFACTOR: we need a better way of fixing the link inner html
      link_html.dup.tap do |fixed_link|
        fixed_link.gsub!('<br>', '<br/>')
        fixed_link.scan(/<img(?:[^>]+?)>/).each do |img|
          fixed_img = img.dup
          fixed_img.gsub!(/>$/, '/>') unless img =~ %r{/>$}
          fixed_link.gsub!(img, fixed_img)
        end
      end
    end
  end
end
