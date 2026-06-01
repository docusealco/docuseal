# frozen_string_literal: true

module Zeitwerk::ConstAdded # :nodoc:
  #: (Symbol) -> void
  def const_added(cname)
    if loader = Zeitwerk::Registry.explicit_namespaces.loader_for(self, cname)
      namespace = const_get(cname, false)
      cref = Zeitwerk::Cref.new(self, cname)

      unless namespace.is_a?(Module)
        raise Zeitwerk::Error, "#{cref} is expected to be a namespace, should be a class or module (got #{namespace.class})"
      end

      loader.__on_namespace_loaded(cref, namespace)
    end
    super
  end

  Module.prepend(self)
end
