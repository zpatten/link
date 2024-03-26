function get_link_chats()
  if global.link_chats then
    rcon.print(game.table_to_json(global.link_chats))
  end
  global.link_chats = {}
end

function link_chat_event(data)
  local event = game.json_to_table(data)
  script.raise_event(defines.events.on_console_chat, event)
end

function on_link_chat(event)
  if not global.link_chats then
    global.link_chats = {}
  end
  if event.message and event.mod_name ~= "link" then
    local player = game.players[event.player_index]
    local message = {
      player_name = player.name,
      message = event.message
    }
    table.insert(global.link_chats, message)
  end
end
script.on_event(defines.events.on_console_chat, on_link_chat)
