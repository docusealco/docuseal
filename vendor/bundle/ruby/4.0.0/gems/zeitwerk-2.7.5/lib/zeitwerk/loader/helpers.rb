# frozen_string_literal: true

module Zeitwerk::Loader::Helpers
  CNAME_VALIDATOR = Module.new #: Module
  private_constant :CNAME_VALIDATOR

  #: (String, String) -> Symbol ! Zeitwerk::NameError
  private def cname_for(basename, abspath)
    cname = inflector.camelize(basename, abspath)

    unless cname.is_a?(String)
      raise TypeError, "#{inflector.class}#camelize must return a String, received #{cname.inspect}"
    end

    if cname.include?("::")
      raise Zeitwerk::NameError.new(<<~MESSAGE, cname)
        wrong constant name #{cname} inferred by #{inflector.class} from

          #{abspath}

        #{inflector.class}#camelize should return a simple constant name without "::"
      MESSAGE
    end

    begin
      CNAME_VALIDATOR.const_defined?(cname, false)
    rescue ::NameError => error
      path_type = @fs.rb_extension?(abspath) ? "file" : "directory"

      raise Zeitwerk::NameError.new(<<~MESSAGE, error.name)
        #{error.message} inferred by #{inflector.class} from #{path_type}

          #{abspath}

        Possible ways to address this:

          * Tell Zeitwerk to ignore this particular #{path_type}.
          * Tell Zeitwerk to ignore one of its parent directories.
          * Rename the #{path_type} to comply with the naming conventions.
          * Modify the inflector to handle this case.
      MESSAGE
    end

    cname.to_sym
  end
end
