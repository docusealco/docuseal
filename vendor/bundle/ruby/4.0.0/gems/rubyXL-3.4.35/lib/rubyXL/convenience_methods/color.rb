module RubyXL
  module ColorConvenienceMethods
    def get_rgb(workbook)
      if rgb then
        return rgb
      elsif theme then
        theme_color = workbook.theme.get_theme_color(theme)
        rgb_color = theme_color && theme_color.a_srgb_clr
        color_value = rgb_color && rgb_color.val
        return nil if color_value.nil?

        RubyXL::RgbColor.parse(color_value).to_hls.apply_tint(tint).to_rgb.to_s
      end
    end
  end

  module ColorConvenienceClasses
    # https://ciintelligence.blogspot.com/2012/02/converting-excel-theme-color-and-tint.html
    class RgbColor
      attr_accessor :r, :g, :b, :a

      def to_hls
        hls_color = HlsColor.new

        # Note that we are overriding accessors with local vars here:
        r = self.r / 255.0
        g = self.g / 255.0
        b = self.b / 255.0

        hls_color.a = (self.a || 0) / 255.0

        min = [r, g, b].min
        max = [r, g, b].max
        delta = max - min

        if (max == min) then
          hls_color.h = hls_color.s = 0
          hls_color.l = max
          return hls_color
        end

        hls_color.l = (min + max) / 2

        if (hls_color.l < 0.5) then
          hls_color.s = delta / (max + min);
        else
          hls_color.s = delta / (2.0 - max - min);
        end

        hls_color.h = (g - b) / delta       if (r == max)
        hls_color.h = 2.0 + ((b - r) / delta) if (g == max)
        hls_color.h = 4.0 + ((r - g) / delta) if (b == max)

        hls_color.h *= 60;
        hls_color.h += 360 if hls_color.h < 0

        hls_color
      end

      def self.parse(str)
        r, g, b, a = str.unpack('A2A2A2A2')

        rgb_color = RgbColor.new
        rgb_color.r = r && r.to_i(16)
        rgb_color.g = g && g.to_i(16)
        rgb_color.b = b && b.to_i(16)
        rgb_color.a = a && a.to_i(16)

        rgb_color
      end

      def to_s
        if a && a != 0 then
          format('%02x%02x%02x%02x', r, g, b, a)
        else
          format('%02x%02x%02x', r, g, b)
        end
      end
    end

    class HlsColor
      attr_accessor :h, :l, :s, :a

      def to_rgb
        rgb_color = RgbColor.new

        r = g = b = l

        if s != 0 then
          t1 = nil

          if l < 0.5 then
            t1 = l * (1.0 + s)
          else
            t1 = l + s - (l * s)
          end

          t2 = (2.0 * l) - t1;
          h = self.h / 360.0

          t_r = h + (1.0 / 3.0)
          r = set_color(t1, t2, t_r)

          t_g = h;
          g = set_color(t1, t2, t_g)

          t_b = h - (1.0 / 3.0);
          b = set_color(t1, t2, t_b)
        end

        rgb_color.r = (r * 255).round(0).to_i
        rgb_color.g = (g * 255).round(0).to_i
        rgb_color.b = (b * 255).round(0).to_i

        rgb_color.a = (a * 255).round(0).to_i

        rgb_color
      end

      def set_color(t1, t2, t3)
        color = 0

        t3 += 1.0 if (t3 < 0)
        t3 -= 1.0 if (t3 > 1)

        if (6.0 * t3 < 1) then
          color = t2 + ((t1 - t2) * 6.0 * t3);
        elsif (2.0 * t3 < 1) then
          color = t1;
        elsif (3.0 * t3 < 2) then
          color = t2 + ((t1 - t2) * ((2.0 / 3.0) - t3) * 6.0);
        else
          color = t2;
        end

        color
      end
      private :set_color

      def apply_tint(tint)
        return self if tint.nil? || tint == 0

        if tint < 0 then
          self.l = l * (1.0 + tint);
        else
          self.l = (l * (1.0 - tint)) + tint;
        end

        self
      end
    end
  end

  RubyXL::Color.send(:include, RubyXL::ColorConvenienceMethods) # ruby 2.1 compat
  include(RubyXL::ColorConvenienceClasses)
end
