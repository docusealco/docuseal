module Brakeman
  class FileTypeDetector < BaseProcessor
    def initialize
      super(nil)
      reset
    end

    def detect_type(file)
      reset
      process(file.ast)

      if @file_type.nil?
        @file_type = guess_from_path(file.path.relative)
      end

      @file_type || :lib
    end

    MODEL_CLASSES = [
      :'ActiveRecord::Base',
      :ApplicationRecord
    ]

    def process_class exp
      name = class_name(exp.class_name)
      parent = class_name(exp.parent_name)

      if name.match(/Controller$/)
        @file_type = :controller
        return exp
      elsif MODEL_CLASSES.include? parent
        @file_type = :model
        return exp
      end

      super
    end

    def guess_from_path path
      case
      when path.include?('app/models')
        :model
      when path.include?('app/controllers')
        :controller
      when path.include?('config/initializers')
        :initializer
      when path.include?('lib/')
        :lib
      when path.match?(%r{config/environments/(?!production\.rb)$})
        :skip
      when path.match?(%r{environments/production\.rb$})
        :skip
      when path.match?(%r{application\.rb$})
        :skip
      when path.match?(%r{config/routes\.rb$})
        :skip
      end
    end

    private

    def reset
      @file_type = nil
    end
  end
end
