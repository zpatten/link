class Combinators

  module ClassMethods

    @@combinators ||= Hash.new
    @@tx_combinators ||= Hash.new

    def circuit_network_synchronize(network_id, &block)
      @@circuit_network_mutex ||= Hash.new
      @@circuit_network_mutex[network_id] ||= Mutex.new
      @@circuit_network_mutex[network_id].synchronize(&block)
    end

    def extract_circuit_network_id(signals)
      network_id = 0
      signals.each do |signal|
        if (signal["signal"]["name"] == "signal-link-network-id")
          network_id = signal["count"]
          break
        end
      end
      $logger.debug { "Extracted Network ID: #{network_id}" }
      network_id
    end

    def build_signal(name, count, type=nil)
      {
        "signal" => {
          "type" => (type || "virtual"),
          "name" => name
        },
        "count" => count
      }
    end

    def lookup_signal(signals, name)
      return nil if signals.nil?
      signals.each do |signal|
        return signal if (signal["signal"]["name"] == name)
      end

      nil
    end

    def signal_name(signal)
      signal["signal"]["name"]
    end

    def signal_type(signal)
      signal["signal"]["type"]
    end

    def signal_count(signal)
      signal["count"]
    end

    def get_signal(signals, signal_name)
      signals.select { |s| s["signal"]["name"] == signal_name }.first
    end

    def index_signals(signals)
      for i in (1..signals.count) do
        signals[i-1]["index"] = i
      end
      signals
    end

    def scrub_signals(signals, signal_data)
      signals.uniq!
      signals.sort! { |a,b| signal_name(a) <=> signal_name(b) }
      # cleanup and signals we will be inserting
      signals.delete_if do |s|
        signal_data.any? { |n,v| (n == signal_name(s)) }
      end
      # insert specified signals
      signal_data.each do |signal_name, signal_value|
        next if signal_value.nil?
        signal = build_signal(signal_name, signal_value)
        # pp signal
        signals.insert(0, signal)
      end
      signals
    end

    def rcon_lookup_item_type(item_name)
      cache_key = "rcon-item-type-#{item_name}"
      item_type = MemoryCache.fetch(cache_key) do
        command = %(/#{rcon_executor} remote.call('link', 'lookup_item_type', '#{item_name}'))
        Servers.random.rcon_command(command)
      end
    end

    def update_inventory_signals
      signals = Array.new
      Storage.clone.each do |item_name, item_count|
        item_type = rcon_lookup_item_type(item_name)
        signals << build_signal(item_name, item_count, item_type)
      end

      circuit_network_synchronize(:inventory) do
        @@combinators[:inventory] ||= Hash.new
        @@combinators[:inventory][0] = deep_clone(signals)
      end

      signals
    end

    def scrub_network_id(nid)
      (nid == "inventory" ? nid.to_sym : nid.to_i)
    end

    def update_signal(network_id, unit_number, signal)
      circuit_network_synchronize(network_id) do
        @@combinators[network_id] ||= Hash.new
        @@combinators[network_id][unit_number] ||= Array.new
        unit_signals = @@combinators[network_id][unit_number]
        name = signal_name(signal)
        current_count = signal_count(signal)
        if (unit_signal = get_signal(unit_signals, name)).nil?
          # new signal
          unit_signals << build_signal(name, current_count, signal_type(signal))
          $logger.debug(:combinator_tx) { "New Signal: #{name} (#{current_count})" }
        else
          previous_count = signal_count(unit_signal)
          if current_count == 0
            # delete signal
            unit_signals.delete_if { |us| signal_name(us) == name }
            $logger.debug(:combinator_tx) { "Delete Signal: #{name}" }
          elsif previous_count != current_count
            # update signal
            unit_signal["count"] = current_count
            $logger.debug(:combinator_tx) { "Update Signal: #{name} (#{previous_count} -> #{current_count})" }
          end
        end
        IO.write("combinators.json", JSON.pretty_generate(@@combinators))
      end
    end

    def tx(signal_lists, server=nil)
      signal_lists.each do |unit_number, networks|
        networks.each do |network_id, signals|
          network_id = scrub_network_id(network_id)
          # pp signals
          $logger.debug(:combinator_tx) { "Circuit Network ID: #{PP.singleline_pp(network_id, "")}" }
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

          $logger.debug(:combinator_tx) { "Refreshing #{signals.count} signals for circuit network #{network_id}." }

          # pp signals
          signals.each do |signal|
            update_signal(network_id, unit_number, signal)
          end
          # circuit_network_synchronize(network_id) do
          #   @@combinators[network_id] ||= Hash.new
          #   @@combinators[network_id][unit_number] = deep_clone(signals)
          # end
          # pp @@combinators
          signals
        end
      end
    end

    def rx(network_id=0, server=nil)
      Combinators.update_inventory_signals
      network_id = scrub_network_id(network_id)

      $logger.debug(:combinator_rx) { "Circuit Network ID: #{PP.singleline_pp(network_id, "")}" }
      # pp @@combinators
      unit_signals = circuit_network_synchronize(network_id) do
        @@combinators[network_id] ||= Hash.new
        deep_clone(@@combinators[network_id])
        @@combinators[network_id]
      end
      # pp unit_signals
      return [] if unit_signals.nil?

      signal_totals = Hash.new
      signal_types = Hash.new

      unit_signals.each do |unit_number, signals|
        # puts "unit_number: #{unit_number}"
        signals.each do |signal|
          # puts "signals: #{signals.count}"
          signal_totals.merge!(signal_name(signal) => signal_count(signal)) { |k,o,n| o + n }
          signal_types[signal_name(signal)] ||= signal_type(signal)
        end
      end

      # pp signal_totals

      signals = Array.new
      signal_totals.each do |signal_name, count|
        s = build_signal(signal_name, count, signal_types[signal_name])
        # $logger.debug { "Built Signal (network-id:#{network_id}): #{s}" }
        signals << s
      end
      signals

      unless (network_id == :inventory)
        signal_data = {
          "signal-link-epoch" => Time.now.to_i,
          "signal-link-local-id" => server.id,
          "signal-link-network-id" => nil
        }
        signals = scrub_signals(signals, signal_data)
      end

      # index the signals
      signals = index_signals(signals)

      deep_clone(signals)
    end

  end

  extend ClassMethods

end
