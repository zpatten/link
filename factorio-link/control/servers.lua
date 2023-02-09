function set_link_gui_server_list(json)
  global.link_server_list = game.json_to_table(json)
  link_gui_servers_table_update(player)

  rcon.print("OK")
end

function set_link_gui_logistics_storage(storage_items_json)
  storage_items = game.json_to_table(storage_items_json)
  link_gui_logistics_frame_update(global.link_gui_storage_table, storage_items, nil)
  rcon.print("OK")
end

function set_link_gui_logistics_provided(provided_items_json)
  provided_items = game.json_to_table(provided_items_json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_provided, provided_items, nil)
  rcon.print("OK")
end

function set_link_gui_logistics_requested(requested_items_json)
  requested_items = game.json_to_table(requested_items_json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_requested, requested_items, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items)
  rcon.print("OK")
end

function set_link_gui_logistics_fulfilled(fulfilled_items_json)
  global.link_logistics_fulfilled_items = game.json_to_table(fulfilled_items_json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_fulfilled, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items, global.link_logistics_unfulfilled_items)
  rcon.print("OK")
end

function set_link_gui_logistics_unfulfilled(unfulfilled_items_json)
  global.link_logistics_unfulfilled_items = game.json_to_table(unfulfilled_items_json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_unfulfilled, global.link_logistics_unfulfilled_items, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items)
  rcon.print("OK")
end

function set_link_gui_logistics_overflow(overflow_items_json)
  overflow_items = game.json_to_table(overflow_items_json)
  link_gui_logistics_frame_update(global.link_gui_logistics_table_overflow, overflow_items, nil)
  rcon.print("OK")
end
