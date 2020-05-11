# frozen_string_literal: true

module Link
  class WebServer
    module Config

################################################################################

      def self.registered(app)

        app.get "/config" do
          haml :config
        end

      end

################################################################################

    end
  end
end
