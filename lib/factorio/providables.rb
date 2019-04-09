def get_providables(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    providables = JSON.parse(payload)
    unless providables.empty?
      $logger.debug(:providables) { "[#{server.id}] providables: #{PP.singleline_pp(providables, "")}" }
      providables.each do |item_name, item_count|
        Storage.add(item_name, item_count)
      end
    end
  end
end

# Link Factorio Server Get Providables
################################################################################
schedule_server(:providables) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
  server.rcon_command_nonblock(command, method(:get_providables))
end
