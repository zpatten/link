class Combinators

  module ClassMethods

    @@combinators ||= Hash.new

    def extract_network_id(signals)
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
        signal_data.any? { |n,v| (n == s["signal"]["name"]) }
      end
      # insert specified signals
      signal_data.each do |signal_name, signal_value|
        next if signal_value.nil?
        signal = build_signal(signal_name, signal_value)
        signals.insert(0, signal)
      end
      # index the signals
      index_signals(signals)
    end

    def tx(server, signal_lists)
      signal_lists.each do |unit_number, signals|
        # pp signals
        network_id = extract_network_id(signals)
        signal_data = {
          "signal-link-epoch" => nil,
          "signal-link-network-id" => network_id,
          "signal-link-source-id" => server.id
        }
        signals = scrub_signals(signals, signal_data)
        @@combinators[network_id] = signals
        # pp @@combinators
      end
    end

    def rx(server, network_id=0)
      puts "network_id: #{network_id}"
      # pp @@combinators
      signal_data = {
        "signal-link-epoch" => Time.now.to_i,
        "signal-link-local-id" => server.id,
        "signal-link-network-id" => nil
      }
      signals = @@combinators[network_id] ||= Array.new
      scrub_signals(signals, signal_data)
    end

  end

  extend ClassMethods

end
