# frozen_string_literal: true

module Faker
  class HTML < Base
    class << self
      ##
      # Produces a random HTML header format.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.heading #=> "<h5>Autem</h5>"
      #
      # @faker.version 3.2.1
      def heading
        level = rand(1..6)
        "<h#{level}>#{Lorem.word.capitalize}</h#{level}>"
      end

      ##
      # Produces a random HTML paragraph format.
      #
      # @param sentence_count [Integer] The number of sentences in the paragraph.
      # @param supplemental [Boolean] Include supplemental text.
      # @param random_sentences_to_add [Integer] The number of random sentences to add to the paragraph.
      # @param exclude_words [Array<String>] Words to exclude from the generated paragraph.
      # @return [String]
      #
      # @example
      #   Faker::HTML.paragraph #=> "<p>Incidunt atque quis</p>"
      #
      # @faker.version 3.2.1
      def paragraph(sentence_count: 3, supplemental: false, random_sentences_to_add: 0, exclude_words: nil)
        "<p>#{Faker::Lorem.paragraph(sentence_count: sentence_count, supplemental: supplemental, random_sentences_to_add: random_sentences_to_add, exclude_words: exclude_words)}</p>"
      end

      ##
      # Produces a random emphasis formatting on a random word in two HTML paragraphs.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.emphasis #=> "<em>repellat id impedit</em>"
      #
      # @faker.version 3.2.1
      def emphasis
        "<em>#{Faker::Lorem.paragraph(sentence_count: 1)}</em>"
      end

      ##
      # Produces a random ordered list in HTML format, with at least one element.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.ordered_list #=> "<ol>\n<li>Qui reiciendis non consequatur atque.</li>\n<li>Quo doloremque veritatis tempora aut.</li>\n<li>Aspernatur.</li>\n<li>Ea ab.</li>\n<li>Qui.</li>\n<li>Sit pariatur nemo eveniet.</li>\n<li>Molestiae aut.</li>\n<li>Nihil molestias iure placeat.</li>\n<li>Dolore autem quisquam.</li>\n</ol>"
      #
      # @faker.version 3.2.1
      def ordered_list
        number = rand(1..10)

        items = []
        number.times do
          items << "<li>#{Faker::Lorem.sentence(word_count: 1)}</li>"
        end

        "<ol>\n#{items.join("\n")}\n</ol>"
      end

      ##
      # Produces a random unordered list of items between 1 and 10 randomly in HTML format.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.unordered_list #=> "<ul>\n<li>Voluptatum aliquid tempora molestiae facilis non sed.</li>\n<li>Nostrum omnis iste impedit voluptatum dolor.</li>\n<li>Esse quidem et facere.</li>\n</ul>"
      #
      # @faker.version 3.2.1
      def unordered_list
        number = rand(1..10)

        items = []
        number.times do
          items << "<li>#{Faker::Lorem.sentence(word_count: 1)}</li>"
        end

        "<ul>\n#{items.join("\n")}\n</ul>"
      end

      ##
      # Produces a random code block formatted in HTML.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.code #=> "<code>Eos quasi qui.</code>"
      #
      # @faker.version 3.2.1
      def code
        "<code>#{Lorem.sentence(word_count: 1)}</code>"
      end

      ##
      # Produces a random HTML table.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.table #=> "<table>\n<thead>\n<th>ad</th>\n<th>similique</th>\n<th>voluptatem</th>\n</thead>\n<tbody>\n<td>corrupti</td>\n<td>est</td>\n<td>rerum</td>\n<td>molestiae</td>\n<td>quidem</td>\n<td>et</td>\n<td>in</td>\n<td>tempora</td>\n<td>at</td>\n<\tbody>\n<tfoot>\n<td>voluptatem</td>\n<td>debitis</td>\n<td>rem</td>\n</tfoot>\n</table>"
      #
      # @faker.version 3.2.1
      def table
        header_row = generate_table_row('th', 3)
        footer_row = generate_table_row('td', 3)

        body_rows = []
        3.times do
          row = generate_table_row('td', 3)
          body_rows << row
        end

        thead = "<thead>\n#{header_row}</thead>"
        tbody = "<tbody>\n#{body_rows.join("\n")}</tbody>"
        tfoot = "<tfoot>\n#{footer_row}</tfoot>"

        "<table>\n#{thead}\n#{tbody}\n#{tfoot}\n</table>"
      end

      ##
      # Generates a random <script> tag with the `src` attribute set to a random URL.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.script #=> "<script src=\"http://gulgowski.name/jordan.weimann.js\"></script>"
      #
      # @faker.version 3.2.1
      def script
        "<script src=\"#{Faker::Internet.url}.js\"></script>"
      end

      ##
      # Generates a random <link> tag with the `rel` attribute set to "stylesheet" and the `href` attribute set to a random URL.
      #
      # @param rel [String] The rel of the link tag.
      # @return [String]
      #
      # @example
      #   Faker::HTML.link #=> "<link rel=\"stylesheet\" href=\"http://fay.io/darryl.barrows.css\">"
      #
      # @faker.version 3.2.1
      def link(rel: 'stylesheet')
        "<link rel=\"#{rel}\" href=\"#{Faker::Internet.url}.css\">"
      end

      ##
      # Generates HTML content with customizable attributes for any HTML tag.
      #
      # @param tag [String] The HTML tag to generate.
      # @param content [String] The Content of the HTML tag.
      # @param attributes [Hash] The attributes to include in the tag.
      # @return [String]
      #
      # @example
      #   Faker::HTML.element(tag: 'div', content: "This is a div with XSS attributes.", attributes: {class: 'xss', onclick: "alert('XSS')"}) #=> "<div class=\"xss\" onclick=\"alert('XSS')\">This is a div with XSS attributes.</div>"
      #
      # @faker.version 3.2.1
      def element(tag: 'div', content: Lorem.sentence(word_count: 3), attributes: { class: Lorem.word, onclick: "#{Lorem.word}()" })
        attribute_string = attributes.map { |key, value| "#{key}=\"#{value}\"" }.join(' ')
        "<#{tag} #{attribute_string}>#{content}</#{tag}>"
      end

      ##
      # Produces a random method from the methods above, excluding the methods listed in the arguments.
      #
      # @overload random(methods)
      #   @param methods [Symbol] Specify which methods to exclude.
      #
      # @return [String]
      #
      # @example
      #   Faker::HTML.random #=> returns output from a single method outlined above
      #   Faker::HTML.random(exclude: [:table]) #=> returns output from any single method outlined above except for "table"
      #   Faker::HTML.random(exclude: [:ordered_list, :unordered_list]) #=> returns output from any single method outlined above except for either ordered_list and unordered_list
      #
      # @faker.version 3.2.1
      def random(exclude: [])
        method_list = available_methods
        exclude.each { |ex| method_list.delete_if { |meth| meth == ex.to_sym } }
        send(method_list[Faker::Config.random.rand(0..(method_list.length - 1))])
      end

      ##
      # Generates a random HTML content sandwich, starting with a header, followed by paragraphs, and random elements.
      #
      # @param sentences [Integer] The number of sentences in each paragraph.
      # @param repeat [Integer] The number of times to repeat the pattern (header, paragraph, random).
      # @return [String]
      #
      # @example
      #   Faker::HTML.sandwich(sentences: 3, repeat: 2) #=> returns a sandwich of HTML content with 2 repetitions, each having a header, paragraph, and random element
      #
      # @faker.version 3.2.1
      def sandwich(sentences: 3, repeat: 1)
        text_block = []
        text_block << heading
        repeat.times do
          text_block << paragraph(sentence_count: sentences)
          text_block << random(exclude: %i[script link])
        end
        text_block.join("\n")
      end

      private

      def available_methods
        (HTML.public_methods(false) - Base.methods).sort
      end

      def generate_table_row(tag, cell_count)
        row = "<tr>\n"
        cell_count.times do
          row += "<#{tag == 'th' ? 'th' : 'td'}>#{Lorem.word}</#{tag == 'th' ? 'th' : 'td'}>\n"
        end
        row += "</tr>\n"
        row
      end
    end
  end
end
