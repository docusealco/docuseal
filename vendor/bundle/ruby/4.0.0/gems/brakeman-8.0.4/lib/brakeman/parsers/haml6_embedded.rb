[:Coffee, :CoffeeScript, :Markdown, :Sass].each do |name|
  klass = Module.const_get("Haml::Filters::#{name}")

  klass.define_method(:compile) do |node|
    temple = [:multi]
    temple << [:static, "<script>\n"]
    temple << compile_with_tilt(node)
    temple << [:static, "</script>"]
    temple
  end

  klass.define_method(:compile_with_tilt) do |node|
    # From Haml
    text = ::Haml::Util.unescape_interpolation(node.value[:text]).gsub(/(\\+)n/) do |s|
      escapes = $1.size
      next s if escapes % 2 == 0
      "#{'\\' * (escapes - 1)}\n"
    end
    text.prepend("\n").sub!(/\n"\z/, '"')

    [:dynamic, "BrakemanFilter.render(#{text})"]
  end
end
