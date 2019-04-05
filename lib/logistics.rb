def get_providables(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    providables = JSON.parse(payload)
    unless providables.empty?
      $logger.debug { "PROVIDABLES[#{host}]: #{PP.singleline_pp(providables, "")}" }
      providables.each do |item_name, item_count|
        Storage.add(item_name, item_count)
      end
    end
  end
end

def get_requests(host, packet_fields, data)
  payload = packet_fields.payload
  unless payload.empty?
    requests = JSON.parse(payload)
    unless requests.empty?
      $logger.debug { "REQUESTS[#{host}]: #{PP.singleline_pp(requests, "")}" }
      Requests.add(host, requests)
    end
  end
end

def fulfillments
  Requests.fulfill do |host,fulfillments|
    $logger.debug { "FULFILLMENTS[#{host}]: #{PP.singleline_pp(fulfillments, "")}" }
    s = Servers.find_by_name(host)
    command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
    s.rcon_command(command, method(:rcon_print))
  end
  Requests.reset
end
