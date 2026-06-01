# frozen_string_literal: true

require "active_record"
require "active_support"
require "rake"

module AnnotateRb
end

require_relative "annotate_rb/helper"
require_relative "annotate_rb/core"
require_relative "annotate_rb/commands"
require_relative "annotate_rb/parser"
require_relative "annotate_rb/runner"
require_relative "annotate_rb/route_annotator"
require_relative "annotate_rb/model_annotator"
require_relative "annotate_rb/options"
require_relative "annotate_rb/eager_loader"
require_relative "annotate_rb/rake_bootstrapper"
require_relative "annotate_rb/config_finder"
require_relative "annotate_rb/config_loader"
require_relative "annotate_rb/config_generator"
