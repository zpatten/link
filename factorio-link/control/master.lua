function set_link_id(id)
  global.link_id = tonumber(id)
  rcon.print("OK")
end

function set_link_name(name)
  global.link_name = tostring(name)
  rcon.print("OK")
end

function ping()
  rcon.print("PONG")
end

function rtt(usec)
  global.link_rtt = usec
  rcon.print("OK")
end
