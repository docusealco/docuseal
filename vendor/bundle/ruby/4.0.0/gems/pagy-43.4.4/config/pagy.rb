# frozen_string_literal: true

# Pagy initializer file (43.4.4)
# See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/


############ Global Options ################################################################
# See https://ddnexus.github.io/pagy/toolbox/configuration/options/ for details.
# Add your global options below. They will be applied globally.
# For example:
#
# Pagy::OPTIONS[:limit] = 10               # Limit the items per page
# Pagy::OPTIONS[:client_max_limit] = 100   # The client is allowed to request a limit up to 100
# Pagy::OPTIONS[:jsonapi] = true           # Use JSON:API compliant URLs

Pagy::OPTIONS.freeze


############ JS and CSS Resources ##########################################################
# See https://ddnexus.github.io/pagy/resources/javascript/
# and https://ddnexus.github.io/pagy/resources/stylesheets/ for more resources and details.
# Copy and keep the resource files synced in the app. For example:
#
# if Rails.env.development?
#   Pagy.sync(:javascript, Rails.root.join('app/javascript'), 'pagy.mjs')
#   Pagy.sync(:stylesheet, Rails.root.join('app/stylesheets'), 'pagy.css')
# end
#
# As an alternative, use this config ONLY for apps with an asset pipeline
#
# Rails.application.config.assets.paths << Pagy::ROOT.join(':javascripts')
# Rails.application.config.assets.paths << Pagy::ROOT.join(':stylesheets')


############# Overriding Pagy::I18n Lookup #################################################
# Refer to https://ddnexus.github.io/pagy/resources/i18n/ for details.
# Override the I18n lookup by dropping your custom dictionary in some pagy dir.
# Example for Rails:
#
# Pagy::I18n.pathnames << Rails.root.join('config/locales/pagy')


############# I18n Gem Translation #########################################################
# See https://ddnexus.github.io/pagy/resources/i18n/ for details.
#
# Pagy.translate_with_the_slower_i18n_gem!


############# Calendar Localization for non-en locales ####################################
# See https://ddnexus.github.io/pagy/toolbox/paginators/calendar#localization for details.
# Add your desired locales to the list and uncomment the following line to enable them,
# regardless of whether you use the I18n gem for translations or not, whether with
# Rails or not.
#
# Pagy::Calendar.localize_with_rails_i18n_gem(*your_locales)
