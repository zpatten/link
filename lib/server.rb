# frozen_string_literal: true

require_relative 'server/chat'
require_relative 'server/id'
require_relative 'server/list'
require_relative 'server/logistics'
require_relative 'server/ping'
require_relative 'server/rcon'
require_relative 'server/research'
require_relative 'server/signals'

class Server

################################################################################

  include Server::Chat
  include Server::ID
  include Server::List
  include Server::Logistics
  include Server::Ping
  include Server::Research
  include Server::Signals

################################################################################

  attr_reader :child_pid
  attr_reader :client_password
  attr_reader :client_port
  attr_reader :details
  attr_reader :factorio_port
  attr_reader :host
  attr_reader :id
  attr_reader :name
  attr_reader :network_id
  attr_reader :pinged_at
  attr_reader :research
  attr_reader :rtt

  attr_reader :cancellation
  attr_reader :pool
  attr_reader :watch

  RECV_MAX_LEN = 64 * 1024

################################################################################

  def initialize(name, details)
    @name              = name.dup
    @id                = Zlib::crc32(@name.to_s)
    @network_id        = [@id].pack("L").unpack("l").first
    @pinged_at         = Time.now.to_f
    @rtt               = 0
    @watch             = false

    @details           = details
    @active            = details['active']
    @chats             = details['chats']
    @client_password   = details['client_password']
    @client_port       = details['client_port']
    @command_whitelist = details['command_whitelist']
    @commands          = details['commands']
    @factorio_port     = details['factorio_port']
    @host              = details['host']
    @research          = details['research']

    @rx_signals_initalized = false
    @tx_signals_initalized = false
  end

################################################################################

  def update_websocket
    ::WebServer.settings.server_sockets.each do |s|
      s.send({
        name: @name,
        connected: connected?,
        authenticated: authenticated?,
        available: available?,
        container: container_alive?,
        responsive: responsive?,
        rtt: @rtt.nil? ? '-' : "#{@rtt} ms"
      }.to_json)
    end
  end

  def update_rtt(value)
    @pinged_at = Time.now.to_f
    @rtt       = value
    # update_websocket
    @rtt
  end

################################################################################

  def host_tag
    "#{@name}@#{@host}:#{@client_port}"
  end

  def log_tag(*tags)
    [@name, tags].flatten.compact.join('.').upcase
  end

################################################################################

  def method_missing(method_name, *method_args, &block)
    @details[method_name.to_s]
  end

################################################################################

  def to_h
    { @name => @details }
  end

  def path
    File.expand_path(File.join(LINK_ROOT, 'servers', @name))
  end

  def config_path
    File.join(self.path, 'config')
  end

  def mods_path
    File.join(self.path, 'mods')
  end

  def saves_path
    File.join(self.path, 'saves')
  end

  def save_file
    File.join(self.saves_path, "save.zip")
  end

  def latest_save_file
    save_files = Dir.glob(File.join(self.saves_path, '*.zip'), File::FNM_CASEFOLD)
    save_files.reject! { |save_file| save_file =~ /tmp\.zip$/ }
    save_files.sort! { |a, b| File.mtime(a) <=> File.mtime(b) }
    save_files.last
  end

################################################################################

  def backup(timestamp: false)
    return false if container_dead? || unresponsive?
    if File.exist?(self.save_file)
      begin
        FileUtils.mkdir_p(Servers.factorio_saves)
      rescue Errno::ENOENT
      end

      filename = if timestamp
        "#{@name}-#{Time.now.to_i}.zip"
      else
        "#{@name}.zip"
      end
      backup_save_file = File.join(Servers.factorio_saves, filename)
      latest_save_file = self.latest_save_file
      FileUtils.cp_r(latest_save_file, backup_save_file)
      LinkLogger.info(log_tag(:backup)) { "Backed up #{latest_save_file.inspect} to #{backup_save_file.inspect}" }
    end

    rcon_command %(/server-save)

    true
  end

################################################################################

  def start!(container: true)
    LinkLogger.info(log_tag) { "Start Server (container: #{container.ai})" }

    start_container! if container
    start_pool! unless @pool and @pool.running?
    start_rcon!
    start_threads!

    # sleep 1 while unavailable?

    @watch = true

    true
  end

  def stop!(container: true)
    LinkLogger.info(log_tag) { "Stop Server (container: #{container.ai})" }

    @watch = false

    stop_threads!
    sleep 3
    stop_rcon!
    stop_pool!
    stop_container! if container

    # sleep 1 while available?

    true
  end

  def restart!(container: true)
    LinkLogger.info(log_tag) { "Restart Server (container: #{container.ai})" }

    stop!(container: container)
    sleep 3
    start!(container: container)

    true
  end

################################################################################

  def start_pool!
    raise "Existing thread pool is still running!" if @pool && @pool.running?
    LinkLogger.info(log_tag(:pool)) { "Starting Thread Pool" }
    # @pool = Concurrent::ImmediateExecutor.new
    @pool = Concurrent::CachedThreadPool.new(
      name: @name.downcase,
      auto_terminate: true,
      min_threads: [2, (Concurrent.processor_count * 0.25).floor].max,
      max_threads: [2, Concurrent.processor_count].max,
      max_queue: [2, Concurrent.processor_count * 5].max,
      fallback_policy: :abort
    )
    @cancellation, @origin = Concurrent::Cancellation.new

    true
  end

  def stop_pool!
    LinkLogger.info(log_tag(:pool)) { "Thread Pool Shutting Down" }
    @pool.shutdown
    LinkLogger.info(log_tag(:pool)) { "Waiting for Thread Pool Termination" }
    @pool.wait_for_termination
    LinkLogger.info(log_tag(:pool)) { "Thread Pool Shutdown Complete" }

    true
  end

################################################################################

  def start_threads!
    sleep 1 until available?

    start_thread_ping
    start_thread_id
    start_thread_research
    start_thread_chat
    start_thread_logistics
    start_thread_server_list
    start_thread_signals

    true
  end

  def stop_threads!
    @origin.resolved? or @origin.resolve if @origin

    true
  end

################################################################################

  def start_container!
    return true if container_alive?

    FileUtils.cp_r(Servers.factorio_mods, self.path)

    run_command(@name,
      %(/usr/bin/env),
      %(chcon),
      %(-Rt),
      %(svirt_sandbox_file_t),
      self.path
    )

    run_command(@name,
      %(docker run),
      %(--rm),
      %(--detach),
      %(--name="#{@name}"),
      %(--network=host),
      %(-e FACTORIO_PORT="#{self.factorio_port}"),
      %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}"),
      %(-e FACTORIO_RCON_PORT="#{self.client_port}"),
      %(-e PUID="$(id -u)"),
      %(-e PGID="$(id -g)"),
      %(-e DEBUG=true),
      %(--volume=#{self.path}:/factorio),
      Config.factorio_docker_image
    )

    true
  end

  def stop_container!
    return true if container_dead?

    run_command(@name,
      %(docker stop),
      @name
    )

    true
  end

  def container_alive?
    key = [@name, 'container-alive'].join('-')
    MemoryCache.fetch(key, expires_in: 10) do
      output = run_command(@name,
        %(docker inspect),
        %(-f '{{.State.Running}}'),
        @name
      )
      (output == 'true')
    end
  end

  def container_dead?
    !container_alive?
  end

################################################################################

  def start_rcon!
    sleep 1 until container_alive?
    @pinged_at = Time.now.to_f

    @rcon = RConPool.new(server: self)
    @rcon.start!

    true
  end

  def stop_rcon!
    @rcon and @rcon.stop!

    @pinged_at = 0
    @rtt       = 0

    true
  end

################################################################################

  def unresponsive?
    ((@pinged_at + PING_TIMEOUT) < Time.now.to_f)
  end

  def responsive?
    !unresponsive?
  end

################################################################################

  def connected?
    @rcon && @rcon.connected?
  end

  def disconnected?
    !connected?
  end

################################################################################

  def authenticated?
    @rcon && @rcon.authenticated?
  end

  def unauthenticated?
    !authenticated?
  end

################################################################################

  def available?
    @rcon && @rcon.available?
  end

  def unavailable?
    !available?
  end

################################################################################

  def rcon_command_nonblock(command)
    return false if unavailable?

    @rcon.command_nonblock(command)

    true
  end

  def rcon_command(command)
    return nil if unavailable?

    @rcon.command(command)
  end

################################################################################

  def rcon_handler(what:, command:, &block)
    payload = self.rcon_command(command)
    unless payload.nil? || payload.empty?
      data = JSON.parse(payload)
      unless data.nil? || data.empty?
        block.call(data)
      # else
      #   LinkLogger.warn(log_tag(:rcon)) { "Missing Payload Data! #{command.ai}" }
      end
    else
      LinkLogger.warn(log_tag(:rcon, what)) { "Missing Payload!" }
    end
  end

end
