# frozen_string_literal: true

def get_providables(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    providables = JSON.parse(payload)
    unless providables.empty?
      $logger.info(:providables) { "[#{server.id}] providables: #{providables.ai}" }
      providables.each do |item_name, item_count|
        Storage.add(item_name, item_count)
      end
    end
  end
end

def get_requests(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    requests = JSON.parse(payload)
    unless requests.empty?
      $logger.info(:requests) { "[#{server.id}] requests: #{requests.ai}" }
      Requests.add(host, requests)
    end
  end
end

def fulfillments
  Requests.fulfill do |host,fulfillments|
    s = Servers.find_by_name(host)
    $logger.info(:fulfillments) { "[#{s.id}] fulfillments: #{fulfillments.ai}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
    s.rcon_command_nonblock(command, method(:rcon_print))
  end
  Requests.reset
end

# Link Factorio Server Perform Fulfillments and Get New Requests
################################################################################
def schedule_server_logistics
  schedule_servers(:logistics, parallel: false) do |servers|
    command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
    servers.each do |server|
      server.rcon_command_nonblock(command, method(:get_providables))
    end

    command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
    servers.each do |server|
      server.rcon_command_nonblock(command, method(:get_requests))
    end

    fulfillments
  end
end

