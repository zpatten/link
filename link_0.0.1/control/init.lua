function link_dump(printer)
  printer.print("Link Dump")
  printer.print("  - global.link_enabled: "..tostring(global.link_enabled))
  printer.print("  - global.link_debug: "..tostring(global.link_debug))
  printer.print("  - global.link_id: "..global.link_id)
  printer.print("  - global.link_rtt: "..global.link_rtt)
  printer.print("  - global.ticks_since_last_link_operation: "..global.ticks_since_last_link_operation)
  printer.print("  - global.link_command_whitelist: "..dump(global.link_command_whitelist))
  printer.print("  - global.link_events: "..dump(global.link_events))
  printer.print("  - global.link_inventory_combinators: "..dump(global.link_inventory_combinators))
  printer.print("  - global.link_receiver_combinators: "..dump(global.link_receiver_combinators))
  printer.print("  - global.link_transmitter_combinators: "..dump(global.link_transmitter_combinators))
  printer.print("  - global.link_provider_chests: "..dump(global.link_provider_chests))
  printer.print("  - global.link_requester_chests: "..dump(global.link_requester_chests))
end

function link_debug()
  return global.link_debug
end

function on_link_init()
  game.print("on_link_init")

  global.link_debug = false
  global.link_enabled = true

  global.link_rtt = 0

  global.link_id = 42

  global.link_events = {}

  global.link_provider_chests = {}
  global.link_requester_chests = {}

  global.link_previous_signals = {}

  global.link_inventory_combinators = {}
  global.link_receiver_combinators = {}
  global.link_transmitter_combinators = {}

  global.link_electrical_providers = {}
  global.link_electrical_requesters = {}

  global.ticks_since_last_link_operation = 0

  global.link_command_whitelist = {}

  add_all_link_entities()
end
script.on_init(on_link_init)
