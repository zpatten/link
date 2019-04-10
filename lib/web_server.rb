require 'thin'
require 'sinatra'
require 'sinatra/custom_logger'
require 'sinatra/respond_with'
require 'sinatra/json'
require 'sinatra-websocket'

class WebServer < Sinatra::Application
  enable :logging
  set :logger, $logger
  set :server, :thin
  set :port, 4242
  # set :bind, "127.0.0.1"
  set :sockets, []
  set :storage_sockets, []

  set :views, File.join(Dir.pwd, "web", "views")
  set :public_folder, File.join(Dir.pwd, "web", "static")

  set :haml, :format => :html5

  respond_to :html, :json

  get "/" do
    respond_to do |f|
      f.json { :index }
      f.html { haml :index }
    end
    # haml :index
  end

  get "/storage" do
    if !request.websocket?
      @storage = Storage.clone
      @total_count = @storage.values.sum
      @statistics = Storage.statistics
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
    haml :threads
  end

  get "/servers" do
    haml :servers
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
          ws.send("Hello World!")
          settings.sockets << ws
        end

        # ws.onmessage do |msg|
        #   EM.next_tick { settings.sockets.each { |s| s.send(msg) } }
        # end

        ws.onclose do
          settings.sockets.delete(ws)
        end

      end
    end
  end

  # get "/log", provides: 'text/event-stream' do
  #   stream do |out|
  #     loop do
  #       unless out.closed?
  #         message = $log_queue.pop
  #         out << message
  #       end
  #       break if out.closed?
  #     end
  #   end
  # end

  ThreadPool.thread("sinatra") do
    run!
    exit
  end
end
