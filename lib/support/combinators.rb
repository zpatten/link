class Combinators

  module ClassMethods

    @@combinators ||= Hash.new

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

    def signal_name(signal)
      signal["signal"]["name"]
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

    def tx(signal_lists, server=nil)
      signal_lists.each do |unit_number, signals|
        # pp signals
        network_id = extract_circuit_network_id(signals)
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

        circuit_network_synchronize(network_id) do
          @@combinators[network_id] = deep_clone(signals)
        end
        # pp @@combinators
      end
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
        @@combinators[:inventory] = deep_clone(signals)
      end

      signals
    end

    def rx(network_id=0, server=nil)
      Combinators.update_inventory_signals

      $logger.debug { "RX network-id: #{network_id}" }
      # pp @@combinators
      signals = circuit_network_synchronize(network_id) do
        deep_clone(@@combinators[network_id] ||= Array.new)
      end

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
