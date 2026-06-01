---
author: Willem van Bergen
title: Memory efficiency when using Ruby
---

I have been spending some time creating [a pure Ruby PNG library](https://github.com/wvanbergen/chunky_png). For this library, I need to have some representation of the image, which is composed of RGB pixels, supporting an alpha channel. Because images can be composed of a lot of pixels, I want the implementation to be as memory efficient as possible. I also would like decent performance.

A very naive Ruby implementation for an image represents the red, green, blue and alpha channel using a floating point number between 0.0 and 1.0, and might look something like this:

{% highlight ruby %}
class Pixel
  attr_reader :r, :g, :b, :a

  def initialize(r, g, b, a = 1.0)
    @r, @g, @b, @a = r, g, b, a
  end
end

class Image
  attr_reader :width, :height

  def initialize(width, height)
    @width, @height = width, height
    @pixels = Array.new(width * height)
  end

  def [](x,y)
    @pixels[y * width + x]
  end

  def []=(x,y, pixel)
    @pixels[y * width + x] = pixel
  end
end
{% endhighlight %}

For a 10×10 image, this representation requires 4 times 100 floating point numbers, which require 8 bytes each. That’s already over 3kB for such a small image just for the floating point numbers! Ouch.

A simple improvement is to decide that 8-bit color depth is enough in the case, in which case each channel can be represented by an integer between 0 and 255. Storing such a number only costs one byte of memory. Ruby’s Fixnum class typically uses 4-byte integers. If only the 4 channels of one byte each could be combined into a single Fixnum instance… Behold!

{% highlight ruby %}
class Pixel
  attr_reader :value
  alias :to_i :value

  def initialize(value)
    @value = value
  end

  def self.rgba(r, g, b, a = 255)
    self.new(r << 24 | g << 16 | b << 8 | a)
  end

  def r; (@value & 0xff000000) >> 24; end
  def g; (@value & 0x00ff0000) >> 16; end
  def b; (@value & 0x0000ff00) >>  8; end
  def a; (@value & 0x000000ff); end
end
{% endhighlight %}

Notice the bit operations, which are extremely fast. This only requires 100 times 4 bytes = 400 bytes for storing the RGBA values for a 10×10 image, an 8 times improvement!

This implementation wraps every pixel inside an object. This is nice, because I want to access the separate channels of every pixel easily using the r, g, b, and a methods, and every other method that is defined for every pixel. However, a Ruby object instance has an overhead of at least 20 bytes. That’s 20 times 100 is about 2kB for our 10×10 image!

To get rid of the object overhead, it is possible to simply store the Fixnum value for every pixel, and only wrapping it inside a Pixel object when it is accessed. This can be done by modifying the Image class:

{% highlight ruby %}
class Image
  # ...

  def [](x,y)
    Pixel.new(@pixels[y * width + x]) # wrap
  end

  def []=(x,y, pixel)
    @pixels[y * width + x] = pixel.to_i # unwrap
  end
end
{% endhighlight %}

As you can see, some simply changes in the representation can really make a difference in the memory usage. Can this representation be improved further?

## Integer math calculations

Because we are now using integers to represent a pixel, this can cause problems when the math requires you to use floating point numbers. For example, the formula for [alpha composition](https://en.wikipedia.org/wiki/Alpha_compositing) of two pixels is as follows:

\\[ C_o = C_a \alpha_a + C_b \alpha_b (1 - \alpha_a) \\]

in which \\(C_a\\) is the color component of the foreground pixel, \\(\alpha_a\\) the alpha channel of the foreground pixel, \\(C_b\\) and \\(\alpha_b\\) the same values for the background pixel, all of which should be values between 0 and 1.

A naive implementation could convert the integer numbers to their floating point equivalents:

{% highlight ruby %}
def compose(fg, bg)
  return bg if fg.a == 0
  return fg if fg.a == 255

  fg_alpha = fg.a / 255.0
  bg_alpha = fg.a / 255.0
  alpha_complement = (1.0 - fg_alpha) * bg_alpha

  new_r = (fg_alpha * fg.r + alpha_complement * bg.r).round
  new_g = (fg_alpha * fg.g + alpha_complement * bg.g).round
  new_b = (fg_alpha * fg.b + alpha_complement * bg.b).round
  new_a = ((fg_alpha + alpha_complement) * 255).round

  Pixel.rgba(new_r, new_g, new_b, new_a)
end
{% endhighlight %}

This implementation is already a little bit optimized: no unnecessary conversions and calculations are being performed. However, this composition can be done a lot quicker after realizing that 255 is almost a power of two, in which computers excel because it can use bitwise operators and shifting for some calculations.

My new approach uses a quicker implementation of multiplication of 8-bit integers that represent floating numbers between 0 and 1:

{% highlight ruby %}
def compose(fg, bg)
  return bg if fg.a == 0
  return fg if fg.a == 255

  alpha_complement = multiply(255 - fg.a, bg.a)
  new_r = multiply(fg.a, fg.r) + multiply(alpha_complement, bg.r)
  new_g = multiply(fg.a, fg.g) + multiply(alpha_complement, bg.g)
  new_b = multiply(fg.a, fg.b) + multiply(alpha_complement, bg.b)
  new_a = fg.a + alpha_complement

  Pixel.rgba(new_r, new_g, new_b, new_a)
end

# Quicker alternative for (a * b / 255.0).round
def multiply(a, b)
  t = a * b + 0x80
  ((t >> 8) + t) >> 8
end
{% endhighlight %}

Note that the new implementation is less precise in theory, but this precision is lost anyway because we have to convert the values back to 8 bit RGBA values. Your thoughts?
