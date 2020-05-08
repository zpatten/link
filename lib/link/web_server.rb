# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/custom_logger'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'sinatra-websocket'
require 'thin'

require 'link/web_server/config'
require 'link/web_server/servers'

module Link
  class WebServer < Sinatra::Base
    helpers Sinatra::CustomLogger
    register Sinatra::RespondWith

    register Link::WebServer::Config
    register Link::WebServer::Servers

    configure do
      enable :logging, :threaded
      disable :traps

      set :bind, '0.0.0.0'
      set :haml, format: :html5
      set :logger, logger
      set :port, 4242
      set :public_folder, File.join(Link::LINK_ROOT, "web", "static")
      set :server, :thin
      set :server_settings, timeout: (10 * 60)
      set :views, File.join(Link::LINK_ROOT, "web", "views")

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
