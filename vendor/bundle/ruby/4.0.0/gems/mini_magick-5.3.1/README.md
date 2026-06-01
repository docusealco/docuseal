# MiniMagick
[![Gem Version](https://img.shields.io/gem/v/mini_magick.svg)](http://rubygems.org/gems/mini_magick)
[![Gem Downloads](https://img.shields.io/gem/dt/mini_magick.svg)](http://rubygems.org/gems/mini_magick)
[![CI](https://github.com/minimagick/minimagick/actions/workflows/ci.yml/badge.svg)](https://github.com/minimagick/minimagick/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/minimagick/minimagick/badges/gpa.svg)](https://codeclimate.com/github/minimagick/minimagick)

A ruby wrapper for [ImageMagick](http://imagemagick.org/) command line.

## Why?

I was using [RMagick](https://github.com/rmagick/rmagick) and loving it, but it
was eating up huge amounts of memory. Even a simple script would use over 100MB
of RAM. On my local machine this wasn't a problem, but on my hosting server the
ruby apps would crash because of their 100MB memory limit.

## Solution!

Using MiniMagick the ruby processes memory remains small (it spawns
ImageMagick's command line program mogrify which takes up some memory as well,
but is much smaller compared to RMagick). See [Thinking of switching from
RMagick?](#thinking-of-switching-from-rmagick) below.

MiniMagick gives you access to all the command line options ImageMagick has
(found [here](http://www.imagemagick.org/script/command-line-options.php)).

## Requirements

ImageMagick command-line tool has to be installed. You can check if you have it
installed by running

```sh
$ magick -version
Version: ImageMagick 7.1.1-33 Q16-HDRI aarch64 22263 https://imagemagick.org
Copyright: (C) 1999 ImageMagick Studio LLC
License: https://imagemagick.org/script/license.php
Features: Cipher DPC HDRI Modules OpenMP(5.0)
Delegates (built-in): bzlib fontconfig freetype gslib heic jng jp2 jpeg jxl lcms lqr ltdl lzma openexr png ps raw tiff webp xml zlib zstd
Compiler: gcc (4.2)
```

## Installation

Add the gem to your Gemfile:

```sh
$ bundle add mini_magick
```

## Information

* [API documentation](https://rubydoc.info/gems/mini_magick)

## Usage

Let's first see a basic example of resizing an image.

```rb
require "mini_magick"

image = MiniMagick::Image.open("input.jpg")
image.path #=> "/var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/magick20140921-75881-1yho3zc.jpg"
image.resize "100x100"
image.format "png"
image.write "output.png"
```

`MiniMagick::Image.open` makes a copy of the image, and further methods modify
that copy (the original stays untouched). We then
[resize](http://www.imagemagick.org/script/command-line-options.php#resize)
the image, and write it to a file. The writing part is necessary because
the copy is just temporary, it gets garbage collected when we lose reference
to the image.

`MiniMagick::Image.open` also accepts URLs, and options passed in will be
forwarded to [open-uri](https://github.com/ruby/open-uri).

```rb
image = MiniMagick::Image.open("http://example.com/image.jpg")
image.contrast
image.write("from_internets.jpg")
```

On the other hand, if we want the original image to actually *get* modified,
we can use `MiniMagick::Image.new`.

```rb
image = MiniMagick::Image.new("input.jpg")
image.path #=> "input.jpg"
image.resize "100x100"
# Not calling #write, because it's not a copy
```

### Combine options

While using methods like `#resize` directly is convenient, if we use more
methods in this way, it quickly becomes inefficient, because it calls the
command on each methods call. `MiniMagick::Image#combine_options` takes
multiple options and from them builds one single command.

```rb
image.combine_options do |b|
  b.resize "250x200>"
  b.rotate "-90"
  b.flip
end # the command gets executed
```

As a handy shortcut, `MiniMagick::Image.new` also accepts an optional block
which is used to `combine_options`.

```rb
image = MiniMagick::Image.new("input.jpg") do |b|
  b.resize "250x200>"
  b.rotate "-90"
  b.flip
end # the command gets executed
```

The yielded builder is an instance of `MiniMagick::Tool`. To learn more
about its interface, see [Tools](#tools) below.

### Attributes

A `MiniMagick::Image` has various handy attributes.

```rb
image.type        #=> "JPEG"
image.width       #=> 250
image.height      #=> 300
image.dimensions  #=> [250, 300]
image.size        #=> 3451 (in bytes)
image.colorspace  #=> "DirectClass sRGB"
image.exif        #=> {"DateTimeOriginal" => "2013:09:04 08:03:39", ...}
image.resolution  #=> [75, 75]
image.signature   #=> "60a7848c4ca6e36b8e2c5dea632ecdc29e9637791d2c59ebf7a54c0c6a74ef7e"
```

If you need more control, you can also access [raw image
attributes](http://www.imagemagick.org/script/escape.php):

```rb
image["%[gamma]"] # "0.9"
```

To get the all information about the image, MiniMagick gives you a handy method
which returns the output from `magick input.jpg json:`:

```rb
image.data #=>
# {
#   "format": "JPEG",
#   "mimeType": "image/jpeg",
#   "class": "DirectClass",
#   "geometry": {
#     "width": 200,
#     "height": 276,
#     "x": 0,
#     "y": 0
#   },
#   "resolution": {
#     "x": "300",
#     "y": "300"
#   },
#   "colorspace": "sRGB",
#   "channelDepth": {
#     "red": 8,
#     "green": 8,
#     "blue": 8
#   },
#   "quality": 92,
#   "properties": {
#     "date:create": "2016-07-11T19:17:53+08:00",
#     "date:modify": "2016-07-11T19:17:53+08:00",
#     "exif:ColorSpace": "1",
#     "exif:ExifImageLength": "276",
#     "exif:ExifImageWidth": "200",
#     "exif:ExifOffset": "90",
#     "exif:Orientation": "1",
#     "exif:ResolutionUnit": "2",
#     "exif:XResolution": "300/1",
#     "exif:YResolution": "300/1",
#     "icc:copyright": "Copyright (c) 1998 Hewlett-Packard Company",
#     "icc:description": "sRGB IEC61966-2.1",
#     "icc:manufacturer": "IEC http://www.iec.ch",
#     "icc:model": "IEC 61966-2.1 Default RGB colour space - sRGB",
#     "jpeg:colorspace": "2",
#     "jpeg:sampling-factor": "1x1,1x1,1x1",
#     "signature": "1b2336f023e5be4a9f357848df9803527afacd4987ecc18c4295a272403e52c1"
#   },
#   ...
# }
```

### Pixels

With MiniMagick you can retrieve a matrix of image pixels, where each member of
the matrix is a 3-element array of numbers between 0-255, one for each range of
the RGB color channels.

```rb
image = MiniMagick::Image.open("image.jpg")
pixels = image.get_pixels
pixels[3][2][1] # the green channel value from the 4th-row, 3rd-column pixel
```

It can also be called after applying transformations:

```rb
image = MiniMagick::Image.open("image.jpg")
image.crop "20x30+10+5"
image.colorspace "Gray"
pixels = image.get_pixels
```

### Pixels To Image

Sometimes when you have pixels and want to create image from pixels, you can do this to form an image:

```rb
image = MiniMagick::Image.open('/Users/rabin/input.jpg')
pixels = image.get_pixels
depth = 8
dimension = [image.width, image.height]
map = 'rgb'
image = MiniMagick::Image.get_image_from_pixels(pixels, dimension, map, depth ,'jpg')
image.write('/Users/rabin/output.jpg')
```

In this example, the returned pixels should now have equal R, G, and B values.

### Configuration

Here are the available configuration options with their default values:

```rb
MiniMagick.configure do |config|
  config.timeout = nil # number of seconds IM commands may take
  config.errors = true # raise errors non nonzero exit status
  config.warnings = true # forward warnings to standard error
  config.tmpdir = Dir.tmpdir # alternative directory for tempfiles
  config.logger = Logger.new($stdout) # where to log IM commands
  config.cli_prefix = nil # add prefix to all IM commands
  config.cli_env = {} # environment variables to set for IM commands
  config.restricted_env = false # when true, block IM commands from accessing system environment variables other than those in cli_env
end
```

For a more information, see
[Configuration](https://rubydoc.info/gems/mini_magick/MiniMagick/Configuration) API documentation.

### Composite

MiniMagick also allows you to
[composite](http://www.imagemagick.org/script/composite.php) images:

```rb
first_image  = MiniMagick::Image.new("first.jpg")
second_image = MiniMagick::Image.new("second.jpg")
result = first_image.composite(second_image) do |c|
  c.compose "Over"    # OverCompositeOp
  c.geometry "+20+20" # copy second_image onto first_image from (20, 20)
end
result.write "output.jpg"
```

### Layers/Frames/Pages

For multilayered images you can access its layers.

```rb
gif.frames #=> [...]
pdf.pages  #=> [...]
psd.layers #=> [...]

gif.frames.each_with_index do |frame, idx|
  frame.write("frame#{idx}.jpg")
end
```

### Image validation

You can test whether an image is valid by running it through `identify`:

```rb
image.valid?
image.validate! # raises MiniMagick::Invalid if image is invalid
```

### Logging

You can choose to log MiniMagick commands and their execution times:

```rb
MiniMagick.logger.level = Logger::DEBUG
```
```
D, [2016-03-19T07:31:36.755338 #87191] DEBUG -- : [0.01s] identify /var/folders/k7/6zx6dx6x7ys3rv3srh0nyfj00000gn/T/mini_magick20160319-87191-1ve31n1.jpg
```

In Rails you'll probably want to set `MiniMagick.logger = Rails.logger`.

## Tools

If you prefer not to use the `MiniMagick::Image` abstraction, you can use ImageMagick's command-line tools directly:

```rb
MiniMagick.convert do |convert|
  convert << "input.jpg"
  convert.resize("100x100")
  convert.negate
  convert << "output.jpg"
end #=> `magick input.jpg -resize 100x100 -negate output.jpg`

# OR

convert = MiniMagick.convert
convert << "input.jpg"
convert.resize("100x100")
convert.negate
convert << "output.jpg"
convert.call #=> `magick input.jpg -resize 100x100 -negate output.jpg`
```

This way of using MiniMagick is highly recommended if you want to maximize performance of your image processing. There are class methods for each CLI tool: `animate`, `compare`, `composite`, `conjure`, `convert`, `display`, `identify`, `import`, `mogrify` and `stream`. The `MiniMagick.convert` method will use `magick` on ImageMagick 7 and `convert` on ImageMagick 6.

### Appending

The most basic way of building a command is appending strings:

```rb
MiniMagick.convert do |convert|
  convert << "input.jpg"
  convert.merge! ["-resize", "500x500", "-negate"]
  convert << "output.jpg"
end
```

Note that it is important that every command you would pass to the command line
has to be separated with `<<`, e.g.:

```rb
# GOOD
convert << "-resize" << "500x500"

# BAD
convert << "-resize 500x500"
```

Shell escaping is also handled for you. If an option has a value that has
spaces inside it, just pass it as a regular string.

```rb
convert << "-distort"
convert << "Perspective"
convert << "0,0,0,0 0,45,0,45 69,0,60,10 69,45,60,35"
```
```
magick -distort Perspective '0,0,0,0 0,45,0,45 69,0,60,10 69,45,60,35'
```

### Methods

Instead of passing in options directly, you can use Ruby methods:

```rb
convert.resize("500x500")
convert.rotate(90)
convert.distort("Perspective", "0,0,0,0 0,45,0,45 69,0,60,10 69,45,60,35")
```

### Chaining

Every method call returns `self`, so you can chain them to create logical groups.

```rb
MiniMagick.convert do |convert|
  convert << "input.jpg"
  convert.clone(0).background('gray').shadow('80x5+5+5')
  convert.negate
  convert << "output.jpg"
end
```

### "Plus" options

```rb
MiniMagick.convert do |convert|
  convert << "input.jpg"
  convert.repage.+
  convert.distort.+("Perspective", "more args")
end
```
```
magick input.jpg +repage +distort Perspective 'more args'
```

### Stacks

```rb
MiniMagick.convert do |convert|
  convert << "wand.gif"

  convert.stack do |stack|
    stack << "wand.gif"
    stack.rotate(30)
    stack.foo("bar", "baz")
  end
  # or
  convert.stack("wand.gif", { rotate: 30, foo: ["bar", "baz"] })

  convert << "images.gif"
end
```
```
magick wand.gif \( wand.gif -rotate 90 -foo bar baz \) images.gif
```

### STDIN and STDOUT

If you want to pass something to standard input, you can pass the `:stdin`
option to `#call`:

```rb
identify = MiniMagick.identify
identify.stdin # alias for "-"
identify.call(stdin: image_content)
```

MiniMagick also has `#stdout` alias for "-" for outputting file contents to
standard output:

```rb
content = MiniMagick.convert do |convert|
  convert << "input.jpg"
  convert.auto_orient
  convert.stdout # alias for "-"
end
```

### Capturing STDERR

Some MiniMagick tools such as `compare` output the result of the command on
standard error, even if the command succeeded. The result of
`MiniMagick::Tool#call` is always the standard output, but if you pass it a
block, it will yield the stdout, stderr and exit status of the command:

```rb
compare = MiniMagick.compare
# build the command
compare.call do |stdout, stderr, status|
  # ...
end
```

## Configuring

### GraphicsMagick

As of MiniMagick 5+, [GraphicsMagick](http://www.graphicsmagick.org/) isn't
officially supported. This means its installation won't be auto-detected, and no
attempts will be made to handle differences in GraphicsMagick API or output.

However, you can still configure MiniMagick to use it:

```rb
MiniMagick.configure do |config|
  config.graphicsmagick = true
end
```

Some MiniMagick features won't be supported, such as global timeout,
`MiniMagick::Image#data` and `MiniMagick::Image#exif`.

### Limiting resources

ImageMagick supports a number of [environment variables] for controlling its
resource limits. For example, you can enforce memory or execution time limits by
setting the following:

```rb
MiniMagick.configure do |config|
  config.cli_env = {
    "MAGICK_MEMORY_LIMIT" => "128MiB",
    "MAGICK_MAP_LIMIT" => "64MiB",
    "MAGICK_TIME_LIMIT" => "30"
  }
end
```

For time limit you can also use the `timeout` configuration:

```rb
MiniMagick.configure do |config|
  config.timeout = 30 # 30 seconds
end
```

### Changing temporary directory

ImageMagick allows you to change the temporary directory to process the image file:

```rb
MiniMagick.configure do |config|
  config.tmpdir = File.join(Dir.tmpdir, "/my/new/tmp_dir")
end
```

The example directory `/my/new/tmp_dir` must exist and must be writable.

If not configured, it will default to `Dir.tmpdir`.

### Ignoring STDERR

If you're receiving warnings from ImageMagick that you don't care about, you
can avoid them being forwarded to standard error:

```rb
MiniMagick.configure do |config|
  config.warnings = false
end
```

### Avoiding raising errors

This gem raises an error when ImageMagick returns a nonzero exit code.
Sometimes, however, ImageMagick returns nonzero exit codes when the command
actually went ok. In these cases, to avoid raising errors, you can add the
following configuration:

```rb
MiniMagick.configure do |config|
  config.errors = false
end
```

You can also pass `errors: false` to individual commands:

```rb
MiniMagick.identify(errors: false) do |b|
  b.help
end
```

## Thinking of switching from RMagick?

Unlike RMagick, MiniMagick is a much thinner wrapper around ImageMagick.

* To piece together MiniMagick commands refer to the [Mogrify
  Documentation](https://imagemagick.org/script/mogrify.php). For instance
  you can use the `-flop` option as `image.flop`.
* Operations on a MiniMagick image tend to happen in-place as `image.trim`,
  whereas RMagick has both copying and in-place methods like `image.trim` and
  `image.trim!`.
* To open files with MiniMagick you use `MiniMagick::Image.open` as you would
  `Magick::Image.read`. To open a file and directly edit it, use
  `MiniMagick::Image.new`.

[environment variables]: https://imagemagick.org/script/resources.php#environment
