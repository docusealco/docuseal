# frozen_string_literal: true

require "bootsnap"
require "rake/clean"

# Typically, should have been set up prior to requiring rake integration.
# But allow for a streamlined ::default_setup
require "bootsnap/setup" if Bootsnap.cache_dir.nil?

if Bootsnap.cache_dir
  CLEAN.include Bootsnap.cache_dir
else
  abort "Bootsnap must be set-up prior to rake integration"
end
