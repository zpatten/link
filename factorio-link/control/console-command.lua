function get_link_commands()
  if global.link_commands then
    rcon.print(game.table_to_json(global.link_commands))
  end
  global.link_commands = {}
end

function link_command_event(data)
  local event = game.json_to_table(data)
  script.raise_event(defines.events.on_console_chat, event)
end

function set_link_command_whitelist(data)
  local link_command_whitelist = game.json_to_table(data)
  global.link_command_whitelist = link_command_whitelist

  rcon.print("OK")
end

function on_link_command(event)
  if not global.link_commands then
    global.link_commands = {}
    global.link_command_whitelist = {}
  end
  if event.command and event.mod_name ~= "link" then
    local player_name = ""
    if event.player_index and event.player_index ~= -1 then
      player_name = game.players[event.player_index].name

      local message = {
        player_index = event.player_index,
        player_name = player_name,
        command = event.command,
        parameters = event.parameters
      }

      for _, command in pairs(global.link_command_whitelist) do
        if event.command == command then
          table.insert(global.link_commands, message)
        end
      end
    end

  end
end
script.on_event(defines.events.on_console_command, on_link_command)
