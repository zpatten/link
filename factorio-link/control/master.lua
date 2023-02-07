function set_link_id(id)
  global.link_id = tonumber(id)
end

function ping()
  rcon.print("PONG")
end

function rtt(usec)
  global.link_rtt = usec

  rcon.print("OK")
end
