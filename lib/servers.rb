# frozen_string_literal: true

require_relative 'servers/create'
require_relative 'servers/delete'
require_relative 'servers/rcon'
require_relative 'servers/saves'
require_relative 'servers/state'

class Servers
  include Enumerable

################################################################################

  include Servers::Create
  include Servers::Delete
  include Servers::RCon
  include Servers::Saves
  include Servers::State

################################################################################

  def initialize
    @servers = Concurrent::Map.new
    Config.servers.each_pair do |server_name, server_details|
      server = Server.new(server_name, server_details)
      @servers[server_name] = server
      LinkLogger.info(:servers) { "Loaded Server #{server.host_tag.ai} (id:#{server.id.ai})" }
    end
  end

################################################################################

  def each(&block)
    if block_given?
      @servers.values.sort_by { |server| server.name }.each(&block)
    else
      to_enum(:each)
    end
  end

################################################################################

  def find_by_name(name)
    find { |s| s.name.to_s == name.to_s }
  end

  def find_by_id(id)
    find { |s| s.id.to_i == id.to_i }
  end

  def find_by_task(task, except=[])
    servers = case task.to_sym
    when :research, :research_current
      select { |s| s.research }
    when :non_research
      select { |s| !s.research }
    else
      select { |s| !!Config.server(s.name.to_s, task.to_s) }
    end
    servers.delete_if { |s| except.map(&:to_s).include?(s.name.to_s) }
  end

################################################################################

  def to_json
    server_list = Hash.new
    collect do |server|
      if server.available?
        server_list[server.name] = {
          name: server.name,
          host: external_host,
          port: server.factorio_port,
          research: server.research,
          responsive: server.responsive?,
          rtt: server.rtt
        }
      end
    end
    server_list.to_json
  end

################################################################################

  def start!(container: false)
    LinkLogger.info(:servers) { "Start Servers (container: #{container.ai})" }
    each { |server| Runner.pool.post { server.start!(container: container) } }
  end

  def stop!(container: false)
    LinkLogger.warn(:servers) { "Stopping Servers (container: #{container.ai})" }
    each { |server| Runner.pool.post { server.stop!(container: container) } }
  end

  def restart!(container: false)
    LinkLogger.warn(:servers) { "Restart Servers (container: #{container.ai})" }
    each { |server| Runner.pool.post { server.restart!(container: container) } }
  end

################################################################################

  # def backup
  #   LinkLogger.debug(:servers) { "Backing Up Servers" }
  #   each do |server|
  #     if server.available?
  #       server.backup(timestamp: true)
  #       sleep 3
  #     end
  #   end
  # end

################################################################################

  def factorio_mods
    File.expand_path(File.join(LINK_ROOT, 'mods'))
  end

################################################################################

  def random
    if (available_servers = available)
      random_index = SecureRandom.random_number(available_servers.count)
      return available_servers[random_index]
    else
      LinkLogger.fatal(:servers) { "No servers available!" }
    end

    nil
  end

################################################################################

  module ClassMethods
    @@servers ||= Servers.new

    def to_json
      @@servers.send(:to_json)
    end

    def to_enum
      @@servers.send(:to_enum)
    end

    def method_missing(method_name, *args, &block)
      @@servers.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
