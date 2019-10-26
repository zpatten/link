# frozen_string_literal: true

def get_providables(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    providables = JSON.parse(payload)
    unless providables.empty?
      $logger.info(:providables) { "[#{server.name}] providables: #{providables.ai}" }
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
      $logger.info(:requests) { "[#{server.name}] requests: #{requests.ai}" }
      Requests.add(host, requests)
    end
  end
end

def fulfillments
  Requests.fulfill do |host,fulfillments|
    server = Servers.find_by_name(host)
    $logger.info(:fulfillments) { "[#{server.name}] fulfillments: #{fulfillments.ai}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
    server.rcon_command_nonblock(command, method(:rcon_print))
  end
end

# Link Factorio Server Perform Fulfillments and Get New Requests
################################################################################
def schedule_server_logistics
  schedule_servers(:logistics, parallel: false) do |servers|

    command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
    servers.each do |server|
      server.rcon_command_nonblock(command, method(:get_providables))
    end

    # command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
    # $logger.info { "servers.count=#{servers.count}" }
    # servers.each do |server|
    #   $logger.info { "server=#{server.name}" }
    #   server.rcon_command_nonblock(command, method(:get_requests))
    # end

    command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
    $logger.info { "servers.count=#{servers.count}" }
    servers.each do |server|
      $logger.info { "server=#{server.name}" }
      payload = server.rcon_command(command) #, method(:get_requests))
      unless payload.empty?
        requests = JSON.parse(payload)
        unless requests.empty?
          $logger.info(:requests) { "[#{server.name}] requests: #{requests.ai}" }
          Requests.add(server.name, requests)
        end
      end
    end

    fulfillments
    Requests.reset
  end
end

