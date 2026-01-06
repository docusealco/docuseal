# frozen_string_literal: true

module Templates
  module ImageToFields
    module_function

    Field = Struct.new(:type, :x, :y, :w, :h, :confidence, keyword_init: true) do
      def endy
        @endy ||= y + h
      end

      def endx
        @endx ||= x + w
      end
    end

    MODEL_PATH = Rails.root.join('tmp/model.onnx')

    INPUT_NAMES = %w[images input].freeze

    ID_TO_CLASS = %w[text checkbox].freeze

    MEAN = [0.485, 0.456, 0.406].freeze
    STD = [0.229, 0.224, 0.225].freeze

    CPU_THREADS = Etc.nprocessors

    # rubocop:disable Metrics
    def call(image, confidence: 0.3, nms: 0.1, temperature: 1,
             split_page: false, aspect_ratio: true, padding: nil, resolution: self.resolution)
      image = image.extract_band(0, n: 3) if image.bands > 3

      trimmed_base, base_offset_x, base_offset_y = trim_image_with_padding(image, padding)

      if model_v2?
        detections = call_v2(trimmed_base, base_offset_x, base_offset_y, split_page, confidence:, resolution:)
      elsif split_page && image.height > image.width
        regions = build_split_image_regions(trimmed_base)

        detections = { xyxy: Numo::SFloat[], confidence: Numo::SFloat[], class_id: Numo::Int32[] }

        detections = regions.reduce(detections) do |acc, r|
          next detections if r[:img].height <= 0 || r[:img].width <= 0

          input_tensor, transform_info = preprocess_image(r[:img], resolution, aspect_ratio:)

          transform_info[:trim_offset_x] = base_offset_x
          transform_info[:trim_offset_y] = base_offset_y + r[:offset_y]

          outputs = model.predict({ 'input' => input_tensor }, output_type: :numo)

          boxes = outputs['dets'][0, true, true]
          logits = outputs['labels'][0, true, true]

          postprocess_outputs(boxes, logits, transform_info, acc, confidence:, temperature:, resolution:)
        end
      else
        input_tensor, transform_info = preprocess_image(trimmed_base, resolution, aspect_ratio:)

        transform_info[:trim_offset_x] = base_offset_x
        transform_info[:trim_offset_y] = base_offset_y

        outputs = model.predict({ 'input' => input_tensor }, output_type: :numo)

        boxes = outputs['dets'][0, true, true]
        logits = outputs['labels'][0, true, true]

        detections = postprocess_outputs(boxes, logits, transform_info, confidence:, temperature:, resolution:)
      end

      detections = apply_nms(detections, nms)

      build_fields_from_detections(detections, image)
    end

    def call_v2(image, offset_x, offset_y, split_page, confidence:, resolution:)
      if split_page && image.height > image.width
        regions = build_split_image_regions(image)

        detections = { xyxy: Numo::SFloat[], confidence: Numo::SFloat[], class_id: Numo::Int32[] }

        regions.reduce(detections) do |acc, r|
          next acc if r[:img].height <= 0 || r[:img].width <= 0

          input_tensor, orig_size_tensor, transform_info = preprocess_image_v2(r[:img], resolution)

          outputs = model.predict({ 'images' => input_tensor, 'orig_target_sizes' => orig_size_tensor },
                                  output_type: :numo)

          boxes = outputs['boxes'][0, true, true]
          labels = outputs['labels'][0, true]
          scores = outputs['scores'][0, true]

          postprocess_outputs_v2(boxes, labels, scores, acc,
                                 offset_x:, offset_y: offset_y + r[:offset_y],
                                 confidence:, transform_info:)
        end
      else
        input_tensor, orig_size_tensor, transform_info = preprocess_image_v2(image, resolution)

        outputs = model.predict({ 'images' => input_tensor, 'orig_target_sizes' => orig_size_tensor },
                                output_type: :numo)

        boxes = outputs['boxes'][0, true, true]
        labels = outputs['labels'][0, true]
        scores = outputs['scores'][0, true]

        postprocess_outputs_v2(boxes, labels, scores, offset_x:, offset_y:,
                                                      confidence:, transform_info:)
      end
    end

    def preprocess_image_v2(image, resolution)
      image = image.extract_band(0, n: 3) if image.bands > 3

      ratio = [resolution.to_f / image.width, resolution.to_f / image.height].min
      new_width = (image.width * ratio).to_i
      new_height = (image.height * ratio).to_i

      image = image.resize(ratio, vscale: ratio, kernel: :linear) if ratio != 1

      pad_w = (resolution - new_width) / 2
      pad_h = (resolution - new_height) / 2

      padded = image.embed(pad_w, pad_h, resolution, resolution, background: [255, 255, 255])

      padded /= 255.0

      img_array = Numo::SFloat.from_binary(padded.write_to_memory, [resolution, resolution, 3])

      img_array = img_array.transpose(2, 0, 1)

      input_tensor = img_array.reshape(1, 3, resolution, resolution)

      orig_size_tensor = Numo::Int64[[resolution, resolution]]

      transform_info = { ratio: ratio, pad_w: pad_w, pad_h: pad_h }

      [input_tensor, orig_size_tensor, transform_info]
    end

    def postprocess_outputs_v2(boxes, labels, scores, detections = nil, offset_x:, offset_y:, confidence:,
                               transform_info:)
      keep_mask = scores.gt(confidence)
      keep_indices = keep_mask.where

      if keep_indices.empty?
        detections || {
          xyxy: Numo::SFloat[],
          confidence: Numo::SFloat[],
          class_id: Numo::Int32[]
        }
      else
        scores = scores[keep_indices]
        labels = labels[keep_indices]
        boxes_xyxy = boxes[keep_indices, true]

        ratio = transform_info[:ratio]
        pad_w = transform_info[:pad_w]
        pad_h = transform_info[:pad_h]

        boxes_xyxy[true, 0] = ((boxes_xyxy[true, 0] - pad_w) / ratio) + offset_x
        boxes_xyxy[true, 1] = ((boxes_xyxy[true, 1] - pad_h) / ratio) + offset_y
        boxes_xyxy[true, 2] = ((boxes_xyxy[true, 2] - pad_w) / ratio) + offset_x
        boxes_xyxy[true, 3] = ((boxes_xyxy[true, 3] - pad_h) / ratio) + offset_y

        if detections
          existing_n = detections[:xyxy].shape[0]
          new_n = boxes_xyxy.shape[0]
          total = existing_n + new_n

          xyxy = Numo::SFloat.zeros(total, 4)
          conf = Numo::SFloat.zeros(total)
          cls = Numo::Int32.zeros(total)

          if existing_n.positive?
            xyxy[0...existing_n, true] = detections[:xyxy]
            conf[0...existing_n] = detections[:confidence]
            cls[0...existing_n] = detections[:class_id]
          end

          xyxy[existing_n...(existing_n + new_n), true] = boxes_xyxy
          conf[existing_n...(existing_n + new_n)] = scores
          cls[existing_n...(existing_n + new_n)] = labels

          { xyxy: xyxy, confidence: conf, class_id: cls }
        else
          {
            xyxy: boxes_xyxy,
            confidence: scores,
            class_id: labels
          }
        end
      end
    end

    def build_split_image_regions(image)
      half_h = image.height / 2
      top_h = half_h
      bottom_h = image.height - half_h

      [
        { img: image.crop(0, 0, image.width, top_h), offset_y: 0 },
        { img: image.crop(0, top_h, image.width, bottom_h), offset_y: top_h }
      ]
    end

    def build_fields_from_detections(detections, image)
      detections[:xyxy].shape[0].times.filter_map do |i|
        x1 = detections[:xyxy][i, 0]
        y1 = detections[:xyxy][i, 1]
        x2 = detections[:xyxy][i, 2]
        y2 = detections[:xyxy][i, 3]

        class_id = detections[:class_id][i].to_i

        confidence = detections[:confidence][i]

        x0_norm = x1 / image.width.to_f
        y0_norm = y1 / image.height.to_f
        x1_norm = x2 / image.width.to_f
        y1_norm = y2 / image.height.to_f

        x1_norm = 1 if x1_norm > 1
        y1_norm = 1 if y1_norm > 1

        next if x0_norm < 0 || x0_norm > 1
        next if y0_norm < 0 || y0_norm > 1

        type_name = ID_TO_CLASS[class_id]

        Field.new(
          type: type_name,
          x: x0_norm,
          y: y0_norm,
          w: (x1_norm - x0_norm),
          h: (y1_norm - y0_norm),
          confidence:
        )
      end
    end

    def trim_image_with_padding(image, padding = 0)
      return [image, 0, 0] if padding.nil?

      left, top, trim_width, trim_height = image.find_trim(threshold: 10, background: [255, 255, 255])

      trim_width = [trim_width, image.width - (left * 2)].max

      padded_left = [left - padding, 0].max
      padded_top = [top - padding, 0].max
      padded_right = [left + trim_width + padding, image.width].min
      padded_bottom = [top + trim_height + padding, image.height].min

      width = padded_right - padded_left
      height = padded_bottom - padded_top

      trimmed_image = image.crop(padded_left, padded_top, width, height)

      [trimmed_image, padded_left, padded_top]
    end

    def preprocess_image(image, resolution, aspect_ratio: false)
      scale_x = resolution.to_f / image.width
      scale_y = resolution.to_f / image.height

      if aspect_ratio
        scale = [scale_x, scale_y].min

        new_width = (image.width * scale).round
        new_height = (image.height * scale).round

        resized = image.resize(scale, vscale: scale, kernel: :lanczos3)

        pad_x = ((resolution - new_width) / 2.0).round
        pad_y = ((resolution - new_height) / 2.0).round

        image = resized.embed(pad_x, pad_y, resolution, resolution, background: [255, 255, 255])

        transform_info = { scale_x: scale, scale_y: scale, pad_x: pad_x, pad_y: pad_y }
      else
        image = image.resize(scale_x, vscale: scale_y, kernel: :lanczos3)

        transform_info = { scale_x: scale_x, scale_y: scale_y, pad_x: 0, pad_y: 0 }
      end

      image /= 255.0

      image = (image - MEAN) / STD

      pixel_data = image.write_to_memory

      img_array = Numo::SFloat.from_binary(pixel_data, [resolution, resolution, 3])

      img_array = img_array.transpose(2, 0, 1)

      [img_array.reshape(1, 3, resolution, resolution), transform_info]
    end

    def nms(boxes, scores, iou_threshold = 0.5, containment_threshold = 0.7)
      return Numo::Int32[] if boxes.shape[0].zero?

      x1 = boxes[true, 0]
      y1 = boxes[true, 1]
      x2 = boxes[true, 2]
      y2 = boxes[true, 3]

      areas = (x2 - x1) * (y2 - y1)
      order = scores.sort_index.reverse

      keep = []

      while order.size.positive?
        i = order[0]
        keep << i

        break if order.size == 1

        xx1 = Numo::SFloat.maximum(x1[i], x1[order[1..]])
        yy1 = Numo::SFloat.maximum(y1[i], y1[order[1..]])
        xx2 = Numo::SFloat.minimum(x2[i], x2[order[1..]])
        yy2 = Numo::SFloat.minimum(y2[i], y2[order[1..]])

        w = Numo::SFloat.maximum(0.0, xx2 - xx1)
        h = Numo::SFloat.maximum(0.0, yy2 - yy1)

        intersection = w * h

        iou = intersection / (areas[i] + areas[order[1..]] - intersection)

        other_areas = areas[order[1..]]
        containment = intersection / (other_areas + 1e-6)

        suppress_mask = iou.gt(iou_threshold) | containment.gt(containment_threshold)
        inds = suppress_mask.eq(0).where

        order = order[inds + 1]
      end

      Numo::Int32.cast(keep)
    end

    def postprocess_outputs(boxes, logits, transform_info, detections = nil, confidence: 0.3, temperature: 1,
                            resolution: self.resolution)
      scaled_logits = logits / temperature

      probs = 1.0 / (1.0 + Numo::NMath.exp(-scaled_logits))

      scores = probs.max(axis: 1)
      labels = probs.argmax(axis: 1)

      cx = boxes[true, 0]
      cy = boxes[true, 1]
      w = boxes[true, 2]
      h = boxes[true, 3]

      x1 = cx - (w / 2.0)
      y1 = cy - (h / 2.0)
      x2 = cx + (w / 2.0)
      y2 = cy + (h / 2.0)

      boxes_xyxy = Numo::SFloat.zeros(boxes.shape[0], 4)
      boxes_xyxy[true, 0] = x1
      boxes_xyxy[true, 1] = y1
      boxes_xyxy[true, 2] = x2
      boxes_xyxy[true, 3] = y2

      boxes_xyxy *= resolution

      pad_x = transform_info[:pad_x]
      pad_y = transform_info[:pad_y]
      boxes_xyxy[true, 0] -= pad_x
      boxes_xyxy[true, 1] -= pad_y
      boxes_xyxy[true, 2] -= pad_x
      boxes_xyxy[true, 3] -= pad_y

      scale_x = transform_info[:scale_x]
      scale_y = transform_info[:scale_y]
      boxes_xyxy[true, 0] /= scale_x
      boxes_xyxy[true, 1] /= scale_y
      boxes_xyxy[true, 2] /= scale_x
      boxes_xyxy[true, 3] /= scale_y

      trim_offset_x = transform_info[:trim_offset_x]
      trim_offset_y = transform_info[:trim_offset_y]
      boxes_xyxy[true, 0] += trim_offset_x
      boxes_xyxy[true, 1] += trim_offset_y
      boxes_xyxy[true, 2] += trim_offset_x
      boxes_xyxy[true, 3] += trim_offset_y

      keep_mask = scores.gt(confidence)

      keep_indices = keep_mask.where

      if keep_indices.empty?
        detections || {
          xyxy: Numo::SFloat[],
          confidence: Numo::SFloat[],
          class_id: Numo::Int32[]
        }
      else
        scores = scores[keep_indices]
        labels = labels[keep_indices]
        boxes_xyxy = boxes_xyxy[keep_indices, true]

        if detections
          existing_n = detections[:xyxy].shape[0]
          new_n = boxes_xyxy.shape[0]
          total = existing_n + new_n

          xyxy = Numo::SFloat.zeros(total, 4)
          conf = Numo::SFloat.zeros(total)
          cls = Numo::Int32.zeros(total)

          if existing_n.positive?
            xyxy[0...existing_n, true] = detections[:xyxy]
            conf[0...existing_n] = detections[:confidence]
            cls[0...existing_n] = detections[:class_id]
          end

          xyxy[existing_n...(existing_n + new_n), true] = boxes_xyxy
          conf[existing_n...(existing_n + new_n)] = scores
          cls[existing_n...(existing_n + new_n)] = Numo::Int32.cast(labels)

          { xyxy: xyxy, confidence: conf, class_id: cls }
        else
          {
            xyxy: boxes_xyxy,
            confidence: scores,
            class_id: Numo::Int32.cast(labels)
          }
        end
      end
    end

    def apply_nms(detections, threshold = 0.5)
      return detections if detections[:xyxy].shape[0].zero?

      keep_indices = nms(detections[:xyxy], detections[:confidence], threshold)

      {
        xyxy: detections[:xyxy][keep_indices, true],
        confidence: detections[:confidence][keep_indices],
        class_id: detections[:class_id][keep_indices]
      }
    end

    def model
      @model ||= OnnxRuntime::Model.new(
        MODEL_PATH.to_s,
        inter_op_num_threads: CPU_THREADS,
        intra_op_num_threads: CPU_THREADS,
        enable_mem_pattern: false,
        enable_cpu_mem_arena: false,
        providers: ['CPUExecutionProvider']
      )
    end

    def resolution
      @resolution ||= model.inputs.find { |i| INPUT_NAMES.include?(i[:name]) }.dig(:shape, 2)
    end

    def model_v2?
      @model_v2 ||= model.inputs.pluck(:name).include?('orig_target_sizes')
    end
    # rubocop:enable Metrics
  end
end
