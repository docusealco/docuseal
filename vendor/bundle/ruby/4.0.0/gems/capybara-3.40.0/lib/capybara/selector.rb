# frozen_string_literal: true

require 'capybara/selector/xpath_extensions'
require 'capybara/selector/selector'
require 'capybara/selector/definition'

#
# All Selectors below support the listed selector specific filters in addition to the following system-wide filters
#   * :id (String, Regexp, XPath::Expression) - Matches the id attribute
#   * :class (String, Array<String | Regexp>, Regexp, XPath::Expression) - Matches the class(es) provided
#   * :style (String, Regexp, Hash<String, String>) - Match on elements style
#   * :above (Element) - Match elements above the passed element on the page
#   * :below (Element) - Match elements below the passed element on the page
#   * :left_of (Element) - Match elements left of the passed element on the page
#   * :right_of (Element) - Match elements right of the passed element on the page
#   * :near (Element) - Match elements near (within 50px) the passed element on the page
#   * :focused (Boolean) - Match elements with focus (requires driver support)
#
# ### Built-in Selectors
#
# * **:xpath** - Select elements by XPath expression
#   * Locator: An XPath expression
#
#   ```ruby
#   page.html # => '<input>'
#
#   page.find :xpath, './/input'
#   ```
#
# * **:css** - Select elements by CSS selector
#   * Locator: A CSS selector
#
#   ```ruby
#   page.html # => '<input>'
#
#   page.find :css, 'input'
#   ```
#
# * **:id** - Select element by id
#   * Locator: (String, Regexp, XPath::Expression) The id of the element to match
#
#   ```ruby
#   page.html # => '<input id="field">'
#
#   page.find :id, 'content'
#   ```
#
# * **:field** - Select field elements (input [not of type submit, image, or hidden], textarea, select)
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name, placeholder, or
#     associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :type (String) - Matches the type attribute of the field or element type for 'textarea' and 'select'
#       * :readonly (Boolean) - Match on the element being readonly
#       * :with (String, Regexp) - Matches the current value of the field
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :valid (Boolean) - Match fields that are valid/invalid according to HTML5 form validation
#       * :validation_message (String, Regexp) - Matches the elements current validationMessage
#
#   ```ruby
#   page.html # => '<label for="article_title">Title</label>
#                   <input id="article_title" name="article[title]" value="Hello world">'
#
#   page.find :field, 'article_title'
#   page.find :field, 'article[title]'
#   page.find :field, 'Title'
#   page.find :field, 'Title', type: 'text', with: 'Hello world'
#   ```
#
# * **:fieldset** - Select fieldset elements
#   * Locator: Matches id, {Capybara.configure test_id}, or contents of wrapped legend
#   * Filters:
#       * :legend (String) - Matches contents of wrapped legend
#       * :disabled (Boolean) - Match disabled fieldset?
#
#   ```ruby
#   page.html # => '<fieldset disabled>
#                     <legend>Fields (disabled)</legend>
#                   </fieldset>'
#
#   page.find :fieldset, 'Fields (disabled)', disabled: true
#   ```
#
# * **:link** - Find links (`<a>` elements with an href attribute)
#   * Locator: Matches the id, {Capybara.configure test_id}, or title attributes, or the string content of the link,
#     or the alt attribute of a contained img element. By default this selector requires a link to have an href attribute.
#   * Filters:
#       * :title (String) - Matches the title attribute
#       * :alt (String) - Matches the alt attribute of a contained img element
#       * :href (String, Regexp, nil, false) - Matches the normalized href of the link, if nil will find `<a>` elements with no href attribute, if false ignores href presence
#
#   ```ruby
#   page.html # => '<a href="/">Home</a>'
#
#   page.find :link, 'Home', href: '/'
#
#   page.html # => '<a href="/"><img src="/logo.png" alt="The logo"></a>'
#
#   page.find :link, 'The logo', href: '/'
#   page.find :link, alt: 'The logo', href: '/'
#   ```
#
# * **:button** - Find buttons ( input [of type submit, reset, image, button] or button elements )
#   * Locator: Matches the id, {Capybara.configure test_id} attribute, name, value, or title attributes, string content of a button, or the alt attribute of an image type button or of a descendant image of a button
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :title (String) - Matches the title attribute
#       * :value (String) - Matches the value of an input button
#       * :type (String) - Matches the type attribute
#       * :disabled (Boolean, :all) - Match disabled buttons (Default: false)
#
#   ```ruby
#   page.html # => '<button>Submit</button>'
#
#   page.find :button, 'Submit'
#
#   page.html # => '<button name="article[state]" value="draft">Save as draft</button>'
#
#   page.find :button, 'Save as draft', name: 'article[state]', value: 'draft'
#   ```
#
# * **:link_or_button** - Find links or buttons
#   * Locator: See :link and :button selectors
#   * Filters:
#       * :disabled (Boolean, :all) - Match disabled buttons? (Default: false)
#
#   ```ruby
#   page.html # => '<a href="/">Home</a>'
#
#   page.find :link_or_button, 'Home'
#
#   page.html # => '<button>Submit</button>'
#
#   page.find :link_or_button, 'Submit'
#   ```
#
# * **:fillable_field** - Find text fillable fields ( textarea, input [not of type submit, image, radio, checkbox, hidden, file] )
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name, placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :with (String, Regexp) - Matches the current value of the field
#       * :type (String) - Matches the type attribute of the field or element type for 'textarea'
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :valid (Boolean) - Match fields that are valid/invalid according to HTML5 form validation
#       * :validation_message (String, Regexp) - Matches the elements current validationMessage
#
#   ```ruby
#   page.html # => '<label for="article_body">Body</label>
#                   <textarea id="article_body" name="article[body]"></textarea>'
#
#   page.find :fillable_field, 'article_body'
#   page.find :fillable_field, 'article[body]'
#   page.find :fillable_field, 'Body'
#   page.find :field, 'Body', type: 'textarea'
#   ```
#
# * **:radio_button** - Find radio buttons
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :option (String, Regexp) - Match the current value
#       * :with - Alias of :option
#
#   ```ruby
#   page.html # => '<input type="radio" id="article_state_published" name="article[state]" value="published" checked>
#                   <label for="article_state_published">Published</label>
#                   <input type="radio" id="article_state_draft" name="article[state]" value="draft">
#                   <label for="article_state_draft">Draft</label>'
#
#   page.find :radio_button, 'article_state_published'
#   page.find :radio_button, 'article[state]', option: 'published'
#   page.find :radio_button, 'Published', checked: true
#   page.find :radio_button, 'Draft', unchecked: true
#   ```
#
# * **:checkbox** - Find checkboxes
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :checked (Boolean) - Match checked fields?
#       * :unchecked (Boolean) - Match unchecked fields?
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :with (String, Regexp) - Match the current value
#       * :option - Alias of :with
#
#   ```ruby
#   page.html # => '<input type="checkbox" id="registration_terms" name="registration[terms]" value="true">
#                   <label for="registration_terms">I agree to terms and conditions</label>'
#
#   page.find :checkbox, 'registration_terms'
#   page.find :checkbox, 'registration[terms]'
#   page.find :checkbox, 'I agree to terms and conditions', unchecked: true
#   ```
#
# * **:select** - Find select elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Placeholder) - Matches the placeholder attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match fields that accept multiple values
#       * :options (Array<String>) - Exact match options
#       * :enabled_options (Array<String>) - Exact match enabled options
#       * :disabled_options (Array<String>) - Exact match disabled options
#       * :with_options (Array<String>) - Partial match options
#       * :selected (String, Array<String>) - Match the selection(s)
#       * :with_selected (String, Array<String>) - Partial match the selection(s)
#
#   ```ruby
#   page.html # => '<label for="article_category">Category</label>
#                   <select id="article_category" name="article[category]">
#                     <option value="General" checked></option>
#                     <option value="Other"></option>
#                   </select>'
#
#   page.find :select, 'article_category'
#   page.find :select, 'article[category]'
#   page.find :select, 'Category'
#   page.find :select, 'Category', selected: 'General'
#   page.find :select, with_options: ['General']
#   page.find :select, with_options: ['Other']
#   page.find :select, options: ['General', 'Other']
#   page.find :select, options: ['General'] # => raises Capybara::ElementNotFound
#   ```
#
# * **:option** - Find option elements
#   * Locator: Match text of option
#   * Filters:
#       * :disabled (Boolean) - Match disabled option
#       * :selected (Boolean) - Match selected option
#
#   ```ruby
#   page.html # => '<option value="General" checked></option>
#                   <option value="Disabled" disabled></option>
#                   <option value="Other"></option>'
#
#   page.find :option, 'General'
#   page.find :option, 'General', selected: true
#   page.find :option, 'Disabled', disabled: true
#   page.find :option, 'Other', selected: false
#   ```
#
# * **:datalist_input** - Find input field with datalist completion
#   * Locator: Matches against the id, {Capybara.configure test_id} attribute, name,
#     placeholder, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :placeholder (String, Regexp) - Matches the placeholder attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :options (Array<String>) - Exact match options
#       * :with_options (Array<String>) - Partial match options
#
#   ```ruby
#   page.html # => '<label for="ice_cream_flavor">Flavor</label>
#                   <input list="ice_cream_flavors" id="ice_cream_flavor" name="ice_cream[flavor]">
#                   <datalist id="ice_cream_flavors">
#                     <option value="Chocolate"></option>
#                     <option value="Strawberry"></option>
#                     <option value="Vanilla"></option>
#                   </datalist>'
#
#   page.find :datalist_input, 'ice_cream_flavor'
#   page.find :datalist_input, 'ice_cream[flavor]'
#   page.find :datalist_input, 'Flavor'
#   page.find :datalist_input, with_options: ['Chocolate', 'Strawberry']
#   page.find :datalist_input, options: ['Chocolate', 'Strawberry', 'Vanilla']
#   page.find :datalist_input, options: ['Chocolate'] # => raises Capybara::ElementNotFound
#   ```
#
# * **:datalist_option** - Find datalist option
#   * Locator: Match text or value of option
#   * Filters:
#       * :disabled (Boolean) - Match disabled option
#
#   ```ruby
#   page.html # => '<datalist>
#                     <option value="Chocolate"></option>
#                     <option value="Strawberry"></option>
#                     <option value="Vanilla"></option>
#                     <option value="Forbidden" disabled></option>
#                   </datalist>'
#
#   page.find :datalist_option, 'Chocolate'
#   page.find :datalist_option, 'Strawberry'
#   page.find :datalist_option, 'Vanilla'
#   page.find :datalist_option, 'Forbidden', disabled: true
#   ```
#
# * **:file_field** - Find file input elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, name, or associated label text
#   * Filters:
#       * :name (String, Regexp) - Matches the name attribute
#       * :disabled (Boolean, :all) - Match disabled field? (Default: false)
#       * :multiple (Boolean) - Match field that accepts multiple values
#
#   ```ruby
#   page.html # => '<label for="article_banner_image">Banner Image</label>
#                   <input type="file" id="article_banner_image" name="article[banner_image]">'
#
#   page.find :file_field, 'article_banner_image'
#   page.find :file_field, 'article[banner_image]'
#   page.find :file_field, 'Banner Image'
#   page.find :file_field, 'Banner Image', name: 'article[banner_image]'
#   page.find :field, 'Banner Image', type: 'file'
#   ```
#
# * **:label** - Find label elements
#   * Locator: Match id, {Capybara.configure test_id}, or text contents
#   * Filters:
#       * :for (Element, String, Regexp) - The element or id of the element associated with the label
#
#   ```ruby
#   page.html # => '<label for="article_title">Title</label>
#                   <input id="article_title" name="article[title]">'
#
#   page.find :label, 'Title'
#   page.find :label, 'Title', for: 'article_title'
#   page.find :label, 'Title', for: page.find('article[title]')
#   ```
#
# * **:table** - Find table elements
#   * Locator: id, {Capybara.configure test_id}, or caption text of table
#   * Filters:
#       * :caption (String) - Match text of associated caption
#       * :with_rows (Array<Array<String>>, Array<Hash<String, String>>) - Partial match `<td>` data - visibility of `<td>` elements is not considered
#       * :rows (Array<Array<String>>) - Match all `<td>`s - visibility of `<td>` elements is not considered
#       * :with_cols (Array<Array<String>>, Array<Hash<String, String>>) - Partial match `<td>` data - visibility of `<td>` elements is not considered
#       * :cols (Array<Array<String>>) - Match all `<td>`s - visibility of `<td>` elements is not considered
#
#   ```ruby
#   page.html # => '<table>
#                     <caption>A table</caption>
#                     <tr>
#                       <th>A</th>
#                       <th>B</th>
#                     </tr>
#                     <tr>
#                       <td>1</td>
#                       <td>2</td>
#                     </tr>
#                     <tr>
#                       <td>3</td>
#                       <td>4</td>
#                     </tr>
#                   </table>'
#
#   page.find :table, 'A table'
#   page.find :table, with_rows: [
#     { 'A' => '1', 'B' => '2' },
#     { 'A' => '3', 'B' => '4' },
#   ]
#   page.find :table, with_rows: [
#     ['1', '2'],
#     ['3', '4'],
#   ]
#   page.find :table, rows: [
#     { 'A' => '1', 'B' => '2' },
#     { 'A' => '3', 'B' => '4' },
#   ]
#   page.find :table, rows: [
#     ['1', '2'],
#     ['3', '4'],
#   ]
#   page.find :table, rows: [ ['1', '2'] ] # => raises Capybara::ElementNotFound
#   ```
#
# * **:table_row** - Find table row
#   * Locator: Array<String>, Hash<String, String> table row `<td>` contents - visibility of `<td>` elements is not considered
#
#   ```ruby
#   page.html # => '<table>
#                     <tr>
#                       <th>A</th>
#                       <th>B</th>
#                     </tr>
#                     <tr>
#                       <td>1</td>
#                       <td>2</td>
#                     </tr>
#                     <tr>
#                       <td>3</td>
#                       <td>4</td>
#                     </tr>
#                   </table>'
#
#   page.find :table_row, 'A' => '1', 'B' => '2'
#   page.find :table_row, 'A' => '3', 'B' => '4'
#   ```
#
# * **:frame** - Find frame/iframe elements
#   * Locator: Match id, {Capybara.configure test_id} attribute, or name
#   * Filters:
#       * :name (String) - Match name attribute
#
#   ```ruby
#   page.html # => '<iframe id="embed_frame" name="embed" src="https://example.com/embed"></iframe>'
#
#   page.find :frame, 'embed_frame'
#   page.find :frame, 'embed'
#   page.find :frame, name: 'embed'
#   ```
#
# * **:element**
#   * Locator: Type of element ('div', 'a', etc) - if not specified defaults to '*'
#   * Filters:
#       * :\<any> (String, Regexp) - Match on any specified element attribute
#
#   ```ruby
#   page.html # => '<button type="button" role="menuitemcheckbox" aria-checked="true">Check me</button>
#
#   page.find :element, 'button'
#   page.find :element, type: 'button', text: 'Check me'
#   page.find :element, role: 'menuitemcheckbox'
#   page.find :element, role: /checkbox/, 'aria-checked': 'true'
#   ```
#
class Capybara::Selector; end # rubocop:disable Lint/EmptyClass

Capybara::Selector::FilterSet.add(:_field) do
  node_filter(:checked, :boolean) { |node, value| !(value ^ node.checked?) }
  node_filter(:unchecked, :boolean) { |node, value| (value ^ node.checked?) }
  node_filter(:disabled, :boolean, default: false, skip_if: :all) { |node, value| !(value ^ node.disabled?) }
  node_filter(:valid, :boolean) { |node, value| node.evaluate_script('this.validity.valid') == value }
  node_filter(:name) { |node, value| !value.is_a?(Regexp) || value.match?(node[:name]) }
  node_filter(:placeholder) { |node, value| !value.is_a?(Regexp) || value.match?(node[:placeholder]) }
  node_filter(:validation_message) do |node, msg|
    vm = node[:validationMessage]
    (msg.is_a?(Regexp) ? msg.match?(vm) : vm == msg.to_s).tap do |res|
      add_error("Expected validation message to be #{msg.inspect} but was #{vm}") unless res
    end
  end

  expression_filter(:name) do |xpath, val|
    builder(xpath).add_attribute_conditions(name: val)
  end
  expression_filter(:placeholder) do |xpath, val|
    builder(xpath).add_attribute_conditions(placeholder: val)
  end
  expression_filter(:disabled) { |xpath, val| val ? xpath : xpath[~XPath.attr(:disabled)] }
  expression_filter(:multiple) { |xpath, val| xpath[val ? XPath.attr(:multiple) : ~XPath.attr(:multiple)] }

  describe(:expression_filters) do |name: nil, placeholder: nil, disabled: nil, multiple: nil, **|
    desc = +''
    desc << ' that is not disabled' if disabled == false
    desc << " with name #{name}" if name
    desc << " with placeholder #{placeholder}" if placeholder
    desc << ' with the multiple attribute' if multiple == true
    desc << ' without the multiple attribute' if multiple == false
    desc
  end

  describe(:node_filters) do |checked: nil, unchecked: nil, disabled: nil, valid: nil, validation_message: nil, **|
    desc, states = +'', []
    states << 'checked' if checked || (unchecked == false)
    states << 'not checked' if unchecked || (checked == false)
    states << 'disabled' if disabled == true
    desc << " that is #{states.join(' and ')}" unless states.empty?
    desc << ' that is valid' if valid == true
    desc << ' that is invalid' if valid == false
    desc << " with validation message #{validation_message.to_s.inspect}" if validation_message
    desc
  end
end

require 'capybara/selector/definition/xpath'
require 'capybara/selector/definition/css'
require 'capybara/selector/definition/id'
require 'capybara/selector/definition/field'
require 'capybara/selector/definition/fieldset'
require 'capybara/selector/definition/link'
require 'capybara/selector/definition/button'
require 'capybara/selector/definition/link_or_button'
require 'capybara/selector/definition/fillable_field'
require 'capybara/selector/definition/radio_button'
require 'capybara/selector/definition/checkbox'
require 'capybara/selector/definition/select'
require 'capybara/selector/definition/datalist_input'
require 'capybara/selector/definition/option'
require 'capybara/selector/definition/datalist_option'
require 'capybara/selector/definition/file_field'
require 'capybara/selector/definition/label'
require 'capybara/selector/definition/table'
require 'capybara/selector/definition/table_row'
require 'capybara/selector/definition/frame'
require 'capybara/selector/definition/element'
