# RTT
def ping(host, packet_fields, started_at)
  # Calculate the RTT based on how much time passed from the start of the inital
  # request until we received the response here.
  rtt = (Time.now.to_f - started_at)

  # Update Factorio Servers with our current RTT
  server = Servers.find_by_name(host)
  command = %(/#{rcon_executor} remote.call('link', 'rtt', '#{rtt}'))
  server.rcon_command(command, method(:rcon_print))
  $logger.debug { "[#{server.id}] rtt: #{(rtt * 1000.0).round(0)}ms" }
end

# Link Factorio Server Ping (Calculates RTT)
################################################################################
schedule_server(:ping) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'ping'))
  server.rcon_command(command, method(:ping), Time.now.to_f)
end
