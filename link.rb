require "logger"
require "pp"
require "json"

require_relative "lib/config"
require_relative "lib/chat"
require_relative "lib/command"
require_relative "lib/logistics"
require_relative "lib/rcon"
require_relative "lib/requests"
require_relative "lib/research"
require_relative "lib/servers"
require_relative "lib/storage"
require_relative "lib/support"

#ENV["DEBUG"] = "1"

$logger = Logger.new(STDOUT)
$logger.level = (!!ENV["DEBUG"] ? Logger::DEBUG : Logger::INFO)

Thread.abort_on_exception = true


SLEEP_TIME = 0.0001

Config.load("config.json")
# c = Config.new("servers.json")

# pp c.core.host

# c.core.each_pair do |key, value|
#   puts "#{key}=#{value}"
# end

# pp c.to_h.to_json

# pp $config.c.send("core".to_sym)
# pp Config.servers.count
# pp Config.server_value("core", "schedule_serversr", "ping")
# pp Config.server_value("provinggrounds", "schedule_serversr", "ping")

# exit!

@shutdown = false
Requests.reset
$threads = Array.new


at_exit do
  $stderr.puts "Shutting down!"
  @shutdown = true
  Servers.shutdown!
  $threads.map(&:exit)
  Storage.put
end

%w( INT ).each do |signal|
  Signal.trap(signal) do
    $stderr.puts "Caught Signal: #{signal}"
    exit
  end
end


# Calculate Deltas
################################################################################
schedule_task(:statistics) do
  Storage.delta
end

# Link Inventory Combinator Update
################################################################################
schedule_servers(:combinators) do |server|
  # get a copy of the storage
  storage = Storage.clone

  # if we have a previous copy of the storage detect changes and skip updating
  # if nothing has changed
  if (!!$previous_storage && ($previous_storage == storage))
    $logger.debug { "Skipping sending storage to inventory combinators; no changes detected." }
    next
  end
  $logger.debug { "Sending storage to inventory combinators." }

  # update inventory combinators with the current storage
  command = %(/#{rcon_executor} remote.call('link', 'set_inventory_combinator', '#{storage.to_json}'))
  Servers.rcon_command(command, method(:rcon_print))

  # stash a copy of the current storage so we can detect changes on the next run
  $previous_storage = storage.clone
end

# Link Factorio Server Ping (Calculates RTT)
################################################################################
schedule_servers(:ping) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'ping'))
  server.rcon_command(command, method(:ping), Time.now.to_f)
end

# Link Factorio Server Chat Mirroring
################################################################################
schedule_servers(:chats) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_chats'))
  server.rcon_command(command, method(:get_chats))
end

# Link Factorio Server Command Mirroring
################################################################################
schedule_servers(:commands) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_commands'))
  server.rcon_command(command, method(:get_commands))
end

# Link Factorio Server Set Command Mirroring Whitelist
################################################################################
schedule_servers(:command_whitelist) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'set_command_whitelist', '#{server.command_whitelist.to_json}'))
  server.rcon_command(command, method(:rcon_print))
end

# Link Factorio Server Get Providables
################################################################################
schedule_servers(:providables) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
  server.rcon_command(command, method(:get_providables))
end

# Link Factorio Server Perform Fulfillments and Get New Requests
################################################################################
schedule_servers(:requests) do |server|
  fulfillments

  command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
  server.rcon_command(command, method(:get_requests))
end

# Link Factorio Server Current Research Mirroring
################################################################################
schedule_servers(:current_research) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_current_research'))
  server.rcon_command(command, method(:set_current_research))
end

# Link Factorio Server Research Mirroring
################################################################################
schedule_servers(:research) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_research'))
  server.rcon_command(command, method(:set_research))
end

$threads.map(&:join)
