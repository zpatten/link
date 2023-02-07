# frozen_string_literal: true

require_relative 'server/actions'
require_relative 'server/container'
require_relative 'server/pool'
require_relative 'server/rcon'
require_relative 'server/save'
require_relative 'server/state'
require_relative 'server/task'
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

  include Server::Actions
  include Server::Container
  include Server::Pool
  include Server::RCon
  include Server::Save
  include Server::State
  include Server::Task
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

  attr_accessor :timedout_at
  attr_reader :metrics

  RECV_MAX_LEN = (2 ** 16) - 1

################################################################################

  def initialize(name, details)
    @name         = name.dup
    @id           = Zlib::crc32(@name.to_s)
    @network_id   = [@id].pack("L").unpack("l").first
    @ping_timeout = Config.value(:timeout, :ping)
    @pinged_at    = Time.now.to_f
    @rtt          = 0
    @timedout_at  = nil
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

    @metrics           = Concurrent::Map.new

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

end
