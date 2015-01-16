require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'sprockets/railtie'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Calagator
  class Application < Rails::Application
    config.autoload_paths += %W( #{config.root}/lib )

    # Activate observers that should always be running
    # config.active_record.observers = :cacher, :garbage_collector
    config.active_record.observers = :cache_observer

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.i18n.enforce_available_locales = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.assets.precompile += [
      "leaflet.js",
      "leaflet_google_layer.js",
      "errors.css"
    ]

    require "secrets_reader"
    ::SECRETS = SecretsReader.read

    require "theme_reader"
    ::THEME_NAME = ThemeReader.read

    require "settings_reader"
    ::SETTINGS = SettingsReader.read(Rails.root.join('themes',THEME_NAME,'settings.yml'))

    config.time_zone = SETTINGS.timezone || 'Pacific Time (US & Canada)'
  end
end
