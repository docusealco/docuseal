# frozen_string_literal: true

module Leptonica
  extend FFI::Library

  begin
    ffi_lib %w[
      libleptonica.so.6
      liblept.so.5
      leptonica
      /opt/homebrew/lib/libleptonica.6.dylib
      /usr/local/lib/libleptonica.6.dylib
    ]
  rescue LoadError => e
    raise "Could not load leptonica library. Make sure it's installed and in your library path. Error: #{e.message}"
  end

  typedef :pointer, :PIX
  typedef :pointer, :PTA
  typedef :pointer, :BOX
  typedef :pointer, :BOXA
  typedef :pointer, :PIXA

  L_CLONE = 2
  L_SEVERITY_NONE = 6

  DETECT_WIDTH = 256
  MIN_QUAD_AREA_RATIO = 0.2
  MIN_ORIENT_CONF = 8.0
  ORIENT_CONF_RATIO = 2.5

  LeptonicaError = Class.new(StandardError)

  attach_function :setMsgSeverity, [:int], :int
  attach_function :pixCreate, %i[int int int], :PIX
  attach_function :pixSetSpp, %i[PIX int], :int
  attach_function :pixClone, [:PIX], :PIX
  attach_function :pixDestroy, [:pointer], :void
  attach_function :pixGetWidth, [:PIX], :int
  attach_function :pixGetHeight, [:PIX], :int
  attach_function :pixGetDepth, [:PIX], :int
  attach_function :pixGetWpl, [:PIX], :int
  attach_function :pixGetData, [:PIX], :pointer
  attach_function :pixConvertTo32, [:PIX], :PIX
  attach_function :pixConvertTo8, %i[PIX int], :PIX
  attach_function :pixInvert, %i[PIX PIX], :PIX
  attach_function :pixScaleToSize, %i[PIX int int], :PIX
  attach_function :pixOtsuAdaptiveThreshold, %i[PIX int int int int float pointer pointer], :int
  attach_function :pixCloseBrick, %i[PIX PIX int int], :PIX
  attach_function :pixOpenBrick, %i[PIX PIX int int], :PIX
  attach_function :pixConnComp, %i[PIX pointer int], :BOXA
  attach_function :pixCountPixels, %i[PIX pointer pointer], :int
  attach_function :boxaGetCount, [:BOXA], :int
  attach_function :boxaGetBox, %i[BOXA int int], :BOX
  attach_function :boxaDestroy, [:pointer], :void
  attach_function :boxCreate, %i[int int int int], :BOX
  attach_function :boxDestroy, [:pointer], :void
  attach_function :boxGetGeometry, %i[BOX pointer pointer pointer pointer], :int
  attach_function :pixaGetPix, %i[PIXA int int], :PIX
  attach_function :pixaDestroy, [:pointer], :void
  attach_function :pixClipRectangle, %i[PIX BOX pointer], :PIX
  attach_function :ptaCreate, [:int], :PTA
  attach_function :ptaAddPt, %i[PTA float float], :int
  attach_function :ptaDestroy, [:pointer], :void
  attach_function :pixProjectivePtaColor, %i[PIX PTA PTA uint], :PIX
  attach_function :pixRotateOrth, %i[PIX int], :PIX
  attach_function :pixOrientDetect, %i[PIX pointer pointer int int], :int
  attach_function :pixFlipLR, %i[PIX PIX], :PIX
  attach_function :pixFlipTB, %i[PIX PIX], :PIX
  attach_function :pixBackgroundNormSimple, %i[PIX PIX PIX], :PIX
  attach_function :pixGammaTRC, %i[PIX PIX float int int], :PIX
  attach_function :pixEndianByteSwap, [:PIX], :int
  attach_function :dewarpSinglePage, %i[PIX int int int int pointer pointer int], :int

  setMsgSeverity(L_SEVERITY_NONE)

  module_function

  def crop_document(image_data, corners, scan: false, rotate: nil, flip_h: false, flip_v: false)
    pix = read_pix(image_data)

    begin
      pix32 = checked(pixConvertTo32(pix), 'Failed to convert image to 32bpp')

      begin
        width = pixGetWidth(pix32)
        height = pixGetHeight(pix32)

        points = corners.map { |point| [point['x'].to_f * width, point['y'].to_f * height] }

        out_width, out_height = output_size(points, width, height)

        warped = projective_crop(pix32, points, out_width, out_height)

        begin
          rotate = rotate.nil? ? detect_orientation(warped) : rotate.to_i

          result = transform_result(warped, scan:, rotate:, flip_h:, flip_v:)

          read_bytes(result)
        ensure
          destroy_pix(result) if result && !result.equal?(warped)
          destroy_pix(warped)
        end
      ensure
        destroy_pix(pix32)
      end
    ensure
      destroy_pix(pix)
    end
  end

  def detect_document_corners(image_data)
    pix = read_detect_pix(image_data)

    begin
      mask = build_page_mask(pix)

      return if mask.nil?

      begin
        corners = mask_corners(mask)
      ensure
        destroy_pix(mask)
      end

      return if corners.nil? || quad_area(corners) < MIN_QUAD_AREA_RATIO

      corners.map { |x, y| { 'x' => x.round(6), 'y' => y.round(6) } }
    ensure
      destroy_pix(pix)
    end
  end

  def read_pix(image_data)
    build_pix(load_image(image_data))
  end

  def read_detect_pix(image_data)
    image = load_image(image_data)

    height = (DETECT_WIDTH * image.height / image.width.to_f).round.clamp(8, DETECT_WIDTH * 4)
    image = image.resize(DETECT_WIDTH / image.width.to_f, vscale: height / image.height.to_f)

    build_pix(image)
  end

  def build_pix(image)
    pix = checked(pixCreate(image.width, image.height, 32), 'Failed to read image')

    pixSetSpp(pix, 3)
    pixGetData(pix).put_bytes(0, image.write_to_memory)

    raise LeptonicaError, 'Failed to read image' unless pixEndianByteSwap(pix).zero?

    pix
  end

  def load_image(image_data)
    image = ImageUtils.load_vips(image_data)

    image = image.colourspace(:srgb) if image.interpretation != :srgb
    image = image.cast(:uchar) if image.format != :uchar
    image = image.bandjoin(255) unless image.has_alpha?

    image
  end

  def projective_crop(pix32, points, out_width, out_height)
    ptas = ptaCreate(4)
    ptad = ptaCreate(4)

    begin
      points.each { |x, y| ptaAddPt(ptas, x, y) }

      [[0, 0], [out_width, 0], [out_width, out_height], [0, out_height]].each { |x, y| ptaAddPt(ptad, x, y) }

      warped = checked(pixProjectivePtaColor(pix32, ptad, ptas, 0xffffff00), 'Failed to warp image')

      begin
        box = boxCreate(0, 0, out_width, out_height)

        begin
          checked(pixClipRectangle(warped, box, nil), 'Failed to clip image')
        ensure
          destroy_box(box)
        end
      ensure
        destroy_pix(warped)
      end
    ensure
      destroy_pta(ptas)
      destroy_pta(ptad)
    end
  end

  def transform_result(warped, scan:, rotate:, flip_h:, flip_v:)
    steps = []

    steps << ->(pix) { whiten(pix) } if scan
    steps << ->(pix) { checked(pixFlipLR(nil, pix), 'Failed to flip image') } if flip_h
    steps << ->(pix) { checked(pixFlipTB(nil, pix), 'Failed to flip image') } if flip_v
    steps << ->(pix) { checked(pixRotateOrth(pix, rotate / 90), 'Failed to rotate image') } unless rotate.zero?
    steps << ->(pix) { dewarp(pix) } if scan

    steps.reduce(warped) do |current, step|
      step.call(current)
    ensure
      destroy_pix(current) unless current.equal?(warped)
    end
  end

  def output_size(points, width, height)
    out_width = (distance(points[0], points[1]) + distance(points[3], points[2])) / 2.0
    out_height = (distance(points[0], points[3]) + distance(points[1], points[2])) / 2.0

    [out_width.round.clamp(8, width * 2), out_height.round.clamp(8, height * 2)]
  end

  def detect_orientation(pix32)
    gray = pixConvertTo8(pix32, 0)

    return 0 if gray.null?

    binary_ptr = FFI::MemoryPointer.new(:pointer)
    result = pixOtsuAdaptiveThreshold(gray, pixGetWidth(gray), pixGetHeight(gray), 0, 0, 0.1, nil, binary_ptr)

    destroy_pix(gray)

    binary = binary_ptr.read_pointer

    return 0 if result != 0 || binary.null?

    upconf_ptr = FFI::MemoryPointer.new(:float)
    leftconf_ptr = FFI::MemoryPointer.new(:float)
    result = pixOrientDetect(binary, upconf_ptr, leftconf_ptr, 0, 0)

    destroy_pix(binary)

    return 0 unless result.zero?

    orientation_rotation(upconf_ptr.read_float, leftconf_ptr.read_float)
  end

  def orientation_rotation(upconf, leftconf)
    if leftconf >= MIN_ORIENT_CONF && leftconf >= ORIENT_CONF_RATIO * upconf.abs
      90
    elsif -upconf >= MIN_ORIENT_CONF && -upconf >= ORIENT_CONF_RATIO * leftconf.abs
      180
    elsif -leftconf >= MIN_ORIENT_CONF && -leftconf >= ORIENT_CONF_RATIO * upconf.abs
      270
    else
      0
    end
  end

  def dewarp(pix)
    out_ptr = FFI::MemoryPointer.new(:pointer)

    result = dewarpSinglePage(pix, 0, 1, 1, 0, out_ptr, nil, 0)

    out = out_ptr.read_pointer

    return pixClone(pix) if result != 0 || out.null?

    out
  end

  def whiten(pix)
    normalized = checked(pixBackgroundNormSimple(pix, nil, nil), 'Failed to normalize background')

    begin
      checked(pixGammaTRC(nil, normalized, 1.0, 70, 190), 'Failed to adjust contrast')
    ensure
      destroy_pix(normalized)
    end
  end

  def read_bytes(pix)
    width = pixGetWidth(pix)
    height = pixGetHeight(pix)

    raise LeptonicaError, 'Failed to read pixels' unless pixEndianByteSwap(pix).zero?

    [pixGetData(pix).read_bytes(width * height * 4), width, height]
  end

  def build_page_mask(pix)
    gray = checked(pixConvertTo8(pix, 0), 'Failed to convert image to grayscale')

    begin
      binary_ptr = FFI::MemoryPointer.new(:pointer)

      result = pixOtsuAdaptiveThreshold(gray, pixGetWidth(gray), pixGetHeight(gray), 0, 0, 0.1,
                                        nil, binary_ptr)

      return if result != 0 || binary_ptr.read_pointer.null?

      binary = binary_ptr.read_pointer

      begin
        clean_mask(binary)
      ensure
        destroy_pix(binary)
      end
    ensure
      destroy_pix(gray)
    end
  end

  def clean_mask(binary)
    inverted = checked(pixInvert(nil, binary), 'Failed to invert mask')

    begin
      closed = checked(pixCloseBrick(nil, inverted, 5, 5), 'Failed to close mask')

      begin
        checked(pixOpenBrick(nil, closed, 3, 3), 'Failed to open mask')
      ensure
        destroy_pix(closed)
      end
    ensure
      destroy_pix(inverted)
    end
  end

  def mask_corners(mask)
    width = pixGetWidth(mask)
    height = pixGetHeight(mask)

    pixels = read_mask_pixels(mask)

    return if pixels.empty?

    bounds = largest_component_bounds(mask)

    if bounds
      box_x, box_y, box_w, box_h = bounds

      pixels = pixels.select do |x, y|
        x.between?(box_x, box_x + box_w - 1) && y.between?(box_y, box_y + box_h - 1)
      end

      return if pixels.empty?
    end

    image_corners = [[0, 0], [width - 1, 0], [width - 1, height - 1], [0, height - 1]]

    corners = image_corners.map do |corner_x, corner_y|
      pixels.min_by { |x, y| (x - corner_x).abs + (y - corner_y).abs }
    end

    return if corners.uniq.size < 4

    corners.map { |x, y| [x / width.to_f, y / height.to_f] }
  end

  def largest_component_bounds(mask)
    pixa_ptr = FFI::MemoryPointer.new(:pointer)
    boxa = pixConnComp(mask, pixa_ptr, 8)

    return if boxa.null?

    pixa = pixa_ptr.read_pointer

    begin
      geometry = Array.new(4) { FFI::MemoryPointer.new(:int) }

      bounds = nil
      best_area = 0

      boxaGetCount(boxa).times do |index|
        box = boxaGetBox(boxa, index, L_CLONE)

        next if box.null?

        boxGetGeometry(box, *geometry)

        box_x, box_y, box_w, box_h = geometry.map(&:read_int)

        if box_w * box_h > best_area
          best_area = box_w * box_h
          bounds = [box_x, box_y, box_w, box_h]
        end

        destroy_box(box)
      end

      bounds
    ensure
      destroy_pixa(pixa)
      destroy_boxa(boxa)
    end
  end

  def read_mask_pixels(pix)
    width = pixGetWidth(pix)
    height = pixGetHeight(pix)
    wpl = pixGetWpl(pix)

    raise LeptonicaError, 'Failed to read mask' unless pixEndianByteSwap(pix).zero?

    data = pixGetData(pix).read_bytes(wpl * 4 * height)

    pixEndianByteSwap(pix)

    pixels = []

    height.times do |y|
      row_offset = y * wpl * 4

      width.times do |x|
        byte = data.getbyte(row_offset + (x / 8))

        pixels << [x, y] if byte.anybits?(0x80 >> (x % 8))
      end
    end

    pixels
  end

  def quad_area(corners)
    area = 0.0

    corners.each_with_index do |(x1, y1), index|
      x2, y2 = corners[(index + 1) % 4]

      area += (x1 * y2) - (x2 * y1)
    end

    (area / 2.0).abs
  end

  def distance(point_a, point_b)
    Math.sqrt(((point_a[0] - point_b[0])**2) + ((point_a[1] - point_b[1])**2))
  end

  def checked(pix, message)
    raise LeptonicaError, message if pix.nil? || pix.null?

    pix
  end

  def destroy_pix(pix)
    return if pix.nil? || pix.null?

    pix_ptr = FFI::MemoryPointer.new(:pointer)
    pix_ptr.write_pointer(pix)

    pixDestroy(pix_ptr)
  end

  def destroy_pta(pta)
    return if pta.nil? || pta.null?

    pta_ptr = FFI::MemoryPointer.new(:pointer)
    pta_ptr.write_pointer(pta)

    ptaDestroy(pta_ptr)
  end

  def destroy_box(box)
    return if box.nil? || box.null?

    box_ptr = FFI::MemoryPointer.new(:pointer)
    box_ptr.write_pointer(box)

    boxDestroy(box_ptr)
  end

  def destroy_boxa(boxa)
    return if boxa.nil? || boxa.null?

    boxa_ptr = FFI::MemoryPointer.new(:pointer)
    boxa_ptr.write_pointer(boxa)

    boxaDestroy(boxa_ptr)
  end

  def destroy_pixa(pixa)
    return if pixa.nil? || pixa.null?

    pixa_ptr = FFI::MemoryPointer.new(:pointer)
    pixa_ptr.write_pointer(pixa)

    pixaDestroy(pixa_ptr)
  end
end
