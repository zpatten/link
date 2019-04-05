def set_research(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    research = JSON.parse(payload)
    unless research.empty?
      $logger.debug { "RESEARCH[#{host}]: #{PP.singleline_pp(research, "")}" }
      command = %(/#{rcon_executor} remote.call('link', 'set_research', '#{research.to_json}'))
      Servers.find(:non_research).each do |server|
        server.rcon_command(command, method(:rcon_print))
      end
    end
  end
end

def set_current_research(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    current_research = JSON.parse(payload)
    $logger.debug { "CURRENT_RESEARCH[#{host}]: #{PP.singleline_pp(current_research, "")}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_current_research', '#{current_research.to_json}'))
    Servers.find(:non_research).each do |server|
      server.rcon_command(command, method(:rcon_print))
    end
  end
end

