# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/respond_with'
require 'sinatra/streaming'
require 'puma'
require 'haml'

class WebServer < Sinatra::Application
  set :bind, '0.0.0.0'
  set :haml, :format => :html5
  set :port, 4242
  set :public_folder, File.join(LINK_ROOT, 'web', 'static')
  set :server, :puma
  set :server_settings, :timeout => (10 * 60)
  set :threaded, true
  set :views, File.join(LINK_ROOT, 'web', 'views')

  respond_to :html, :json

  get '/' do
    respond_to do |f|
      f.json { :index }
      f.html { haml :index }
    end
  end

  get '/storage' do
    @storage = Storage.to_h
    @total_count = @storage.values.sum
    haml :storage
  end

  get '/signals' do
    haml :signals, locals: { signals: Signals }
  end

  get '/threads' do
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

  get '/servers' do
    haml :servers
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

  get '/servers/create' do
    haml 'servers/create'.to_sym
  end

  post '/servers/create' do
    Servers.create!(params)
    redirect "servers/start/#{params[:name]}"
  end

  get '/servers/delete/:name' do
    Servers.delete!(params)
    redirect '/servers'
  end

  get '/config' do
    haml :config
  end

  get '/mods' do
    haml :mods
  end

  post '/mods/enable' do
    Mods.enable(params[:name])
    Mods.save
    redirect '/mods'
  end

  post '/mods/disable' do
    Mods.disable(params[:name])
    Mods.save
    redirect '/mods'
  end

  post '/mods/search' do
    @name            = params[:name]
    @parsed_response = Mods.search(name: params[:name], page: params[:page])
    haml 'mods/search'.to_sym
  end

  post '/mods/download' do
    Mods.download(
      file_name: params[:file_name],
      download_url: params[:download_url],
      released_at: params[:released_at]
    )
    Mods.save
    redirect '/mods'
  end

  post '/mods/delete' do
    Mods.delete(params[:filename])
    Mods.save
    redirect '/mods'
  end

end
