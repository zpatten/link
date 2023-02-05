# frozen_string_literal: true

require_relative 'server/container'
require_relative 'server/pool'
require_relative 'server/rcon'

require_relative 'server/task/chat'
require_relative 'server/task/fulfillments'
require_relative 'server/task/id'
require_relative 'server/task/ping'
require_relative 'server/task/providables'
require_relative 'server/task/research'
require_relative 'server/task/save'
require_relative 'server/task/server_list'
require_relative 'server/task/signals'

class Server

################################################################################

  include Server::Container
  include Server::Pool
  include Server::RCon

  include Server::Task::Chat
  include Server::Task::Fulfillments
  include Server::Task::ID
  include Server::Task::Ping
  include Server::Task::Providables
  include Server::Task::Research
  include Server::Task::Save
  include Server::Task::ServerList
  include Server::Task::Signals

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

  RECV_MAX_LEN = (2 ** 16) - 1

################################################################################

  def initialize(name, details)
    @name         = name.dup
    @id           = Zlib::crc32(@name.to_s)
    @network_id   = [@id].pack("L").unpack("l").first
    @pinged_at    = Time.now.to_f
    @ping_timeout = Config.value(:timeout, :ping)
    @rtt          = 0
    @watch        = false

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

  def update_rtt(value)
    @pinged_at = Time.now.to_f
    @rtt       = value
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
    File.expand_path(File.join(self.path, 'config'))
  end

  def mods_path
    File.expand_path(File.join(self.path, 'mods'))
  end

  def saves_path
    File.expand_path(File.join(self.path, 'saves'))
  end

  def save_file
    File.expand_path(File.join(self.saves_path, "save.zip"))
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
        FileUtils.mkdir_p(Servers.save_path)
      rescue Errno::ENOENT
      end

      filename = if timestamp
        "#{@name}-#{Time.now.to_i}.zip"
      else
        "#{@name}.zip"
      end
      backup_save_file = File.join(Servers.save_path, filename)
      latest_save_file = self.latest_save_file
      FileUtils.cp_r(latest_save_file, backup_save_file)
      LinkLogger.info(log_tag(:backup)) { "Backed up #{latest_save_file.ai} to #{backup_save_file.ai}" }
    end

    rcon_command %(/server-save)

    true
  end

################################################################################

  def start!(container: true)
    LinkLogger.info(log_tag) { "Start Server (container: #{container.ai})" }

    if container
      start_container!
      sleep 1 while container_dead?
    end
    start_pool!
    sleep 0.25 while !pool_running? && container_alive?
    start_rcon!
    sleep 0.25 while unauthenticated? && container_alive?
    start_threads!
    sleep 0.25 while unavailable? && container_alive?
    @watch = true

    true
  end

  def stop!(container: true)
    LinkLogger.info(log_tag) { "Stop Server (container: #{container.ai})" }

    @watch = false
    stop_threads!
    stop_rcon!
    stop_pool!
    if container
      stop_container!
      sleep 1 while container_alive?
    end

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

  def start_threads!
    return false if @origin.resolved?

    schedule_task_ping
    schedule_task_id
    schedule_task_research_current
    schedule_task_research
    schedule_task_chat
    schedule_task_fulfillments
    schedule_task_providables
    schedule_task_server_list
    schedule_task_signals
    schedule_task_save

    true
  end

  def stop_threads!
    return false if @origin.resolved?

    @origin and (@origin.resolved? or @origin.resolve)
    sleep (Config.value(:timeout, :thread) + 1)

    true
  end

################################################################################

  def unresponsive?
    ((@pinged_at + @ping_timeout) < Time.now.to_f)
  end

  def responsive?
    !unresponsive?
  end

################################################################################

  def connected?
    (@rcon && @rcon.connected?)
  end

  def disconnected?
    !connected?
  end

################################################################################

  def authenticated?
    (@rcon && @rcon.authenticated?)
  end

  def unauthenticated?
    !authenticated?
  end

################################################################################

  def available?
    (@rcon && @rcon.available?)
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
