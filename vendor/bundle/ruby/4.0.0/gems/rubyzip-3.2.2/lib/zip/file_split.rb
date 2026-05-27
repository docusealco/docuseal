# frozen_string_literal: true

module Zip
  module FileSplit # :nodoc:
    MAX_SEGMENT_SIZE = 3_221_225_472
    MIN_SEGMENT_SIZE = 65_536
    DATA_BUFFER_SIZE = 8192

    def get_segment_size_for_split(segment_size)
      segment_size.clamp(MIN_SEGMENT_SIZE, MAX_SEGMENT_SIZE)
    end

    def get_partial_zip_file_name(zip_file_name, partial_zip_file_name)
      unless partial_zip_file_name.nil?
        partial_zip_file_name = zip_file_name.sub(
          /#{::File.basename(zip_file_name)}\z/,
          partial_zip_file_name + ::File.extname(zip_file_name)
        )
      end
      partial_zip_file_name ||= zip_file_name
      partial_zip_file_name
    end

    def get_segment_count_for_split(zip_file_size, segment_size)
      (zip_file_size / segment_size).to_i +
        ((zip_file_size % segment_size).zero? ? 0 : 1)
    end

    def put_split_signature(szip_file, segment_size)
      signature_packed = [SPLIT_FILE_SIGNATURE].pack('V')
      szip_file << signature_packed
      segment_size - signature_packed.size
    end

    #
    # TODO: Make the code more understandable
    #
    def save_splited_part(
      zip_file, partial_zip_file_name, zip_file_size,
      szip_file_index, segment_size, segment_count
    )
      ssegment_size  = zip_file_size - zip_file.pos
      ssegment_size  = segment_size if ssegment_size > segment_size
      szip_file_name = "#{partial_zip_file_name}.#{format('%03d', szip_file_index)}"
      ::File.open(szip_file_name, 'wb') do |szip_file|
        if szip_file_index == 1
          ssegment_size = put_split_signature(szip_file, segment_size)
        end
        chunk_bytes = 0
        until ssegment_size == chunk_bytes || zip_file.eof?
          segment_bytes_left = ssegment_size - chunk_bytes
          buffer_size        = [segment_bytes_left, DATA_BUFFER_SIZE].min
          chunk              = zip_file.read(buffer_size)
          chunk_bytes += buffer_size
          szip_file << chunk
          # Info for track splitting
          yield segment_count, szip_file_index, chunk_bytes, ssegment_size if block_given?
        end
      end
    end

    # Splits an archive into parts with segment size
    def split(
      zip_file_name, segment_size: MAX_SEGMENT_SIZE,
      delete_original: true, partial_zip_file_name: nil
    )
      raise Error, "File #{zip_file_name} not found" unless ::File.exist?(zip_file_name)
      raise Errno::ENOENT, zip_file_name unless ::File.readable?(zip_file_name)

      zip_file_size = ::File.size(zip_file_name)
      segment_size  = get_segment_size_for_split(segment_size)
      return if zip_file_size <= segment_size

      segment_count = get_segment_count_for_split(zip_file_size, segment_size)
      ::Zip::File.open(zip_file_name) {} # Check for correct zip structure.
      partial_zip_file_name = get_partial_zip_file_name(zip_file_name, partial_zip_file_name)
      szip_file_index       = 0
      ::File.open(zip_file_name, 'rb') do |zip_file|
        until zip_file.eof?
          szip_file_index += 1
          save_splited_part(
            zip_file, partial_zip_file_name, zip_file_size,
            szip_file_index, segment_size, segment_count
          )
        end
      end
      ::File.delete(zip_file_name) if delete_original
      szip_file_index
    end
  end
end
