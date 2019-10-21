require_relative "signals/receive"
require_relative "signals/support"
require_relative "signals/transmit"

class Signals
  extend Signals::Receive
  extend Signals::Support
  extend Signals::Transmit
end


# Link Receiver Combinator
################################################################################

$rx_signals_initalized ||= Hash.new
def set_receiver_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    network_ids = JSON.parse(payload)
    unless network_ids.empty?
      $logger.debug(:signals_rx) { "[#{server.id}] Transmitting signals for circuit networks: #{pp_inline(network_ids)}" }

      networks = Hash.new
      network_ids.each do |network_id|
        # signals to transmit to receivers
        network_signals = Signals.tx(network_id, server, true)

        unless network_signals.nil? || network_signals.empty?
          networks[network_id] = network_signals
        end
      end

      if networks.count > 0
        # update rx signals with the signal networks
        force = ($rx_signals_initalized[server.name] != true)
        command = %(/#{rcon_executor} remote.call('link', 'set_receiver_combinator', #{force}, '#{networks.to_json}'))
        server.rcon_command_nonblock(command, method(:rcon_print))
        $rx_signals_initalized[server.name] = true
      end
    end
  end
end

def schedule_server_rx_signals
  schedule_server(:rx_signals) do |server|
    command = %(/#{rcon_executor} remote.call('link', 'get_receiver_combinator_network_ids'))
    server.rcon_command_nonblock(command, method(:set_receiver_combinator))
  end
end


# Link Transmitter Combinator
################################################################################

def get_transmitter_combinator(host, packet_fields, server)
  payload = packet_fields.payload
  unless payload.empty?
    unit_networks_list = JSON.parse(payload)
    unless unit_networks_list.empty?
      if unit_networks_list["noop"].nil?
        network_ids = unit_networks_list.values.map(&:keys).flatten.uniq.sort
        $logger.debug(:combinator_tx) { "[#{server.id}] Received signals for circuit networks: #{pp_inline(network_ids)}" }
        # signals received from transmitters
        Signals.rx(unit_networks_list, server)
      else
        $logger.debug(:combinator_tx) { "[#{server.id}] NOOP" }
        return
      end
    end
  end
end

$tx_signals_initalized ||= Hash.new

def schedule_server_tx_signals
  schedule_server(:tx_signals) do |server|
    command = if $tx_signals_initalized[server.name].nil?
      $tx_signals_initalized[server.name] = true
      %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator', true))
    else
      %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator'))
    end
    server.rcon_command_nonblock(command, method(:get_transmitter_combinator))
  end
end
