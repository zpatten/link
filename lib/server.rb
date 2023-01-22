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

  attr_reader :client_password
  attr_reader :client_port
  attr_reader :details
  attr_reader :factorio_port
  attr_reader :host
  attr_reader :name
  attr_reader :research
  attr_reader :child_pid
  attr_reader :id
  attr_reader :network_id
  attr_reader :pinged_at

  attr_reader :method_proxy
  attr_reader :rcon

  attr_reader :cancellation, :origin

  RECV_MAX_LEN = 64 * 1024

################################################################################

  def initialize(name, details)
    @name                = name.dup
    @id                  = Zlib::crc32(@name.to_s)
    @network_id          = [@id].pack("L").unpack("l").first
    @pinged_at           = 0

    @details             = details
    @active              = details['active']
    @chats               = details['chats']
    @client_password     = details['client_password']
    @client_port         = details['client_port']
    @command_whitelist   = details['command_whitelist']
    @commands            = details['commands']
    @factorio_port       = details['factorio_port']
    @host                = details['host']
    @research            = details['research']

    @rx_signals_initalized = false
    @tx_signals_initalized = false

    # @pinged_at = Time.now.to_f
    @rcon = RCon.new(
      name: @name,
      host: @host,
      port: @client_port,
      password: @client_password
    )

    @parent_pid          = Process.pid
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

  def rtt
    @rtt
  end

  def rtt=(value)
    @pinged_at = Time.now.to_f unless value.nil?
    @rtt       = value
    update_websocket
    @rtt
  end

################################################################################

  def host_tag
    "#{@name}@#{@host}:#{@client_port}"
  end

################################################################################

  def method_missing(method_name, *method_args, &block)
    @details[method_name.to_s]
  end

################################################################################

  def to_h
    { self.name => self.details }
  end

  def path
    File.expand_path(File.join(LINK_ROOT, 'servers', self.name))
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

  def backup(timestamp=false)
    if File.exist?(self.save_file)
      begin
        FileUtils.mkdir_p(Servers.factorio_saves)
      rescue Errno::ENOENT
      end

      filename = if timestamp
        "#{self.name}-#{Time.now.to_i}.zip"
      else
        "#{self.name}.zip"
      end
      backup_save_file = File.join(Servers.factorio_saves, filename)
      latest_save_file = self.latest_save_file
      FileUtils.cp_r(latest_save_file, backup_save_file)
      $logger.debug(:server) { "[#{self.name}] Backed up #{latest_save_file.inspect} to #{backup_save_file.inspect}" }
    end
  end

################################################################################

  def restart!(container=true)
    self.stop!(container)
    sleep 3
    self.start!(container)
  end

  def start!(container=true)
    Timeout.timeout(60) do
      self.start_container! if container
      self.start_rcon!
      self.start_threads!

      sleep 1 while self.unavailable?
    end
  end

  def stop!(container=true)
    Timeout.timeout(60) do
      self.stop_threads!
      self.stop_rcon!
      self.stop_container! if container

      sleep 1 while self.available?
    end
  end

################################################################################

  def start_threads!
    @cancellation, @origin = Concurrent::Cancellation.new

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
    self.origin and self.origin.resolve
    true
  end

################################################################################

  def start_container!
    return true if container_alive?

    FileUtils.cp_r(Servers.factorio_mods, self.path)

    run_command(:server, self.name,
      %(/usr/bin/env),
      %(chcon),
      %(-Rt),
      %(svirt_sandbox_file_t),
      self.path
    )

    run_command(:server, self.name,
      %(docker run),
      %(--rm),
      %(--detach),
      %(--name="#{self.name}"),
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

      # %(--volume=#{self.config_path}:/opt/factorio/config),
      # %(--volume=#{self.mods_path}:/opt/factorio/mods),
      # %(--volume=#{self.saves_path}:/opt/factorio/saves),

    true
  end

  def stop_container!
    return true if container_dead?

    run_command(:server, self.name,
      %(docker stop),
      self.name
    )

    true
  end

  def container_alive?
    key = [self.name, 'container-alive'].join('-')
    MemoryCache.fetch(key, expires_in: 10) do
      output = run_command(:server, self.name,
        %(docker inspect),
        %(-f '{{.State.Running}}'),
        self.name
      )
      (output == 'true')
    end
  end

  def container_dead?
    !container_alive?
  end

################################################################################

  def start_rcon!
    self.rcon.startup!

    true
  end

  def stop_rcon!
    self.rtt = nil
    self.rcon.shutdown!

    true
  end

################################################################################

  def threads
    Thread.list.collect do |t|
      OpenStruct.new(
        pid: Process.pid,
        name: t.name,
        status: t.status,
        priority: t.priority,
        started_at: t[:started_at] || Time.now.to_i
      )
    end
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
    self.rcon.connected?
  end

  def disconnected?
    !connected?
  end

################################################################################

  def authenticated?
    self.rcon.authenticated?
  end

  def unauthenticated?
    !authenticated?
  end

################################################################################

  def available?
    self.rcon.available?
  end

  def unavailable?
    !available?
  end

################################################################################

  def rcon_command_nonblock(command)
    return if unavailable?
    self.rcon.command_nonblock(command)

    true
  end

  def rcon_command(command)
    return if unavailable?
    self.rcon.command(command)
  end

################################################################################

end
