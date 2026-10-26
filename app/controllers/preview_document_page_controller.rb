# frozen_string_literal: true

class PreviewDocumentPageController < ActionController::API
  include ActiveStorage::SetCurrent

  FORMAT = Templates::ProcessDocument::FORMAT

  TMPFILE_PREFIX = 'attachment-'
  TMPFILE_TTL = 5.minutes
  TMPFILE_MAX_TOTAL_SIZE = Docuseal.multitenant? ? 400.megabytes : 1.gigabyte

  def show
    result_data =
      ApplicationRecord.signed_id_verifier.verified(params[:signed_key], purpose: :attachment)

    attachment =
      if result_data.is_a?(Array) && result_data.compact_blank.size == 2
        attachment_id, attachment_uuid = result_data

        ActiveStorage::Attachment.find_by(id: attachment_id, uuid: attachment_uuid)
      elsif result_data
        ActiveStorage::Attachment.find_by(uuid: result_data)
      end

    return head :not_found unless attachment

    @template = attachment.record

    preview_image =
      attachment.preview_images.joins(:blob)
                .find_by(blob: { filename: ["#{params[:id].to_i}.png", "#{params[:id].to_i}.jpg"] })

    if preview_image
      return redirect_to preview_image.url(time: ActiveStorage::Attachment.service_url_time),
                         allow_other_host: true
    end

    preview_image =
      open_attachment_io(attachment) do |io|
        Templates::ProcessDocument.generate_pdf_preview_from_io(attachment, io, params[:id].to_i)
      end

    redirect_to preview_image.url(time: ActiveStorage::Attachment.service_url_time), allow_other_host: true
  end

  def open_attachment_io(attachment, &)
    return File.open(ActiveStorage::Blob.service.path_for(attachment.key), 'rb', &) if attachment.service.name == :disk

    file_name = "#{TMPFILE_PREFIX}#{Digest::SHA1.hexdigest("#{attachment.id}-#{attachment.uuid}")}"

    file_path = File.join(Dir.tmpdir, file_name)

    File.open(file_path, File::RDWR | File::CREAT, 0o644) do |file|
      file.flock(File::LOCK_EX)

      # rubocop:disable Style/ZeroLengthPredicate
      if file.size.zero?
        cleanup_stale_tempfiles

        file.binmode

        file.write(attachment.download)
      else
        FileUtils.touch(file_path)
      end
      # rubocop:enable Style/ZeroLengthPredicate

      file.flock(File::LOCK_UN)

      yield file
    end
  end

  def cleanup_stale_tempfiles
    entries =
      Dir.glob(File.join(Dir.tmpdir, "#{TMPFILE_PREFIX}*")).filter_map do |path|
        stat = File.stat(path)

        [path, stat.mtime, stat.size]
      rescue Errno::ENOENT
        nil
      end

    total_size = entries.sum(&:last)
    stale_time = TMPFILE_TTL.ago

    entries.sort_by(&:second).each do |path, mtime, size|
      break if mtime > stale_time && total_size <= TMPFILE_MAX_TOTAL_SIZE

      File.unlink(path)

      total_size -= size
    rescue Errno::ENOENT
      nil
    end
  end
end
