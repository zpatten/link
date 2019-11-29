# frozen_string_literal: true

require_relative 'server/chat'
require_relative 'server/id'
require_relative 'server/logistics'
require_relative 'server/ping'
require_relative 'server/rcon'
require_relative 'server/research'
require_relative 'server/signals'

class Server

################################################################################

  include Server::Chat
  include Server::ID
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

  attr_reader :method_proxy
  attr_reader :rcon

  RECV_MAX_LEN = 64 * 1024

################################################################################

  def initialize(name, details)
    @name                = name
    @id                  = Zlib::crc32(@name.to_s)
    @network_id          = [@id].pack("L").unpack("l").first

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
        rtt: @rtt.nil? ? '-' : "#{@rtt} ms"
      }.to_json)
    end
  end

  def rtt
    @rtt
  end

  def rtt=(value)
    if parent?
      @rtt = value
      update_websocket
      @rtt
    elsif child?
      self.method_proxy.rtt = value
    end
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

  def running!(running=false)
    unless Config.servers[@name].nil?
      Config.servers[@name]['running'] = running
      Config.save!
    end
    running
  end

  def running?
    !!Config.servers[@name]['running']
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
    if File.exists?(self.save_file)
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

  def restart!
    self.stop!
    sleep 1
    self.start!
  end

  def start!
    self.start_container!
    self.start_process!
    self.start_rcon!

    Timeout.timeout(60) do
      sleep 1 while self.unavailable?
    end
  end

  def stop!
    self.stop_rcon!
    self.stop_process!
    self.stop_container!

    Timeout.timeout(60) do
      sleep 1 while self.available?
    end
  end

################################################################################

  def start_process!
    unless alive?
      @method_proxy = MethodProxy.new(self, Process.pid)

      @child_pid = Process.fork do
        Thread.list.each do |thread|
          thread.exit unless thread == Thread.main
        end

        $0 = "Link Server: #{self.name}"
        Thread.current.name = self.name
        Thread.current[:started_at] = Time.now.to_f

        @rcon = RCon.new(@name, @host, @client_port, @client_password)

        self.method_proxy.start do |e|
          unless e.class == Timeout::Error
            Process.exit!
          end
        end

        ThreadPool.execute do
          schedule_chat
          schedule_id
          schedule_logistics
          schedule_ping
          schedule_research
          schedule_research_current
          schedule_signals
        end
      end
      Process.detach(@child_pid)

      self.method_proxy.start do |e|
        self.stop_process!
      end
    end
  end

  def stop_process!
    if alive?
      Process.kill('INT', @child_pid)
      self.method_proxy.stop
    end
  end

################################################################################

  def start_container!
    FileUtils.cp_r(Servers.factorio_mods, self.path)

    command = %(/usr/bin/env chcon -Rt svirt_sandbox_file_t #{self.path})
    $logger.info(:server) { "[#{self.name}] Command: #{command.inspect}" }
    system command

    run_command(:server, self.name,
      %(sudo),
      %(docker run),
      %(--rm),
      %(--detach),
      %(--name="#{self.name}"),
      %(--network=host),
      %(-e FACTORIO_PORT="#{self.factorio_port}"),
      %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}"),
      %(-e FACTORIO_RCON_PORT="#{self.client_port}"),
      %(-e PGID="$(id -g)"),
      %(-e PUID="$(id -u)"),
      %(-e RUN_CHOWN="false"),
      %(--volume=#{self.config_path}:/opt/factorio/config),
      %(--volume=#{self.mods_path}:/opt/factorio/mods),
      %(--volume=#{self.saves_path}:/opt/factorio/saves),
      Config.factorio_docker_image
    )

    running!(true)

    true
  end

  def stop_container!
    command = Array.new
    command << %(sudo)
    command << %(docker stop)
    command << self.name
    command = command.flatten.compact.join(' ')

    $logger.info(:server) { "[#{self.name}] Command: #{command.inspect}" }
    system command

    running!(false)

    true
  end

################################################################################

  def start_rcon!
    if parent? && alive?
      self.method_proxy.start_rcon!
    elsif child?
      self.rcon.startup!
    end

    true
  end

  def stop_rcon!
    if parent? && alive?
      self.method_proxy.stop_rcon!
      self.rtt = nil
    elsif child?
      self.rcon.shutdown!
    end

    true
  end

################################################################################

  def threads
    if parent? && alive?
      self.method_proxy.threads
    elsif child?
      Thread.list.collect do |t|
        OpenStruct.new(
          pid: Process.pid,
          name: t.name,
          status: t.status,
          priority: t.priority,
          started_at: t[:started_at] || Time.now.to_i
        )
      end
    else
      []
    end
  end

################################################################################

  def parent?
    (Process.pid == @parent_pid) || master?
  end

  def child?
    !parent?
  end

################################################################################

  def container_alive?
    key = [self.name, 'container-alive'].join('-')
    MemoryCache.fetch(key, expires_in: 10) do
      output = run_command(:server, self.name,
        %(sudo),
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

  def alive?
    !!Process.kill(0, @child_pid) rescue false
  end

  def dead?
    !alive?
  end

################################################################################

  def connected?
    if parent? && alive?
      self.method_proxy.connected?
    elsif child?
      self.rcon.connected?
    else
      false
    end
  end

  def disconnected?
    if parent? && alive?
      self.method_proxy.disconnected?
    elsif child?
      self.rcon.disconnected?
    else
      true
    end
  end

################################################################################

  def authenticated?
    if parent? && alive?
      self.method_proxy.authenticated?
    elsif child?
      self.rcon.authenticated?
    else
      false
    end
  end

  def unauthenticated?
    if parent? && alive?
      self.method_proxy.unauthenticated?
    elsif child?
      self.rcon.unauthenticated?
    else
      true
    end
  end

################################################################################

  def available?
    if parent? && alive?
      self.method_proxy.available?
    elsif child?
      self.rcon.available?
    else
      false
    end
  end

  def unavailable?
    if parent? && alive?
      self.method_proxy.unavailable?
    elsif child?
      self.rcon.unavailable?
    else
      true
    end
  end

################################################################################

  def rcon_command_nonblock(command:)
    if parent? && alive?
      self.method_proxy.rcon_command_nonblock(command: command)
    elsif child?
      return if unavailable?
      self.rcon.command_nonblock(command: command)

      true
    end
  end

  def rcon_command(command:)
    if parent? && alive?
      self.method_proxy.rcon_command(command: command)
    elsif child?
      return if unavailable?
      self.rcon.command(command: command)
    end
  end

################################################################################

end
