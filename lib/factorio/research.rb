def set_research(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    research = JSON.parse(payload)
    unless research.empty?
      $logger.debug { "[#{server.id}] research: #{PP.singleline_pp(research, "")}" }
      command = %(/#{rcon_executor} remote.call('link', 'set_research', '#{research.to_json}'))
      Servers.find(:non_research).each do |server|
        server.rcon_command_nonblock(command, method(:rcon_print))
      end
    end
  end
end

def set_current_research(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    current_research = JSON.parse(payload)
    $logger.debug { "[#{server.id}] current research: #{PP.singleline_pp(current_research, "")}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_current_research', '#{current_research.to_json}'))
    Servers.find(:non_research).each do |server|
      server.rcon_command_nonblock(command, method(:rcon_print))
    end
  end
end

# Link Factorio Server Current Research Mirroring
################################################################################
schedule_server(:current_research) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_current_research'))
  server.rcon_command_nonblock(command, method(:set_current_research))
end

# Link Factorio Server Research Mirroring
################################################################################
schedule_server(:research) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_research'))
  server.rcon_command_nonblock(command, method(:set_research))
end
