module FfcrmPlivo
  class Engine < ::Rails::Engine
      config.to_prepare do
          require 'ffcrm_plivo/plivo_view_hooks'

      end
  end
end
