require 'fileutils'
cache_path = Rails.root.join('tmp','cache',Rails.env)
FileUtils.mkdir_p(cache_path)

Calagator::Application.config.cache_store = :file_store, cache_path
