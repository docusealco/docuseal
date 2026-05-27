namespace :shakapacker do
  desc "Verifies if Shakapacker is installed"
  task verify_install: [:verify_config, :check_node, :check_manager, :check_binstubs]
end
