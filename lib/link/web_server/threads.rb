# frozen_string_literal: true

module Link
  class WebServer
    module Threads

################################################################################

      def self.registered(app)

        app.get "/threads" do
          @pool    = Concurrent.global_io_executor
          @threads = Thread.list.sort_by { |t| t.name || '' }
          haml :threads
        end

      end

################################################################################

    end
  end
end
