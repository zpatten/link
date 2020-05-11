# frozen_string_literal: true

module Link
  class WebServer
    module Servers

################################################################################

      def self.registered(app)
        app.set :server_sockets, []

        app.get "/servers" do
          if !request.websocket?
            @servers = Link::Factorio::Servers.all.sort_by { |server| server.name }
            haml :servers
          else
            logger.info { 'websocket request' }
            request.websocket do |ws|

              ws.on :error do |event|
                logger.fatal { "websocket error" }
              end

              ws.on :open do |event|
                logger.info { "websocket open: #{ws.object_id}" }
                settings.server_sockets << ws
              end

              ws.on :close do |event|
                logger.info { "websocket close: #{ws.object_id}, #{event.code}, #{event.reason}" }
                settings.server_sockets.delete(ws)
              end

            end
          end
        end

        app.get '/servers/start/:name' do
          Link::Factorio::Servers.find_by_name(params[:name]).start!
          redirect '/servers'
        end

        app.get '/servers/stop/:name' do
          Link::Factorio::Servers.find_by_name(params[:name]).stop!
          redirect '/servers'
        end

        app.get '/servers/restart/:name' do
          Link::Factorio::Servers.find_by_name(params[:name]).restart!
          redirect '/servers'
        end

        app.get '/servers/restart-all' do
          Link::Factorio::Servers.restart!
          redirect '/servers'
        end

        app.get '/servers/start-all' do
          Link::Factorio::Servers.start!
          redirect '/servers'
        end

        app.get '/servers/stop-all' do
          Link::Factorio::Servers.stop!
          redirect '/servers'
        end

        app.get "/servers/create" do
          haml :"servers/create"
        end

        app.post "/servers/create" do
          Link::Factorio::Servers.create!(params)
          redirect "/servers/start/#{params[:name]}"
        end

        app.get "/servers/delete/:name" do
          Link::Factorio::Servers.delete!(params)
          redirect '/servers'
        end

      end

################################################################################

    end
  end
end


