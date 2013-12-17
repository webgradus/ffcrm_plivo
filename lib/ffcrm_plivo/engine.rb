module FfcrmPlivo
  class Engine < ::Rails::Engine
      config.to_prepare do
          require 'ffcrm_plivo/plivo_view_hooks'

          #loads application's model / class decorators
          Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
            Rails.configuration.cache_classes ? require(c) : load(c)
          end

      end
  end
end
