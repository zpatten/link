# Link Factorio Server ID
################################################################################
schedule_server(:id) do |server|
  command = %(/#{rcon_executor} remote.call('link', 'set_id', '#{server.id}'))
  server.rcon_command(command, method(:rcon_print))
end
