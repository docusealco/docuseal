module RubyXL
  module FontConvenienceMethods
    # Funny enough, but presence of <i> without value (equivalent to `val == nul`) means "italic = true"!
    # Same is true for bold, strikethrough, etc
    def is_italic
      i && (i.val != false)
    end

    def is_bold
      b && (b.val != false)
    end

    def is_underlined
      u && (u.val != false)
    end

    def is_strikethrough
      strike && (strike.val != false)
    end

    def get_name
      name && name.val
    end

    def get_size
      sz && sz.val
    end

    def get_rgb_color
      color && color.rgb
    end

    def set_italic(val)
      self.i = RubyXL::BooleanValue.new(:val => val)
    end

    def set_bold(val)
      self.b = RubyXL::BooleanValue.new(:val => val)
    end

    def set_underline(val)
      self.u = RubyXL::BooleanValue.new(:val => val)
    end

    def set_strikethrough(val)
      self.strike = RubyXL::BooleanValue.new(:val => val)
    end

    def set_name(val)
      self.name = RubyXL::StringValue.new(:val => val)
    end

    def set_size(val)
      self.sz = RubyXL::FloatValue.new(:val => val)
    end

    def set_rgb_color(font_color)
      self.color = RubyXL::Color.new(:rgb => font_color.to_s)
    end
  end

  RubyXL::Font.send(:include, RubyXL::FontConvenienceMethods) # ruby 2.1 compat
end
