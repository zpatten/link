class Signals
  module Receive

    def update_signal(network_id, unit_number, signal)
      circuit_network_synchronize(network_id) do
        signal_networks[network_id] ||= Hash.new
        signal_networks[network_id][unit_number] ||= Array.new

        unit_signals = signal_networks[network_id][unit_number]

        name = signal_name(signal)
        current_count = signal_count(signal)
        if (unit_signal = get_signal(unit_signals, name)).nil?
          return false if current_count == 0
          # new signal
          unit_signals << build_signal(name, current_count, signal_type(signal))
          $logger.debug(:signals_rx) { "Create Signal: #{name} (#{current_count})" }
        else
          previous_count = signal_count(unit_signal)
          if current_count == 0
            # delete signal
            unit_signals.delete_if { |us| signal_name(us) == name }
            $logger.debug(:signals_rx) { "Delete Signal: #{name}" }
          elsif previous_count != current_count
            # update signal
            unit_signal["count"] = current_count
            $logger.debug(:signals_rx) { "Update Signal: #{name} (#{previous_count} -> #{current_count})" }
          end
        end
      end

      true
    end

    def update_signals(network_id, unit_number, signals)
      $logger.debug(:signals_rx) { "Refreshing #{signals.count} signals for circuit network #{network_id}." }

      signals.each do |signal|
        update_signal(network_id, unit_number, signal)
      end

      true
    end

    def rx(signal_lists, server=nil)
      signal_lists.each do |unit_number, networks|
        networks.each do |network_id, signals|
          network_id = scrub_network_id(network_id)
          $logger.debug(:signals_rx) { "Processing Circuit Network ID: #{pp_inline(network_id)}" }

          # scrub the signals
          unless (network_id == :inventory)
            signal_data = {
              "signal-link-epoch" => nil,
              "signal-link-network-id" => network_id,
              "signal-link-source-id" => server.id
            }
            signals = scrub_signals(signals, signal_data)
          end

          # index the signals
          signals = index_signals(signals)

          # update the signals
          update_signals(network_id, unit_number, signals)

          # IO.write("signals.json", JSON.pretty_generate(signal_networks))

          signals
        end
      end
    end

  end
end

