function link_dump(printer)
  printer.print("Link Dump")
  printer.print("  - global.link_debug: "..tostring(global.link_debug))
  printer.print("  - global.link_enabled: "..tostring(global.link_enabled))
  printer.print("  - global.link_rtt: "..global.link_rtt)
  printer.print("  - global.link_events: "..dump(global.link_events))
  printer.print("  - global.link_provider_chests: "..dump(global.link_provider_chests))
  printer.print("  - global.link_requester_chests: "..dump(global.link_requester_chests))
  printer.print("  - global.link_inventory_combinators: "..dump(global.link_inventory_combinators))
  printer.print("  - global.ticks_since_last_link_operation: "..ticks_since_last_link_operation)
end

function on_link_init()
  game.print("on_link_init")

  global.link_debug = false
  global.link_enabled = true

  global.link_rtt = 0

  global.link_events = {}

  global.link_provider_chests = {}
  global.link_requester_chests = {}

  global.link_inventory_combinators = {}

  global.ticks_since_last_link_operation = 0

  add_all_link_entities()
end
script.on_init(on_link_init)
