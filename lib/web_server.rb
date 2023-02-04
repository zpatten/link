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
    redirect 'servers/start/#{params[:name]}'
  end

  get '/servers/delete/:name' do
    Servers.delete!(params)
    redirect '/servers'
  end

  get '/config' do
    haml :config
  end

  get '/mods' do
    mod_files = Dir.glob(File.join(Servers.factorio_mods, '*.zip'), File::FNM_CASEFOLD)
    @mods = mod_files.collect do |mod_file|
      {
        name: File.basename(mod_file).split('_')[0..-2].join('_'),
        file: File.basename(mod_file),
        size: File.size(mod_file),
        time: File.mtime(mod_file)
      }
    end.sort_by { |mod_file| mod_file[:file] }
    @mod_names = (%w( base ) + @mods.collect { |m| m[:name] }.uniq).sort_by { |m| m.downcase }
    haml :mods
  end

  post '/mods/enable' do
    ModList.enable(params[:name])
    ModList.save
    redirect '/mods'
  end

  post '/mods/disable' do
    ModList.disable(params[:name])
    ModList.save
    redirect '/mods'
  end

  post '/mods/search' do
    query = {
      query: {
        hide_deprecated: false,
        namelist: params[:name].strip,
        sort_order: 'title',
        sort: 'asc',
        page: params[:page]
      }.delete_if { |k,v| v.nil? || v == '' }
    }
    LinkLogger.info(:http) { "query=#{query.ai}" }
    response         = HTTParty.get("#{Config.factorio_mod_url}/api/mods", query)
    @name            = params[:name]
    @parsed_response = response.parsed_response
    haml 'mods/search'.to_sym
  end

  post '/mods/download' do
    filename = File.join(Servers.factorio_mods, params[:file_name])
    LinkLogger.info(:http) { "Downloading #{filename.ai}" }
    File.open(filename, 'wb') do |file|
      HTTParty.get(Config.factorio_mod_url+params[:download_url], stream_body: true) do |data|
        file.write(data)
      end
    end
    LinkLogger.info(:http) { "Downloaded #{filename.ai} (#{countsize(File.size(filename)).ai})" }
    redirect '/mods'
  end

end
