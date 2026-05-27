# frozen_string_literal: true

module Zeitwerk::RealModName
  #: UnboundMethod
  UNBOUND_METHOD_MODULE_NAME = Module.instance_method(:name)
  private_constant :UNBOUND_METHOD_MODULE_NAME

  # Returns the real name of the class or module.
  #
  # We need this indirection because the `name` method can be overridden, and
  # because in practice what we really need is the constant paths of modules
  # with a permanent name, not so much what the user considers to be the name of
  # a certain class or module of theirs.
  #
  #: (Module) -> String?
  def real_mod_name(mod)
    UNBOUND_METHOD_MODULE_NAME.bind_call(mod)
  end
end
