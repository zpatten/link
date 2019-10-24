# frozen_string_literal: true

# RTT
def ping(host, packet_fields, started_at)
  # Calculate the RTT based on how much time passed from the start of the inital
  # request until we received the response here.
  rtt = (Time.now.to_f - started_at)

  # Update Factorio Servers with our current RTT
  server = Servers.find_by_name(host)
  command = %(/#{rcon_executor} remote.call('link', 'rtt', '#{rtt}'))
  server.rcon_command_nonblock(command, method(:rcon_print))
  rtt_ms = (rtt * 1000.0).round(0)
  server.rtt = rtt_ms
  $logger.debug(:ping) { "[#{server.name}] rtt: #{rtt_ms}ms" }
end

# Link Factorio Server Ping (Calculates RTT)
################################################################################
def schedule_server_ping
  schedule_servers(:ping) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'ping'))
    server.rcon_command_nonblock(command, method(:ping), Time.now.to_f)
  end
end
