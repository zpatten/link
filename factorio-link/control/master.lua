function set_link_id(id)
  global.link_id = tonumber(id)
end

function ping()
  global.ticks_since_last_link_operation = 0

  rcon.print("PONG")
end

function rtt(usec)
  global.link_rtt = usec

  rcon.print("OK")
end

function ticks_since_last_link_operation(event)
  if not global.ticks_since_last_link_operation then
    global.ticks_since_last_link_operation = 0
  end

  global.ticks_since_last_link_operation = global.ticks_since_last_link_operation + 1
end
script.on_event(defines.events.on_tick, ticks_since_last_link_operation)
