# frozen_string_literal: true

def get_providables(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.nil? || payload.empty?
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
# def schedule_server_logistics
#   ThreadPool.schedule_servers(:logistics, parallel: false) do |servers|

#     command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
#     servers.each do |server|
#       payload = server.rcon_command(command) #, method(:get_requests))
#       unless payload.nil? || payload.empty?
#         requests = JSON.parse(payload)
#         unless requests.empty?
#           $logger.debug(:requests) { "[#{server.name}] requests: #{requests.ai}" }
#           Requests.add(server.name, requests)
#         end
#       end
#     end

#     Requests.process

#     command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
#     servers.each do |server|
#       server.rcon_command_nonblock(command, method(:get_providables))
#       # payload = server.rcon_command(command) #, method(:get_providables))
#       # unless payload.nil? || payload.empty?
#       #   providables = JSON.parse(payload)
#       #   unless providables.empty?
#       #     $logger.debug(:providables) { "[#{server.name}] providables: #{providables.ai}" }
#       #     providables.each do |item_name, item_count|
#       #       Storage.add(item_name, item_count)
#       #     end
#       #   end
#       # end
#     end

#   end
# end


def schedule_server_logistics
  ThreadPool.schedule_servers(:logistics) do |server|

    command = %(/#{rcon_executor} remote.call('link', 'get_requests'))
    payload = server.rcon_command(command)
    unless payload.nil? || payload.empty?
      requests = JSON.parse(payload)
      unless requests.nil? || requests.empty?
        $logger.debug(:logistics) { "[#{server.name}] requests: #{requests.ai}" }
        logistics = Logistics.new(requests)
        logistics.fulfill do |fulfillments|
          command = %(/#{rcon_executor} remote.call('link', 'set_fulfillments', '#{fulfillments.to_json}'))
          server.rcon_command(command)
        end
      end
    end

    command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
    # server.rcon_command_nonblock(command, method(:get_providables))
    payload = server.rcon_command(command)
    unless payload.nil? || payload.empty?
      providables = JSON.parse(payload)
      unless providables.nil? || providables.empty?
        $logger.debug(:logistics) { "[#{server.name}] providables: #{providables.ai}" }
        providables.each do |item_name, item_count|
          Storage.add(item_name, item_count)
        end
      end
    end

  end
end


# def schedule_server_providables
#   ThreadPool.schedule_servers(:providables) do |server|

#     command = %(/#{rcon_executor} remote.call('link', 'get_providables'))
#     # server.rcon_command_nonblock(command, method(:get_providables))
#     payload = server.rcon_command(command)
#     unless payload.nil? || payload.empty?
#       providables = JSON.parse(payload)
#       unless providables.empty?
#         $logger.debug(:logistics) { "[#{server.name}] providables: #{providables.ai}" }
#         providables.each do |item_name, item_count|
#           Storage.add(item_name, item_count)
#         end
#       end
#     end

#   end
# end
