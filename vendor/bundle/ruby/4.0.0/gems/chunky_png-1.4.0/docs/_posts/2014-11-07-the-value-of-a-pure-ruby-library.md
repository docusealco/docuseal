---
author: Willem van Bergen
title: The value of a pure Ruby library
---

In late 2009, my employer at the time &mdash; [Floorplanner](https://www.floorplanner.com) &mdash; was struggling with memory leaks in [RMagick](https://www.imagemagick.org/RMagick/doc/), a Ruby wrapper around the image manipulation library [ImageMagick](https://www.imagemagick.org/). Because we only needed a small subset of RMagick's functionality, I decided to write a simple library so we could get rid of RMagick. Not much later, [ChunkyPNG was born](https://github.com/wvanbergen/chunky_png/commit/aa8a9378eedfc02aa1d0d1e05c313badc76594a7).

Even though ChunkyPNG has grown in scope and complexity to cover the entire PNG standard, it still is a "pure Ruby" library: all of the code is Ruby, and it doesn't have any dependencies besides Ruby itself. Initially, this was purely for practical reasons: I knew Ruby wasn't the fastest language in the world, but I had no idea how to write Ruby C extensions. Performance was not an important concern for the problem at hand, and maybe RMagick being a C extension was the cause of its memory leaks? By writing pure Ruby, I could get results faster and let the Ruby interpreter do the hard work of managing memory for me. <sup>[1]</sup>

### Performance becomes important

Mostly as a learning project, I ended up implementing the entire PNG standard. This made the library suitable for a broader set of problems, and more people started using it. Performance then became more important. I put a decent effort into optimizing the memory efficiency by [optimizing storing pixels in memory]({% post_url 2010-01-14-memory-efficiency-when-using-ruby %}), and I boosted performance by [short-circuiting the PNG encoding routine using Array#pack]({% post_url 2010-01-17-ode-to-array-pack-and-string-unpack %}).

Even though these efforts resulted in sizable improvements, it became clear that there are limits on how far you can push performance in Ruby. The fact that I am implementing a library that by nature requires a lot of memory and computation is not going to change.

So what are the options? I could recommend RMagick to people asking for more performance, but that is not going to happen after all my ImageMagick bashing. <sup>[2]</sup> In the end, I had to roll up my sleeves and program some C.

### Being pure Ruby is a feature

To tackle the performance issue, I had the options of either implementing the C extension as part of ChunkyPNG, or build a separate library. <sup>[3]</sup> My initial gut feeling was to add a C extension to ChunkyPNG to give everyone a free performance boost. However, I soon discovered many people were using the library *because* it was pure Ruby. For me, it was a pragmatic implementation detail; for them, it was a feature.

Including a C extension would require everybody that wants to install ChunkyPNG to have a compiler toolchain installed. For me, installing a compiler toolchain is the first thing I do when I get a new machine. This is true for many Ruby developers, but it turns out that many of the library users are not Ruby developers at all. [Compass](http://compass-style.org/), a popular CSS authoring framework, uses ChunkyPNG to generate sprite images. Most Compass users are front-end developers who primarily use HTML, CSS and Javascript, and not Ruby. Because OS X comes with Ruby and Rubygems installed, running `gem install compass` works out of the box. Telling them to install a C compiler chain is simply an unacceptable installation requirement.

There are a couple of additional advantages of being a pure Ruby library. As an open source project ChunkyPNG can attract more contributors, because only a small percentage of Ruby developers are well-versed in C. Moreover, C extensions are MRI specific. This means that many C extensions won't work on Rubinius or JRuby, and I wanted my library to work in these environments as well. <sup>[4]</sup> Finally, libraries that require a C compiler inevitably get a lot of bug reports or support requests of people that are having issues installing the library, because of differences in development environments. <sup>[5]</sup>

### OilyPNG: a mixin library

So instead of adding a C extension, I started working on a separate library: [OilyPNG](https://github.com/wvanbergen/oily_png). Rather than making this a standalone library, I designed it to be a mixin module that depends on ChunkyPNG.

The approach is simple: OilyPNG consists of modules that implement some of the methods of ChunkyPNG in C. When  OilyPNG is loaded with `require 'oily_png'`, it first loads ChunkyPNG and uses `Module#include` and `Module#extend` to [overwrite some methods in ChunkyPNG with OilyPNG's faster implementation](https://github.com/wvanbergen/oily_png/blob/master/lib/oily_png.rb).

This approach allows us to keep ChunkyPNG pure Ruby, and make OilyPNG 100% API compatible with ChunkyPNG. It is even possible to make OilyPNG optional in your project:

{% highlight ruby %}
begin
  require 'oily_png'
rescue LoadError
  require 'chunky_png'
end
{% endhighlight %}

This approach has some other advantages as well. Instead of having to implement everything at once to get to a library that implements most of ChunkyPNG, we can do this step by step while always providing 100% functional parity. Profile ChunkyPNG to find a slow method, implement it in OilyPNG, and iterate. This way OilyPNG doesn't suffer from a bootstrapping problem of having to implement and minimum viable subset of ChunkyPNG right from the start. It can grow organically, one optimized method at the time.

And because we have a well tested, pure Ruby implementation available to which OilyPNG is supposed to be 100% compatible, testing OilyPNG is simple. We just call a method on ChunkyPNG, run the exact same call on an OilyPNG-enhanced ChunkyPNG, and compare the results.

### To conclude

Being pure Ruby can be an important feature of a library for many of its users. Don't give it up too easily, even though Ruby's lacking performance may be an issue. Using a hybrid approach of a pure Ruby library with a native companion library is a great way to have the best of both worlds. <sup>[6]</sup>

---------------------------------------

#### Footnotes

1. This is also why I avoided using the [png gem](https://github.com/seattlerb/png), an "almost-pure-ruby" library that was available at the time. It uses [inline C](https://github.com/seattlerb/rubyinline) to speed up some of the algorithms.
2. Disclaimer: I should note that I haven't used ImageMagick and RMagick since 2010. So my knowledge about the current state of these libraries is extremely outdated at this point.
3. I could have leveraged the work of [libpng](http://www.libpng.org/pub/png/libpng.html) instead of implementing the algorithms myself. I decided not to, because libpng's API doesn't lend itself very well for the cherry-picking of hotspots approach I took with OilyPNG. You basically have to go all in if you want to use libpng. I think a Ruby PNG library that simply wraps libpng still has potential, but because of the reasons outlined in this article, I will leave that as an exercise to the reader. :)
4. Rubinius since has implemented most of MRI's C API so you can compile many C extensions against Rubinius as well, including OilyPNG. As an interesting side note: the Rubinius and JRuby developers have used ChunkyPNG as a performance benchmarking tool, because it contains a non-trivial amount of code and is computation heavy.
5. Unfortunately, OilyPNG is [not an exception](https://github.com/wvanbergen/oily_png/issues/12) to this rule.
6. My current employer &mdash; [Shopify](https://www.shopify.com) &mdash; is using the same approach for [Liquid](https://shopify.github.io/liquid/) and its C companion library [liquid-c](https://github.com/Shopify/liquid-c) with great success. Even though this requires matching Liquid's parsing behavior in certain edge cases quirk by quirk in the C implementation.

Thanks to Simon Hørup Eskildsen, Emilie Noël, and Steven H. Noble for reviewing drafts of this post.
