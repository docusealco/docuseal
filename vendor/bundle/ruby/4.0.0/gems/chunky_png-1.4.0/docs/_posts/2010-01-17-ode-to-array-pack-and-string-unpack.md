---
author: Willem van Bergen
title: Ode to Array#pack and String#unpack
---

Remember [my last post]({% post_url 2010-01-14-memory-efficiency-when-using-ruby %}), where I representing a pixel with a Fixnum, storing the R, G, B and A value in its 4 bytes of memory? Well, I have been working some more on [my PNG library](https://github.com/wvanbergen/chunky_png) and I am now trying loading and saving an image.

Using the [PNG specification](https://www.w3.org/TR/PNG/), building a PNG encoder/decoder isn’t that hard, but the required algorithmic calculations make sure that performance in Ruby is less than stellar. I have rewritten all calculations to only use fast integer math (plus, minus, multiply and bitwise operators), but simply the amount of code that is getting executed is slowing Ruby down. What more can I do to improve the performance?

## Encoding RGBA images

Optimizing loading images is very hard, because PNG images can have many variations, and taking shortcuts means that some images are no longer supported. Not so with saving images: as long an image is saved using one of the valid variations, every PNG decoder will be able to read the file. Let’s see if it is possible to optimize one of these encoding variations.

During encoding, the image get splits up into scanlines (rows) of pixels, which in turn get converted into bytes. These bytes can be filtered for optimal compression. For a 3×3 8-bit RGBA image, the result looks like this:

    F Rf Gf Bf Af Rf Gf Bf Af Rf Gf Bf Af
    F Rf Gf Bf Af Rf Gf Bf Af Rf Gf Bf Af
    F Rf Gf Bf Af Rf Gf Bf Af Rf Gf Bf Af

Every line starts with a byte F indicating the filter method, followed by the filtered R, G and B value for every pixel on that line. Now, if we choose filter method 0, which means no filtering, the result looks like this:

    0 Ro Go Bo Ao Ro Go Bo Ao Ro Go Bo Ao
    0 Ro Go Bo Ao Ro Go Bo Ao Ro Go Bo Ao
    0 Ro Go Bo Ao Ro Go Bo Ao Ro Go Bo Ao

Now, the original R, G, B and A byte from the original pixel’s Fixnum, occur in [big-endian or network byte order](https://en.wikipedia.org/wiki/Endianness), starting with the top left pixel, moving left to right and then top to bottom. Exactly like the pixels are stored in our image’s pixel array! This means that we can use the Array#pack method to encode into this format. The Array#pack-notation for this is "xN3" in which x get translated into a null byte, and every N as 4-byte integer in network byte order. For optimal performance, it is best to not split the original array in lines, but to pack the complete pixel array at once. So, we can encode all pixels with this command:

{% highlight ruby %}
pixeldata = pixels.pack("xN#{width}" * height)
{% endhighlight %}

This way, the splitting the image into lines, splitting the pixels into bytes, and filtering the bytes can be skipped. In Ruby 1.8.7, this means a speedup of over 1500% (no typo)! Of course, because no filtering applied, the subsequent compression is not optimal, but that is a tradeoff that I am willing to make.

## Encoding RGB images

What about RGB images without alpha channel? We can simply choose to encode these using the RGBA method, but that increases the file size with roughly 25%. Can we fix this somehow?

The unfiltered pixel data should look something like this:

    0 Ro Go Bo Ro Go Bo Ro Go Bo
    0 Ro Go Bo Ro Go Bo Ro Go Bo
    0 Ro Go Bo Ro Go Bo Ro Go Bo

This means that for every pixel that is encoded as a 4-byte integer, the last byte should be ditched. Luckily, the `Array#pack` method offers a modifier that does just that: `X`. Packing a 3 pixel line can be done with `"xNXNXNX"`. Again we would like to pack the whole pixel array at once:

{% highlight ruby %}
pixeldata = pixels.pack(("x" + ('NX' * width)) * height)
{% endhighlight %}

Because all the encoding steps can get skipped once again, the speed improvement is again 1500%! And the result is 25% smaller than the RGBA method. This method is actually so speedy, that saving an image using Ruby 1.9.1 is only a little bit slower (< 10%) than saving a PNG image using RMagick! See my [performance comparison](https://github.com/wvanbergen/chunky_png/wiki/performance-comparison).

## Loading image

Given the promising results of the Array#pack method, using its counterpart String#unpack looks promising for speedy image loading, if you know the image’s size and the encoding format beforehand.

An RGBA formatted stream can be loaded quickly with this command:

{% highlight ruby %}
pixels = rgba_pixeldata.unpack("N#{width * height}")
image = Image.new(width, height, pixels)
{% endhighlight %}

For an RGB formatted stream, we can use the X modifier again, but we have to make sure to set the alpha value for every pixel to 255:

{% highlight ruby %}
pixels = rgb_pixeldata.unpack("NX" * (width * height))
pixels.map! { |pixel| pixel | 0x000000ff }
image = Image.new(width, height, pixels)
{% endhighlight %}

You can even use little-endian integers to load streams in ABGR format!

{% highlight ruby %}
pixels = abgr_pixeldata.unpack("V#{width * height}")
image = Image.new(width, height, pixels)
{% endhighlight %}

Loading pixel data for an image like this is again over 1500% faster than decoding the same PNG image. However, this can only be applied if you have control over the input format of the image.

## To conclude

`Array#pack` and `String#unpack` really have increased the performance for my code. If you can apply them for project, don’t hesitate and spread the love! For all other cases, use as little code as possible, and upgrade to Ruby 1.9 for improved algorithmic performance.
