class Shakapacker::Commands
  delegate :config, :compiler, :manifest, :logger, to: :@instance

  def initialize(instance)
    @instance = instance
  end

  # Cleanup old assets in the compile directory. By default it will
  # keep the latest version, 2 backups created within the past hour.
  #
  # Examples
  #
  #   To force only 1 backup to be kept, set count=1 and age=0.
  #
  #   To only keep files created within the last 10 minutes, set count=0 and
  #   age=600.
  #
  def clean(count = 2, age = 3600)
    if config.public_output_path.exist? && config.manifest_path.exist?
      packs
        .map do |paths|
          paths.map { |path| [Time.now - File.mtime(path), path] }
          .sort
          .reject.with_index do |(file_age, _), index|
            file_age < age || index < count
          end
          .map { |_, path| path }
        end
        .flatten
        .compact
        .each do |file|
          if File.file?(file)
            File.delete(file)
            logger.info "Removed #{file}"
          end
        end
    end

    true
  end

  def clobber
    config.public_output_path.rmtree if config.public_output_path.exist?
    config.cache_path.rmtree if config.cache_path.exist?
  end

  def bootstrap
    manifest.refresh
  end

  def compile
    compiler.compile.tap do |success|
      manifest.refresh if success
    end
  end

  private
    def packs
      all_files       = Dir.glob("#{config.public_output_path}/**/*")
      manifest_config = Dir.glob("#{config.manifest_path}*")

      packs = all_files - manifest_config - current_version
      packs.reject { |file| File.directory?(file) }.group_by do |path|
        base, _, ext = File.basename(path).scan(/(.*)(-[\da-f]+)([.\w]+)/).flatten
        "#{File.dirname(path)}/#{base}#{ext}"
      end.values
    end

    def current_version
      packs = manifest.refresh.values.map do |value|
        value = value["src"] if value.is_a?(Hash)
        next unless value.is_a?(String)

        File.join(config.root_path, "public", "#{value}*")
      end.compact

      Dir.glob(packs).uniq
    end
end
