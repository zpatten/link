# frozen_string_literal: true

class Server
  module Signals

=begin
    require_relative "signals/receive"
    require_relative "signals/support"
    require_relative "signals/transmit"

    class Signals
      extend Signals::Receive
      extend Signals::Support
      extend Signals::Transmit
    end
=end

    $rx_signals_initalized ||= Hash.new
    $tx_signals_initalized ||= Hash.new

    # Link Receiver Combinator
    ################################################################################

    def set_receiver_combinator(host, packet_fields, server)
      payload = packet_fields.payload
      unless payload.nil? || payload.empty?
        network_ids = JSON.parse(payload)
        unless network_ids.empty?
          $logger.debug(:signals_rx) { "[#{server.id}] Transmitting signals for circuit networks: #{network_ids.ai}" }

          force = !$rx_signals_initalized[server.name]
          networks = Hash.new
          network_ids.each do |network_id|
            # signals to transmit to receivers
            network_signals = Signals.tx(network_id, server, force)

            unless network_signals.nil? || network_signals.empty?
              networks[network_id] = network_signals
            end
          end

          if networks.count > 0
            # update rx signals with the signal networks
            command = %(/#{rcon_executor} remote.call('link', 'set_receiver_combinator', #{force}, '#{networks.to_json}'))
            server.rcon_command_nonblock(command, method(:rcon_print))
            $rx_signals_initalized[server.name] = true
          end
        end
      end
    end


    # Link Transmitter Combinator
    ################################################################################

    def get_transmitter_combinator(host, packet_fields, server)
      payload = packet_fields.payload
      unless payload.nil? || payload.empty?
        unit_networks_list = JSON.parse(payload)
        unless unit_networks_list.empty?
          if unit_networks_list["noop"].nil?
            network_ids = unit_networks_list.values.map(&:keys).flatten.uniq.sort
            $logger.debug(:combinator_tx) { "[#{server.id}] Received signals for circuit networks: #{network_ids.ai}" }
            # signals received from transmitters
            Signals.rx(unit_networks_list, server)
          else
            $logger.debug(:combinator_tx) { "[#{server.id}] NOOP" }
          end
        end
      end
    end


    # def schedule_server_tx_signals
    def schedule_server_signals
      ThreadPool.schedule_servers(:signals) do |server|
        force = !$tx_signals_initalized[server.name]
        command = %(/#{rcon_executor} remote.call('link', 'get_transmitter_combinator', #{force}))
        server.rcon_command_nonblock(command, method(:get_transmitter_combinator))
        $tx_signals_initalized[server.name] = true

        command = %(/#{rcon_executor} remote.call('link', 'get_receiver_combinator_network_ids'))
        server.rcon_command_nonblock(command, method(:set_receiver_combinator))
      end
    end

  end
end

