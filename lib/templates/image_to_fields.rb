# frozen_string_literal: true

module Templates
  module ImageToFields
    module_function

    Field = Struct.new(:type, :x, :y, :w, :h, :confidence, keyword_init: true)

    MODEL_PATH = Rails.root.join('tmp/model_704_int8.onnx')

    RESOLUTION = 704

    ID_TO_CLASS = %w[text checkbox].freeze

    MEAN = [0.485, 0.456, 0.406].freeze
    STD = [0.229, 0.224, 0.225].freeze

    CPU_THREADS = Etc.nprocessors

    # rubocop:disable Metrics
    def call(image, confidence: 0.3, nms: 0.1, temperature: 1,
             split_page: false, aspect_ratio: true, padding: nil)
      base_image = image.extract_band(0, n: 3)

      trimmed_base, base_offset_x, base_offset_y = trim_image_with_padding(base_image, padding)

      if split_page && image.height > image.width
        half_h = trimmed_base.height / 2
        top_h = half_h
        bottom_h = trimmed_base.height - half_h

        regions = [
          { img: trimmed_base.crop(0, 0, trimmed_base.width, top_h), offset_y: 0 },
          { img: trimmed_base.crop(0, top_h, trimmed_base.width, bottom_h), offset_y: top_h }
        ]

        detections = { xyxy: Numo::SFloat[], confidence: Numo::SFloat[], class_id: Numo::Int32[] }

        detections = regions.reduce(detections) do |acc, r|
          next detections if r[:img].height <= 0 || r[:img].width <= 0

          input_tensor, transform_info = preprocess_image(r[:img], RESOLUTION, aspect_ratio:)

          transform_info[:trim_offset_x] = base_offset_x
          transform_info[:trim_offset_y] = base_offset_y + r[:offset_y]

          outputs = model.predict({ 'input' => input_tensor })

          postprocess_outputs(outputs, transform_info, acc, confidence:, temperature:)
        end
      else
        input_tensor, transform_info = preprocess_image(trimmed_base, RESOLUTION, aspect_ratio:)

        transform_info[:trim_offset_x] = base_offset_x
        transform_info[:trim_offset_y] = base_offset_y

        outputs = model.predict({ 'input' => input_tensor })

        detections = postprocess_outputs(outputs, transform_info, confidence:, temperature:)
      end

      detections = apply_nms(detections, nms)

      fields = Array.new(detections[:xyxy].shape[0]) do |i|
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

      sort_fields(fields, y_threshold: 10.0 / image.height)
    end

    def trim_image_with_padding(image, padding = 0)
      return [image, 0, 0] if padding.nil?

      left, top, trim_width, trim_height = image.find_trim(threshold: 10, background: [255, 255, 255])

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

    def nms(boxes, scores, iou_threshold = 0.5)
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

        inds = iou.le(iou_threshold).where

        order = order[inds + 1]
      end

      Numo::Int32.cast(keep)
    end

    def postprocess_outputs(outputs, transform_info, detections = nil, confidence: 0.3, temperature: 1)
      boxes = Numo::SFloat.cast(outputs['dets'])
      logits = Numo::SFloat.cast(outputs['labels'])

      boxes = boxes[0, true, true] # [300, 4]
      logits = logits[0, true, true] # [300, num_classes]

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

      boxes_xyxy *= RESOLUTION

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

    def sort_fields(fields, y_threshold: 0.01)
      sorted_fields = fields.sort { |a, b| a.y == b.y ? a.x <=> b.x : a.y <=> b.y }

      lines = []
      current_line = []

      sorted_fields.each do |field|
        if current_line.blank? || (field.y - current_line.first.y).abs < y_threshold
          current_line << field
        else
          lines << current_line.sort_by(&:x)

          current_line = [field]
        end
      end

      lines << current_line.sort_by(&:x) if current_line.present?

      lines.flatten
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
    # rubocop:enable Metrics
  end
end
