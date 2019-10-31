# frozen_string_literal: true

def get_providables(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    providables = JSON.parse(payload)
    unless providables.empty?
      $logger.debug(:providables) { "[#{server.name}] providables: #{providables.ai}" }
      providables.each do |item_name, item_count|
        Storage.add(item_name, item_count)
      end
    end
  end
end


# Link Factorio Server Perform Fulfillments and Get New Requests
################################################################################
def schedule_server_logistics
  ThreadPool.schedule_servers(:logistics, parallel: false) do |servers|

    command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
    servers.each do |server|
      payload = server.rcon_command(command) #, method(:get_requests))
      unless payload.empty?
        requests = JSON.parse(payload)
        unless requests.empty?
          # $logger.info(:requests) { "[#{server.name}] requests: #{requests.ai}" }
          Requests.add(server.name, requests)
        end
      end
    end

    Requests.process

    command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
    servers.each do |server|
      server.rcon_command_nonblock(command, method(:get_providables))
    end

  end
end

