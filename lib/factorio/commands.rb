# frozen_string_literal: true

def get_commands(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    command_events = JSON.parse(payload)
    unless command_events.empty?
      $logger.debug(:commands) { command_events.ai }
      origin_server = Servers.find_by_name(host)
      (Servers.find(:commands) - [origin_server]).each do |server|
        command_events.each do |command_event|
          # message = %(#{command_event["player_name"]}@#{host}: #{command_event["message"]})
          player_index = command_event["player_index"]
          command = Array.new
          command << "/#{command_event["command"]}"
          command << [command_event["parameters"]].flatten.compact.join(" ")
          command = command.flatten.compact.join(" ")
          server.rcon_command_nonblock(command, method(:rcon_redirect), [player_index, command.strip, host])
        end
      end
    end
  end
end

# Link Factorio Server Command Mirroring
################################################################################
def schedule_server_commands
  schedule_servers(:commands) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'get_commands'))
    server.rcon_command_nonblock(command, method(:get_commands))
  end
end

# Link Factorio Server Set Command Mirroring Whitelist
################################################################################
def schedule_server_command_whitelist
  schedule_servers(:command_whitelist) do |server|
    command_whitelist = Config.server_value(server.name, :command_whitelist)
    command = %(/#{rcon_executor} remote.call('link', 'set_command_whitelist', '#{command_whitelist.to_json}'))
    server.rcon_command_nonblock(command, method(:rcon_print))
  end
end
