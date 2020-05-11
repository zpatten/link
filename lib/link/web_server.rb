# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/json'
require 'sinatra/respond_with'
# require 'sinatra-websocket'
# require 'thin'
require 'puma'
require 'link/support/sinatra'

module Link
  class WebServer < Sinatra::Base
    # require 'link/web_server/middle_ware/web_socket'
    require 'link/web_server/config'
    require 'link/web_server/servers'
    require 'link/web_server/threads'

    PUBLIC_DIR = File.join(Link::LINK_ROOT, 'lib', 'link', 'web_server', 'public')
    VIEWS_DIR = File.join(Link::LINK_ROOT, 'lib', 'link', 'web_server', 'views')

    helpers Sinatra::CustomLogger
    register Sinatra::RespondWith

    # use Link::WebServer::MiddleWare::WebSocket

    register Link::WebServer::Config
    register Link::WebServer::Servers
    register Link::WebServer::Threads

    configure do
      enable :logging
      disable :traps

      set :bind, '0.0.0.0'
      set :haml, format: :html5
      set :logger, logger
      set :port, 4242
      set :public_folder, PUBLIC_DIR
      # set :server, :thin
      set :server, :puma
      # set :server_settings, timeout: (10 * 60), tag: 'web'
      # set :server_settings, { threaded: false, tag: 'thin' }
      # set :server_settings, Threads: '8:16'
      set :views, VIEWS_DIR

      # class << settings
      #   def server_settings
      #     {
      #       threads: '8:16',
      #       timeout: (10 * 60)
      #     }
      #   end
      # end

      respond_to :html, :json
      use ::Rack::CommonLogger, logger
    end

    before do
      env['rack.errors'] = logger
    end

    get "/" do
      respond_to do |f|
        f.json { :index }
        f.html { haml :index }
      end
    end

  end
end
