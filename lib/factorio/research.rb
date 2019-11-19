# frozen_string_literal: true

def set_research(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.nil? || payload.empty?
    research = JSON.parse(payload)
    unless research.empty?
      $logger.debug(:research) { "[#{server.id}] research: #{research.ai}" }
      command = %(/#{rcon_executor} remote.call('link', 'set_research', '#{research.to_json}'))
      Servers.find(:non_research).each do |server|
        server.rcon_command_nonblock(command, method(:rcon_print))
      end
    end
  end
end

def set_current_research(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.nil? || payload.empty?
    current_research = JSON.parse(payload)
    $logger.debug(:research) { "[#{server.id}] current research: #{current_research.ai}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_current_research', '#{current_research.to_json}'))
    Servers.find(:non_research).each do |server|
      server.rcon_command_nonblock(command, method(:rcon_print))
    end
  end
end

# Link Factorio Server Current Research Mirroring
################################################################################
def schedule_server_current_research
  ThreadPool.schedule_servers(:current_research) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'get_current_research'))
    server.rcon_command_nonblock(command, method(:set_current_research))
  end
end

# Link Factorio Server Research Mirroring
################################################################################
def schedule_server_research
  ThreadPool.schedule_servers(:research) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'get_research'))
    server.rcon_command_nonblock(command, method(:set_research))
  end
end
