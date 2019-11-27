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

  # attr_accessor :rtt
  attr_reader :client_password
  attr_reader :client_port
  attr_reader :details
  attr_reader :factorio_port
  attr_reader :host
  attr_reader :name
  attr_reader :rcon
  attr_reader :research
  attr_reader :child_pid

  RECV_MAX_LEN = 64 * 1024

################################################################################

  def initialize(name, details)
    @name              = name
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

    @method_proxy_mutex = Mutex.new
    @method_rproxy_mutex = Mutex.new

    @parent_pid = Process.pid
  end

################################################################################

  def id
    Zlib::crc32(@name.to_s)
  end

  def network_id
    [self.id].pack("L").unpack("l").first
  end

  def update_websocket
    ::WebServer.settings.server_sockets.each do |s|
      s.send({
        name: @name,
        connected: connected?,
        authenticated: authenticated?,
        available: available?,
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
      self.method_proxy(:rtt=, value)
    else
      raise "#rtt= called out of context!"
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

  def method_proxy(*method_args)
    result = nil
    if parent?
      @method_proxy_mutex.synchronize do
        @method_proxy_child.send(Marshal.dump(method_args), 0)
        result = Marshal.load(@method_proxy_child.recv(RECV_MAX_LEN))
        $logger.debug(:mproxy) { "#{method_args.inspect} == #{result.inspect}" }
      end
    elsif child?
      @method_rproxy_mutex.synchronize do
        @method_rproxy_parent.send(Marshal.dump(method_args), 0)
        result = Marshal.load(@method_rproxy_parent.recv(RECV_MAX_LEN))
        $logger.debug(:mrproxy) { "#{method_args.inspect} == #{result.inspect}" }
      end
    else
      raise "#method_proxy call out of context!"
    end
    result
  end

  def child_alive?
    !!Process.kill(0, @child_pid) rescue false
  end

  def start_process!
    unless child_alive?
      @method_proxy_child, @method_proxy_parent = UNIXSocket.pair(:DGRAM)
      @method_rproxy_child, @method_rproxy_parent = UNIXSocket.pair(:DGRAM)

      @child_pid = Process.fork do
        Thread.list.each do |thread|
          thread.exit unless thread == Thread.main
        end
        @method_proxy_child.close
        @method_rproxy_child.close
        $0 = "Link Server: #{self.name}"
        Thread.current.name = self.name

        @rcon = RCon.new(@name, @host, @client_port, @client_password)

        schedule_chat
        schedule_id
        schedule_ping
        schedule_requests
        schedule_research
        schedule_research_current

        ThreadPool.thread("#{self.name}-method-proxy-child") do
          loop do
            method_args = Marshal.load(@method_proxy_parent.recv(RECV_MAX_LEN))
            result = self.send(*method_args)
            data = Marshal.dump(result)
            @method_proxy_parent.send(data, 0)
          end
        end

        ThreadPool.execute
      end
      @method_proxy_parent.close
      @method_rproxy_parent.close

      ThreadPool.thread("#{self.name}-method-proxy-parent") do
        loop do
          method_args = Marshal.load(@method_rproxy_child.recv(RECV_MAX_LEN))
          result = if Object.constants.include?(method_args.first)
            Object.const_get(method_args.first).send(*method_args[1..-1])
          else
            self.send(*method_args)
          end
          # result = self.send(*method_args)
          data = Marshal.dump(result)
          @method_rproxy_child.send(data, 0)
        end
      end

    end
  end

  def stop_process!
    if child_alive?
      Process.kill('INT', @child_pid)
    end
  end

  def start!
    return if self.available?

    self.start_container!
    self.start_process!
    self.start_rcon!

    Timeout.timeout(60) do
      sleep SLEEP_TIME while self.unavailable?
    end
  end

  def stop!
    return if self.unavailable?

    # ThreadPool.wait_on_server_threads(self.name)

    self.stop_rcon!
    self.stop_process!
    self.stop_container!

    Timeout.timeout(60) do
      sleep SLEEP_TIME while self.available?
    end
  end

################################################################################

  def start_container!
    FileUtils.cp_r(Servers.factorio_mods, self.path)

    command = Array.new
    command << %(sudo)
    command << %(docker run)
    command << %(--rm)
    command << %(--detach)
    command << %(--name="#{self.name}")
    command << %(--network=host)
    command << %(-e FACTORIO_PORT="#{self.factorio_port}")
    command << %(-e FACTORIO_RCON_PASSWORD="#{self.client_password}")
    command << %(-e FACTORIO_RCON_PORT="#{self.client_port}")
    command << %(-e PGID="$(id -g)")
    command << %(-e PUID="$(id -u)")
    command << %(-e RUN_CHOWN="false")
    command << %(--volume=#{self.config_path}:/opt/factorio/config)
    command << %(--volume=#{self.mods_path}:/opt/factorio/mods)
    command << %(--volume=#{self.saves_path}:/opt/factorio/saves)
    command << Config.factorio_docker_image
    command = command.flatten.compact.join(' ')

    # $logger.info {%(chcon -Rt svirt_sandbox_file_t #{self.server_path})}
    system %(/usr/bin/env chcon -Rt svirt_sandbox_file_t #{self.path})
    # puts "command=#{command}"
    $logger.info(:server) { "command=#{command}" }
    system command

    running!(true)

    true
  end

  def stop_container!
    command = Array.new
    command << %(sudo)
    command << %(docker stop)
    command << self.name
    command = command.flatten.compact.join(' ')

    $logger.info(:server) { "command=#{command}" }
    # puts "command=#{command}"
    system command

    $rx_signals_initalized[self.name] = nil
    $tx_signals_initalized[self.name] = nil

    running!(false)

    true
  end

################################################################################

  def threads
    if parent? && child_alive?
      method_proxy(:threads)
    elsif child?
      Thread.list.collect do |t|
        OpenStruct.new(
          pid: Process.pid,
          object_id: t.object_id,
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

  def parent?
    Process.pid == @parent_pid
  end

  def child?
    !parent?
  end

  def start_rcon!
    if parent? && child_alive?
      method_proxy(:start_rcon!)
      # send_to_child(:start_rcon)
    elsif child?
      @rcon.startup!
    end

    true
  end

  def stop_rcon!
    if parent? && child_alive?
      method_proxy(:stop_rcon!)
      self.rtt = nil
    elsif child?
      @rcon.shutdown!
    end
    # @rcon.shutdown!
    # self.rtt = nil

    true
  end

################################################################################

  def connected?
    if parent? && child_alive?
      method_proxy(:connected?)
    elsif child?
      @rcon.connected?
    else
      false
    end
  end

  def disconnected?
    if parent? && child_alive?
      method_proxy(:disconnected?)
    elsif child?
      @rcon.disconnected?
    else
      true
    end
  end

################################################################################

  def authenticated?
    if parent? && child_alive?
      method_proxy(:authenticated?)
    elsif child?
      @rcon.authenticated?
    else
      false
    end
  end

  def unauthenticated?
    if parent? && child_alive?
      method_proxy(:unauthenticated?)
    elsif child?
      @rcon.unauthenticated?
    else
      true
    end
  end

################################################################################

  def available?
    # !self.paused? && @rcon.available?
    if parent? && child_alive?
      method_proxy(:available?)
    elsif child?
      @rcon.available?
    else
      false
    end
  end

  def unavailable?
    # self.paused? || @rcon.unavailable?
    if parent? && child_alive?
      method_proxy(:unavailable?)
    elsif child?
      @rcon.unavailable?
    else
      true
    end
  end

################################################################################

  # Displays RCON response packets for debugging or other uses (i.e. when we do not care about the response)
  def rcon_print(host, packet_fields, data)
    # $logger.debug { "RCON Received Packet: #{packet_fields.inspect}" }
  end


  def rcon_command_nonblock(command:, callback: nil, data: nil, what: nil)
    if parent? && child_alive?
      method_proxy(:rcon_command_nonblock, command: command, callback: callback, data: data, what: what)
    elsif child?
      return if unavailable?
      callback ||= method(:rcon_print)
      data ||= self
      @rcon.enqueue_packet(command, callback, data, what)

      true
    end
  end

  def rcon_command(command:, data: nil, what: nil)
    if parent? && child_alive?
      method_proxy(:rcon_command, command: command, data: data, what: what)
    elsif child?
      return if unavailable?
      packet_fields = @rcon.enqueue_packet(command, nil, data, what)
      response = @rcon.find_response(packet_fields.id)
      response.payload.strip
    end
  end

################################################################################

end
