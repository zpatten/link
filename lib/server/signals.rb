# frozen_string_literal: true

# Link Combinators
################################################################################
class Server
  module Signals

    def handle_transmitter_combinators(unit_network_list)
      if unit_network_list["noop"].nil?
        network_ids = unit_network_list.values.map(&:keys).flatten.uniq.sort
        LinkLogger.debug(:combinator_tx) { "[#{self.name}] Received signals for circuit networks: #{network_ids.ai}" }
        # signals received from transmitters
        ::Signals.rx(unit_network_list, server_id: self.network_id)
        @tx_signals_initalized = true
      else
        LinkLogger.debug(:combinator_tx) { "[#{self.name}] NOOP" }
      end
    end

    def handle_receiver_combinators(network_ids)
      LinkLogger.debug(:signals_rx) { "[#{self.name}] Transmitting signals for circuit networks: #{network_ids.ai}" }

      force = !@rx_signals_initalized
      networks = Hash.new
      network_ids.each do |network_id|
        # signals to transmit to receivers
        network_signals = ::Signals.tx(network_id, server_id: self.network_id, force: force)
        unless network_signals.nil? || network_signals.empty?
          networks[network_id] = network_signals
        end
      end

      if networks.count > 0
        # update rx signals with the signal networks
        command = %(remote.call('link', 'set_receiver_combinator', #{force}, '#{networks.to_json}'))
        rcon_command_nonblock(command)
        @rx_signals_initalized = true
      end
    end

    def schedule_task_signals
      Tasks.schedule(what: :signals, pool: @pool, cancellation: @cancellation, server: self) do
        force = !@tx_signals_initalized
        command = %(remote.call('link', 'get_transmitter_combinator', #{force}))
        rcon_handler(what: :get_transmitter_combinator, command: command) do |unit_network_list|
          handle_transmitter_combinators(unit_network_list)
        end

        command = %(remote.call('link', 'get_receiver_combinator_network_ids'))
        rcon_handler(what: :get_receiver_combinator_network_ids, command: command) do |network_ids|
          handle_receiver_combinators(network_ids)
        end
      end
    end

  end
end

