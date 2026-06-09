require_relative "boot"

require "net/http"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module RailsKafkaDemo
  class Application < Rails::Application
    config.load_defaults 7.2
    config.api_only = true
    config.eager_load_paths << Rails.root.join("app/kafka")

    config.generators do |g|
      g.test_framework :rspec
      g.factory_bot true
    end
  end
end
