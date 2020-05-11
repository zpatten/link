require 'faye/websocket'
module Link
  module Support

################################################################################

    module Sinatra
      module Request

        def websocket?
          env['HTTP_CONNECTION'] && env['HTTP_UPGRADE'] &&
            env['HTTP_CONNECTION'].split(',').map(&:strip).map(&:downcase).include?('upgrade') &&
            env['HTTP_UPGRADE'].downcase == 'websocket'
        end

        def websocket(options={}, &block)
          env['skinny.websocket'] ||= begin
            if ::Faye::WebSocket.websocket?(env)
              ws = ::Faye::WebSocket.new(env, nil, { ping: 15 })
              block.call(ws)
              ws.rack_response
            end
          end
        end

      end
    end

################################################################################

  end
end

defined?(Sinatra) and Sinatra::Request.include(Link::Support::Sinatra::Request)
