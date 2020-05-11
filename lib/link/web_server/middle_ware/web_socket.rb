require 'faye/websocket'

module Link
  class WebServer
    module MiddleWare
      class WebSocket
        KEEPALIVE_TIME = 15

        def initialize(app)
          @app     = app
          @clients = Array.new
        end

        def call(env)
          if Faye::WebSocket.websocket?(env)
            ws = Faye::WebSocket.new(env, nil, { ping: KEEPALIVE_TIME })

            ws.on :open do |event|
              p [:open, ws.object_id]
              @clients << ws
            end

            ws.on :message do |event|
              p [:message, event.data]
              @clients.each {|client| client.send(event.data) }
            end

            ws.on :close do |event|
              p [:close, ws.object_id, event.code, event.reason]
              @clients.delete(ws)
              ws = nil
            end

            ws.rack_response
          else
            @app.call(env)
          end
        end

      end
    end
  end
end

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      ws.send(event.data)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    [200, { 'Content-Type' => 'text/plain' }, ['Hello']]
  end
end
