# frozen_string_literal: true

require 'cancan/version'
require 'cancan/config'
require 'cancan/parameter_validators'
require 'cancan/ability'
require 'cancan/rule'
require 'cancan/controller_resource'
require 'cancan/controller_additions'
require 'cancan/model_additions'
require 'cancan/exceptions'

require 'cancan/model_adapters/abstract_adapter'
require 'cancan/model_adapters/default_adapter'
require 'cancan/rules_compressor'

if defined? ActiveRecord
  require 'cancan/model_adapters/conditions_extractor'
  require 'cancan/model_adapters/conditions_normalizer'
  require 'cancan/model_adapters/sti_normalizer'
  require 'cancan/model_adapters/active_record_adapter'
  require 'cancan/model_adapters/active_record_4_adapter'
  require 'cancan/model_adapters/active_record_5_adapter'
  require 'cancan/model_adapters/strategies/base'
  require 'cancan/model_adapters/strategies/joined_alias_each_rule_as_exists_subquery'
  require 'cancan/model_adapters/strategies/joined_alias_exists_subquery'
  require 'cancan/model_adapters/strategies/left_join'
  require 'cancan/model_adapters/strategies/subquery'
end
