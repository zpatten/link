function link_dump(printer)
  printer.print("Link Dump")
  printer.print("  - global.link_enabled: "..tostring(global.link_enabled))
  printer.print("  - global.link_debug: "..tostring(global.link_debug))
  printer.print("  - global.link_id: "..global.link_id)
  printer.print("  - global.link_rtt: "..global.link_rtt)
  printer.print("  - global.ticks_since_last_link_operation: "..global.ticks_since_last_link_operation)
  printer.print("  - global.link_command_whitelist: "..serpent.block(global.link_command_whitelist))
  printer.print("  - global.link_events: "..serpent.block(global.link_events))
  printer.print("  - global.link_inventory_combinators: "..serpent.block(global.link_inventory_combinators))
  printer.print("  - global.link_receiver_combinators: "..serpent.block(global.link_receiver_combinators))
  printer.print("  - global.link_transmitter_combinators: "..serpent.block(global.link_transmitter_combinators))
  printer.print("  - global.link_provider_chests: "..serpent.block(global.link_provider_chests))
  printer.print("  - global.link_requester_chests: "..serpent.block(global.link_requester_chests))
end

function link_debug()
  return global.link_debug
end

function on_link_init()
  game.print("on_link_init")

  -- removed crashsite and cutscene start, so on_player_created inventory safe
  remote.call("freeplay", "set_disable_crashsite", true)

  -- Skips popup message to press tab to start playing
  remote.call("freeplay", "set_skip_intro", true)

  global.link_debug = false
  global.link_enabled = true

  global.link_rtt = 0

  global.link_id = 42

  global.link_events = {}

  global.link_providables = {}

  global.link_provider_chests = {}
  global.link_requester_chests = {}

  global.link_electrical_providers = {}
  global.link_electrical_requesters = {}

  global.link_fluid_providers = {}
  global.link_fluid_requesters = {}

  global.link_previous_signals = {}
  global.link_rx_signals = {}

  global.link_inventory_combinators = {}
  global.link_receiver_combinators = {}
  global.link_transmitter_combinators = {}

  global.ticks_since_last_link_operation = 0

  global.link_command_whitelist = {}

  global.link_server_list = {}

  add_all_link_entities()
end
script.on_init(on_link_init)

function on_player_created(event)
  local player = game.players[event.player_index]

  player.insert{ name = LINK_ACTIVE_PROVIDER_CHEST_NAME, count = 1 }
  player.insert{ name = LINK_BUFFER_CHEST_NAME, count = 1 }
  player.insert{ name = LINK_REQUESTER_PROVIDER_CHEST_NAME, count = 1 }

  player.insert{ name = LINK_ELECTRICAL_PROVIDER_NAME, count = 1 }
  player.insert{ name = LINK_ELECTRICAL_REQUESTER_NAME, count = 1 }

  player.insert{ name = LINK_FLUID_PROVIDER_NAME, count = 1 }
  player.insert{ name = LINK_FLUID_REQUESTER_NAME, count = 1 }

  player.insert{ name = "substation", count = 1 }

  player.insert{ name = "power-armor-mk2", count = 1 }
  player.insert{ name = "fusion-reactor-equipment", count = 2 }
  player.insert{ name = "exoskeleton-equipment", count = 6 }
  player.insert{ name = "energy-shield-mk2-equipment", count = 3 }
  player.insert{ name = "night-vision-equipment", count = 1 }
  player.insert{ name = "belt-immunity-equipment", count = 1 }
  player.insert{ name = "battery-mk2-equipment", count = 1 }
end
script.on_event(defines.events.on_player_created, on_player_created)

function on_player_joined_game(event)
  local player = game.players[event.player_index]
  link_gui_destroy(player)
  link_gui_create(player)
end
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)

function on_player_left_game(event)
  local player = game.players[event.player_index]
  link_gui_destroy(player)
end
script.on_event(defines.events.on_player_left_game, on_player_left_game)
