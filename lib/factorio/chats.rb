def get_chats(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    chat_events = JSON.parse(payload)
    unless chat_events.empty?
      origin_server = Servers.find_by_name(host)
      (Servers.find_by_chat - [origin_server]).each do |server|
        chat_events.each do |chat_event|
          message = %(#{chat_event["player_name"]}@#{host}: #{chat_event["message"]})
          command = %(/#{rcon_executor} game.print('#{message}', {r = 1, g = 0, b = 1, a = 0.5}))
          server.rcon_command(command, method(:rcon_print))
        end
      end
    end
  end
end

# Link Factorio Server Chat Mirroring
################################################################################
schedule_server(:chats) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'get_chats'))
  server.rcon_command(command, method(:get_chats))
end
