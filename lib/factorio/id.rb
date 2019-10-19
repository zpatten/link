# Link Factorio Server ID
################################################################################
def schedule_server_id
  schedule_server(:id) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'set_id', '#{server.id}'))
    server.rcon_command_nonblock(command, method(:rcon_print))
  end
end
