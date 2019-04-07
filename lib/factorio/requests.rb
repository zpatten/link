def get_requests(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    requests = JSON.parse(payload)
    unless requests.empty?
      $logger.debug { "[#{server.id}] requests: #{PP.singleline_pp(requests, "")}" }
      Requests.add(host, requests)
    end
  end
end

def fulfillments
  Requests.fulfill do |host,fulfillments|
    s = Servers.find_by_name(host)
    $logger.debug { "[#{s.id}] fulfillments: #{PP.singleline_pp(fulfillments, "")}" }
    command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
    s.rcon_command_nonblock(command, method(:rcon_print))
  end
  Requests.reset
end

# Link Factorio Server Perform Fulfillments and Get New Requests
################################################################################
schedule_servers(:requests) do |servers|
  fulfillments

  command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
  servers.each do |s|
    s.rcon_command_nonblock(command, method(:get_requests))
  end
end
