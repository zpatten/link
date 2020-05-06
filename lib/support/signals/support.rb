# frozen_string_literal: true

class Link
  class Signals
    module Support

      # def circuit_network_synchronize(network_id, &block)
      #   @@circuit_network_mutex ||= Hash.new
      #   @@circuit_network_mutex[network_id] ||= Mutex.new
      #   @@circuit_network_mutex[network_id].synchronize(&block)
      # end

      def signal_networks
        @@signal_networks ||= Concurrent::Hash.new
      end

      def extract_circuit_network_id(signals)
        network_id = 0
        signals.each do |signal|
          if (signal["signal"]["name"] == "link-signal-network-id")
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
          "count" => (count > INT_32_MAX ? INT_32_MAX : count)
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

      def signal_index(signal)
        signal["index"]
      end

      def get_signal(signals, signal_name)
        signals.find { |s| s["signal"]["name"] == signal_name }
      end

      def sort_signals!(signals)
        signals.sort! { |a,b| signal_name(a) <=> signal_name(b) }
      end

      def index_signals(signals)
        sort_signals!(signals)
        for i in (1..signals.count) do
          signals[i-1]["index"] = i
        end
        signals
      end

      def lookup_signal(signals, name)
        return nil if signals.nil?
        signals.each do |signal|
          return signal if (signal["signal"]["name"] == name)
        end

        nil
      end

      def build_signal_hash_map(signals)
        hash_map = Hash.new
        return hash_map if signals.nil? || signals.empty?
        signals.each do |signal|
          hash_map[signal_name(signal)] = signal
        end
        hash_map
      end

      def scrub_signals(signals, signal_data)
        signals = Array.new if signals.empty?

        signals.uniq!
        sort_signals!(signals)
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

      def update_inventory_signals
        signals = Array.new
        Storage.clone.each do |item_name, item_count|
          item_name = 'link-signal-electricity' if item_name == 'electricity'
          item_type = ItemType[item_name]
          if item_name == 'link-signal-electricity'
            item_count = item_count.div(GIGAJOULE)
          end

          signals << build_signal(item_name, item_count, item_type)
        end

        # circuit_network_synchronize(:inventory) do
          signal_networks[:inventory] ||= Concurrent::Hash.new
          signal_networks[:inventory][0] = Link.deep_clone(signals)
        # end

        signals
      end

      def scrub_network_id(nid)
        return nid if nid.is_a?(Symbol)
        (nid == "inventory" ? nid.to_sym : nid.to_i)
      end

      def get_network_ids
        Link.deep_clone(signal_networks.keys)
      end

      def clone(network_id)
        # circuit_network_synchronize(network_id) do
          Link.deep_clone(signal_networks[network_id])
        # end
      end

      # def clone_all
      #   networks = Hash.new
      #   get_network_ids.each do |nid|
      #     # circuit_network_synchronize(nid) do
      #     network_signals = begin
      #       signals = deep_clone(signal_networks[nid])
      #       if signals.nil? || signals.empty?
      #         {}
      #       else
      #         { nid => signals }
      #       end
      #     end
      #     # end)
      #     networks.merge!(network_signals)
      #   end
      # end

    end
  end
end
