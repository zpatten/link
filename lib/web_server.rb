# frozen_string_literal: true

require 'sinatra'
require 'sinatra-websocket'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'thin'
require 'haml'

class WebServer < Sinatra::Application
  set :server, :thin
  set :port, 4242
  set :bind, "0.0.0.0"
  set :sockets, []
  set :threaded, true

  set :storage_sockets, []
  set :server_sockets, []

  set :server_settings, :timeout => (10 * 60)

  set :views, File.join(LINK_ROOT, "web", "views")
  set :public_folder, File.join(LINK_ROOT, "web", "static")

  set :haml, :format => :html5

  respond_to :html, :json

  configure do
    use ::Rack::CommonLogger, $logger
  end

  # before do
  #   env['rack.errors'] = $logger
  # end

  get "/" do
    respond_to do |f|
      f.json { :index }
      f.html { haml :index }
    end
    # haml :index
  end

  get "/storage" do
    if !request.websocket?
      @storage = Storage.copy
      @total_count = @storage.values.sum
      haml :storage
    else
      request.websocket do |ws|
        ws.onopen do
          settings.storage_sockets << ws
        end

        ws.onclose do
          settings.storage_sockets.delete(ws)
        end
      end
    end
  end

  get "/signals" do
    haml :signals, locals: { signals: Signals }
  end

  get "/threads" do
    @threads = Thread.list.collect do |t|
      OpenStruct.new(
        pid: Process.pid,
        name: t.name,
        status: t.status,
        priority: t.priority
        # started_at: t[:started_at] || Time.now.to_i
      )
    end
    @threads.compact!
    @threads = @threads.sort_by { |t| t.name || '-' }
    haml :threads
  end

  get "/servers" do
    if !request.websocket?
      haml :servers
    else
      request.websocket do |ws|
        ws.onopen do
          settings.server_sockets << ws
        end

        ws.onclose do
          settings.server_sockets.delete(ws)
        end
      end
    end
  end

  get '/servers/start/:name' do
    Servers.find_by_name(params[:name]).start!(container: true)
    redirect '/servers'
  end

  get '/servers/stop/:name' do
    Servers.find_by_name(params[:name]).stop!(container: true)
    redirect '/servers'
  end

  get '/servers/restart/:name' do
    Servers.find_by_name(params[:name]).restart!(container: true)
    redirect '/servers'
  end

  get '/servers/restart-all' do
    Servers.restart!(container: true)
    redirect '/servers'
  end

  get '/servers/start-all' do
    Servers.start!(container: true)
    redirect '/servers'
  end

  get '/servers/stop-all' do
    Servers.stop!(container: true)
    redirect '/servers'
  end

  get "/servers/create" do
    haml :"servers/create"
  end

  post "/servers/create" do
    Servers.create!(params)
    redirect "/servers/start/#{params[:name]}"
  end

  get "/servers/delete/:name" do
    Servers.delete!(params)
    redirect '/servers'
  end

  get "/config" do
    haml :config
  end

  get "/log" do
    if !request.websocket?
      haml :log
    else
      request.websocket do |ws|
        ws.onopen do
          settings.sockets << ws
        end

        ws.onclose do
          settings.sockets.delete(ws)
        end
      end
    end
  end

end
