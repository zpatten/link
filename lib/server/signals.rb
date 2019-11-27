# frozen_string_literal: true

# Link Combinators
################################################################################
class Server
  module Signals

    def handle_transmitter_combinators(unit_network_list)
      if unit_network_list["noop"].nil?
        network_ids = unit_network_list.values.map(&:keys).flatten.uniq.sort
        $logger.debug(:combinator_tx) { "[#{self.name}] Received signals for circuit networks: #{network_ids.ai}" }
        # signals received from transmitters
        self.method_proxy(
          :Signals,
          :rx,
          unit_network_list,
          server_id: self.network_id
        )
        @tx_signals_initalized = true
      else
        $logger.debug(:combinator_tx) { "[#{self.name}] NOOP" }
      end
    end

    def handle_receiver_combinators(network_ids)
      $logger.debug(:signals_rx) { "[#{self.name}] Transmitting signals for circuit networks: #{network_ids.ai}" }

      force = !@rx_signals_initalized
      networks = Hash.new
      network_ids.each do |network_id|
        # signals to transmit to receivers
        network_signals = self.method_proxy(
          :Signals,
          :tx,
          network_id,
          server_id: self.network_id,
          force: force
        )
        unless network_signals.nil? || network_signals.empty?
          networks[network_id] = network_signals
        end
      end

      if networks.count > 0
        # update rx signals with the signal networks
        command = %(/#{rcon_executor} remote.call('link', 'set_receiver_combinator', #{force}, '#{networks.to_json}'))
        self.rcon_command(command: command)
        @rx_signals_initalized = true
      end
    end

    def schedule_signals
      ThreadPool.schedule_server(:signals, server: self) do
        force = !@tx_signals_initalized
        command = %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator', #{force}))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          unit_network_list = JSON.parse(payload)
          unless unit_network_list.nil? || unit_network_list.empty?
            handle_transmitter_combinators(unit_network_list)
          end
        end

        command = %(/#{rcon_executor} remote.call('link', 'get_receiver_combinator_network_ids'))
        payload = self.rcon_command(command: command)
        unless payload.nil? || payload.empty?
          network_ids = JSON.parse(payload)
          unless network_ids.nil? || network_ids.empty?
            handle_receiver_combinators(network_ids)
          end
        end
      end
    end

  end
end

