function set_link_gui_servers(json)
  if global.link_gui and global.link_gui.visible then
    global.link_server_list = game.json_to_table(json)
    link_gui_servers_table_update(player)
  end
  rcon.print("OK")
end

function set_link_gui_signals(signal_networks_json)
  if global.link_gui and global.link_gui.visible then
    signal_networks = game.json_to_table(signal_networks_json)
    link_gui_signal_frame_update(global.link_gui_signals_table, signal_networks)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_storage(storage_items_json)
  if global.link_gui and global.link_gui.visible then
    storage_items = game.json_to_table(storage_items_json)
    link_gui_logistics_frame_update(global.link_gui_storage_table, storage_items)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_provided(provided_items_json, all_provided_items_json)
  if global.link_gui and global.link_gui.visible then
    provided_items = game.json_to_table(provided_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_provided, provided_items)

    all_provided_items = game.json_to_table(all_provided_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_all_provided, all_provided_items)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_requested(requested_items_json, all_requested_items_json)
  if global.link_gui and global.link_gui.visible then
    requested_items = game.json_to_table(requested_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_requested, requested_items, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items)

    all_requested_items = game.json_to_table(all_requested_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_all_requested, all_requested_items, global.link_logistics_all_fulfilled_items, global.link_logistics_all_unfulfilled_items)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_fulfilled(fulfilled_items_json, all_fulfilled_items_json)
  if global.link_gui and global.link_gui.visible then
    global.link_logistics_fulfilled_items = game.json_to_table(fulfilled_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_fulfilled, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items, global.link_logistics_unfulfilled_items)

    global.link_logistics_all_fulfilled_items = game.json_to_table(all_fulfilled_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_all_fulfilled, global.link_logistics_all_fulfilled_items, global.link_logistics_all_unfulfilled_items, global.link_logistics_all_unfulfilled_items)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_unfulfilled(unfulfilled_items_json, all_unfulfilled_items_json)
  if global.link_gui and global.link_gui.visible then
    global.link_logistics_unfulfilled_items = game.json_to_table(unfulfilled_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_unfulfilled, global.link_logistics_unfulfilled_items, global.link_logistics_fulfilled_items, global.link_logistics_unfulfilled_items)

    global.link_logistics_all_unfulfilled_items = game.json_to_table(all_unfulfilled_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_all_unfulfilled, global.link_logistics_all_unfulfilled_items, global.link_logistics_all_fulfilled_items, global.link_logistics_all_unfulfilled_items)
  end
  rcon.print("OK")
end

function set_link_gui_logistics_overflow(overflow_items_json, all_overflow_items_json)
  if global.link_gui and global.link_gui.visible then
    overflow_items = game.json_to_table(overflow_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_overflow, overflow_items, nil)

    all_overflow_items = game.json_to_table(all_overflow_items_json)
    link_gui_logistics_frame_update(global.link_gui_logistics_table_all_overflow, all_overflow_items, nil)
  end
  rcon.print("OK")
end
