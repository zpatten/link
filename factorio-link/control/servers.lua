function set_link_gui_server_list(json)
  global.link_server_list = game.json_to_table(json)
  link_gui_servers_table_update(player)

  rcon.print("OK")
end

function set_link_gui_storage(json)
  global.link_storage = game.json_to_table(json)
  link_gui_storage_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_provided(json)
  global.link_logistics_provided = game.json_to_table(json)
  link_gui_logistics_provided_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_requested(json)
  global.link_logistics_requested = game.json_to_table(json)
  link_gui_logistics_requested_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_fulfilled(json)
  global.link_logistics_fulfilled = game.json_to_table(json)
  link_gui_logistics_fulfilled_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_unfulfilled(json)
  global.link_logistics_unfulfilled = game.json_to_table(json)
  link_gui_logistics_unfulfilled_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_overflow(json)
  global.link_logistics_overflow = game.json_to_table(json)
  link_gui_logistics_overflow_table_update(player)

  rcon.print("OK")
end
