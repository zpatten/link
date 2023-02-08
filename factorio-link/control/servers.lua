function set_link_gui_server_list(json)
  global.link_server_list = game.json_to_table(json)
  link_gui_servers_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_storage(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_storage_table, data)
  rcon.print("OK")
end

function set_link_gui_logistics_provided(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_provided, data)
  rcon.print("OK")
end

function set_link_gui_logistics_requested(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_requested, data)
  rcon.print("OK")
end

function set_link_gui_logistics_fulfilled(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_fulfilled, data)
  rcon.print("OK")
end

function set_link_gui_logistics_unfulfilled(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_unfulfilled, data)
  rcon.print("OK")
end

function set_link_gui_logistics_overflow(json)
  data = game.json_to_table(json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_overflow, data)
  rcon.print("OK")
end
