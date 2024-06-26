function handle_link_command(event)
  local printer = nil
  if event.player_index and event.player_index ~= -1 then
    local player = game.players[event.player_index]
    printer = player
  else
    printer = rcon
  end

  if not event.parameter then
    printer.print("Available Commands: reset, enable, disable, debug (on|off), status, dump")
  elseif event.parameter == "dump" then
    link_dump(printer)
  elseif event.parameter == "reset" then
    on_link_init()
  elseif event.parameter == "enable" then
    global.link_enabled = true
  elseif event.parameter == "disable" then
    global.link_enabled = false
  elseif event.parameter == "debug on" then
    global.link_debug = true
  elseif event.parameter == "debug off" then
    global.link_debug = false
  elseif event.parameter == "status" then
    printer.print("Link v0.0.1")
    printer.print("  - Enabled: "..tostring(global.link_enabled).."  (id:"..global.link_id..", debug:"..tostring(global.link_debug)..")")
    printer.print("  - RCON RTT: "..round(global.link_rtt * 1000, nil).."ms  (master <-> rcon)")
    printer.print("  - Provider Chest Count: "..table_size(global.link_provider_chests))
    printer.print("  - Requester Chest Count: "..table_size(global.link_requester_chests))
    printer.print("  - Inventory Combinator Count: "..table_size(global.link_inventory_combinators))
    printer.print("  - Receiver Combinator Count: "..table_size(global.link_receiver_combinators))
    printer.print("  - Transmitter Combinator Count: "..table_size(global.link_transmitter_combinators))
    printer.print("  - Event Count: "..table_size(global.link_events))
    printer.print("  - Command Whitelist: "..serpent.block(global.link_command_whitelist))
    printer.print("  - Servers: "..serpent.block(global.link_server_list))
  end
end

commands.add_command("link", "manage link", handle_link_command)
