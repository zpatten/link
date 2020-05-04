function set_link_server_list(json)
  global.ticks_since_last_link_operation = 0

  global.link_server_list = game.json_to_table(json)
  link_gui_servers_table_update(player)

  rcon.print("OK")
end
