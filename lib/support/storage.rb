# frozen_string_literal: true

class Storage

  module ClassMethods

    @@storage = nil
    @@storage_delta_history ||= Hash.new { |h,k| h[k] = Array.new }
    @@storage_delta ||= Hash.new(0)
    @@storage_mutex ||= Mutex.new
    @@storage_statistics ||= Hash.new

    def storage_synchronize(item_name, &block)
      @@storage_mutex[item_name] ||= Mutex.new
      @@storage_mutex[item_name].synchronize(&block)
    end

    def storage_synchronize_all(&block)
      @@storage_global_mutex.synchronize(&block)
    end

    def [](item_name)
      @@storage[item_name]
    end

    def storage
      @@storage
    end

    def filename
      File.join(Dir.pwd, "storage.json")
    end

    def load
      @@storage_mutex.synchronize do
        @@storage = (JSON.parse(IO.read(filename)) rescue Hash.new)
      end
    end

    def save
      # pid = Process.fork do
      unless @@storage.nil?
        @@storage_mutex.synchronize do
          @@storage.delete_if { |k,v| v == 0 }
          IO.write(filename, JSON.pretty_generate(@@storage.sort.to_h))
        end
      end
      # end
      # Process.detach(pid)
    end

    def storage_item_instrumentation(item_name, item_count)
      if item_name == 'electricity'
        $electrical_count.set(item_count, labels: { name: item_name })
      else
        $storage_item_count.set(item_count, labels: { name: item_name })
      end
    end

    def storage_delta_instrumentation(item_name, item_count)
      if item_name == 'electricity'
        $electrical_delta_count.set(item_count, labels: { name: item_name })
      else
        $storage_delta_count.set(item_count, labels: { name: item_name })
      end
    end

    def clone
      storage.nil? and load

      storage_clone = nil
      @@storage_mutex.synchronize do
        storage_clone = deep_clone(storage)
      end
      # storage_synchronize_all do
      #   storage_clone = deep_clone(storage)
      # end
      storage_clone.delete_if { |n,c| (c == 0) }
    end

    def update_websocket(item_name, item_count)
      WebServer.settings.storage_sockets.each do |s|
        s.send({
          name: item_name,
          count: countsize(item_count),
          delta_s: delta[item_name][0],
          delta_m: delta[item_name][1]
        }.to_json)
      end
    end

    def add(item_name, item_count)
      storage.nil? and load

      @@storage_mutex.synchronize do
        storage[item_name] ||= 0
        storage[item_name] += item_count
      end
      # $logger.info(:storage) { "#{item_name}: +#{item_count}" }

      # storage_synchronize(item_name) do
      #   storage[item_name] ||= 0
      #   storage[item_name] += item_count
      # end

      Signals.update_inventory_signals
      update_websocket(item_name, storage[item_name])
      storage_item_instrumentation(item_name, storage[item_name])

      Storage.save

      item_count
    end

    def remove(item_name, item_count)
      storage.nil? and load

      removed_count = 0
      @@storage_mutex.synchronize do
        storage[item_name] ||= 0

        removed_count = if storage[item_name] < item_count
          storage[item_name]
        else
          item_count
        end
        storage[item_name] -= removed_count
      end
      # $logger.info(:storage) { "#{item_name}: -#{item_count}" }

      # storage_synchronize(item_name) do
      #   storage[item_name] ||= 0

      #   removed_count = if storage[item_name] < item_count
      #     storage[item_name]
      #   else
      #     item_count
      #   end
      #   storage[item_name] -= removed_count
      # end

      Signals.update_inventory_signals
      update_websocket(item_name, storage[item_name])
      storage_item_instrumentation(item_name, storage[item_name])

      Storage.save

      removed_count
    end

    def count(item_name)
      storage.nil? and load

      @@storage_mutex.synchronize do
        storage[item_name] ||= 0
      end
      # storage_synchronize(item_name) do
      #   storage[item_name] ||= 0
      # end
    end

    def format_delta_count(delta_count)
      if delta_count.nil?
        '-'
      elsif delta_count > 0
        "+#{countsize(delta_count)}"
      elsif delta_count == 0
        '0'
      elsif delta_count < 0
        "-#{countsize(-delta_count)}"
      end
    end

    def delta
      @@storage_delta
    end

    def calculate_delta
      storage.nil? and load
      $logger.debug(:storage) { "Calculating Deltas" }

      @@storage_mutex.synchronize do
        @@previous_storage ||= deep_clone(@@storage)  # first run

        @@storage.keys.each do |item_name|
          count_delta = (@@storage[item_name] - (@@previous_storage[item_name] || 0))
          @@storage_delta_history[item_name] << count_delta
          delta_counts = [@@storage_delta_history[item_name].size, 60].min

          @@storage_delta_history[item_name] = @@storage_delta_history[item_name][-delta_counts, delta_counts]

          sec_rate = @@storage_delta_history[item_name].sum.div(@@storage_delta_history[item_name].size)
          min_rate = @@storage_delta_history[item_name].sum

          @@storage_delta[item_name] = [
            format_delta_count(sec_rate),
            format_delta_count(min_rate)
          ]

          storage_delta_instrumentation(item_name, sec_rate)
        end

        @@previous_storage = deep_clone(@@storage)
      end
      # storage_synchronize_all do
      #   @@previous_storage ||= deep_clone(@@storage)  # first run

      #   @@storage.keys.each do |item_name|
      #     count_delta = (@@storage[item_name] - (@@previous_storage[item_name] || 0))
      #     @@storage_delta_history[item_name] << count_delta
      #     delta_counts = [@@storage_delta_history[item_name].size, 60].min

      #     @@storage_delta_history[item_name] = @@storage_delta_history[item_name][-delta_counts, delta_counts]

      #     sec_rate = @@storage_delta_history[item_name].sum.div(@@storage_delta_history[item_name].size)
      #     min_rate = @@storage_delta_history[item_name].sum

      #     @@storage_delta[item_name] = [
      #       format_delta_count(sec_rate),
      #       format_delta_count(min_rate)
      #     ]

      #     storage_delta_instrumentation(item_name, sec_rate)
      #   end

      #   @@previous_storage = deep_clone(@@storage)
      # end

      true
    end

  end

  extend(ClassMethods)
end
