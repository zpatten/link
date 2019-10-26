# frozen_string_literal: true

class Signals
  module Transmit

    def calculate_signals(network_id)
      signals = Array.new
      network_signals = self.clone(network_id)

      unless network_signals.nil? || network_signals.empty?
        # pp network_signals
        total_signals = network_signals.values.flatten.count
        total_units = network_signals.keys.count

        $logger.debug(:signals_tx) { "Calculating #{total_signals} signals from #{total_units} entities for network-id #{network_id}." }

        signal_totals = Hash.new
        signal_types = Hash.new

        network_signals.each do |unit_number, unit_signals|
          ###
          unit_signals.each do |unit_signal|
            signal_totals.merge!(signal_name(unit_signal) => signal_count(unit_signal)) { |k,o,n| o + n }
            signal_types[signal_name(unit_signal)] ||= signal_type(unit_signal)
          end
        end

        signal_totals.each do |signal_name, count|
          s = build_signal(signal_name, count, signal_types[signal_name])
          signals << s
        end
        $logger.debug(:signals_tx) { "Calculated #{signals.count} signals for network-id #{network_id}." }

      else
        $logger.warn(:signals_tx) { "No signals exist for network-id #{pp_inline(network_id)}!" }
      end

      signals
    end

    def tx(network_id=0, server=nil, force=false)
      Signals.update_inventory_signals
      network_id = scrub_network_id(network_id)


      $logger.debug(:signals_tx) { "Processing Circuit Network ID: #{pp_inline(network_id)}" }

      current_signals = calculate_signals(network_id)

      unless (network_id == :inventory)
        signal_data = {
          "signal-link-epoch" => Time.now.to_i,
          "signal-link-local-id" => server.network_id,
          "signal-link-network-id" => nil
        }
        current_signals = scrub_signals(current_signals, signal_data)
      end

      # index the signals
      current_signals = index_signals(current_signals)

      cache_key = [ "signals-tx-previous", server.name, network_id ].compact.join("-")
      previous_signals = MemoryCache.read(cache_key)
      network_signals = Array.new
      if !!previous_signals && !force

        if (current_signals != previous_signals)
          current_signals_map = build_signal_hash_map(current_signals)
          previous_signals_map = build_signal_hash_map(previous_signals)

          # look for new or changed signals
          current_signals.each do |current_signal|
            previous_signal = previous_signals_map[signal_name(current_signal)]

            if previous_signal.nil? # || not initalized
              $logger.debug(:signals_tx) { "Create Signal: #{signal_name(current_signal)} (#{signal_count(current_signal)})" }
              network_signals << current_signal
            else
              count_changed = (signal_count(previous_signal) != signal_count(current_signal))
              index_changed = (signal_count(previous_signal) != signal_count(current_signal))
              if count_changed
                $logger.debug(:signals_tx) { "Update Signal: #{signal_name(current_signal)} count:(#{signal_count(previous_signal)} -> #{signal_count(current_signal)})" }
                network_signals << current_signal
              elsif index_changed
                $logger.debug(:signals_tx) { "Update Signal: #{signal_name(current_signal)} index:(#{signal_index(previous_signal)} -> #{signal_index(current_signal)})" }
                network_signals << current_signal
              else
                # Unchanged
              end
            end
          end

          # look for deleted signals
          previous_signals.each do |previous_signal|
            current_signal = current_signals_map[signal_name(previous_signal)]
            if current_signal.nil?
              $logger.debug(:signals_tx) { "Delete Signal: #{signal_name(previous_signal)}" }
              previous_signal["count"] = 0
              network_signals << previous_signal
            end
          end

        else
          $logger.debug(:signals_tx) { "No signal changes detected for network-id #{network_id}." }
        end
      else
        $logger.debug(:signals_tx) { "No previous signal state for network-id #{network_id}; emitting all signals." }
        network_signals = current_signals
      end

      signals = if network_signals.count == 0
        nil  # NOOP
      else
        network_signals
      end

      MemoryCache.write(cache_key, current_signals)

      deep_clone(signals)
    end


  end
end
