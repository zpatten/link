# frozen_string_literal: true

class Storage

  module ClassMethods

    @@storage = nil
    @@storage_delta_history ||= Hash.new { |h,k| h[k] = Array.new }
    @@storage_delta ||= Hash.new(0)
    @@storage_mutex ||= Hash.new
    @@storage_statistics ||= Hash.new

    def storage_synchronize(item_name, &block)
      @@storage_mutex[item_name] ||= Mutex.new
      @@storage_mutex[item_name].synchronize(&block)
    end

    def storage_synchronize_all(&block)
      @@storage_mutex.values.map(&:lock)
      block.call
      @@storage_mutex.values.map(&:unlock)
    end

    def storage
      @@storage
    end

    def filename
      File.join(Dir.pwd, "storage.json")
    end

    def load
      storage_synchronize_all do
        @@storage = (JSON.parse(IO.read(filename)) rescue Hash.new)
      end
    end

    def save
      storage_synchronize_all do
        @@storage.nil? or IO.write(filename, JSON.pretty_generate(storage))
      end
    end

    def storage_item_instrumentation(item_name, item_count)
      $storage_item_count.set(item_count, labels: { name: item_name })
    end

    def clone
      storage.nil? and load

      storage_clone = nil
      storage_synchronize_all do
        storage_clone = deep_clone(storage)
      end
      storage_clone.delete_if { |n,c| (c == 0) }
    end

    def update_websocket(item_name, item_count)
      WebServer.settings.storage_sockets.each do |s|
        s.send({
          name: item_name,
          count: item_count,
          delta: delta[item_name]
        }.to_json)
      end
    end

    def add(item_name, item_count)
      storage.nil? and load

      storage_synchronize(item_name) do
        storage[item_name] ||= 0
        storage[item_name] += item_count
      end

      Signals.update_inventory_signals
      update_websocket(item_name, storage[item_name])
      storage_item_instrumentation(item_name, storage[item_name])

      item_count
    end

    def remove(item_name, item_count)
      storage.nil? and load

      removed_count = 0
      storage_synchronize(item_name) do
        storage[item_name] ||= 0

        removed_count = if storage[item_name] < item_count
          storage[item_name]
        else
          item_count
        end
        storage[item_name] -= removed_count
      end

      Signals.update_inventory_signals
      update_websocket(item_name, storage[item_name])
      storage_item_instrumentation(item_name, storage[item_name])

      removed_count
    end

    def count(item_name)
      storage.nil? and load

      storage_synchronize(item_name) do
        storage[item_name] ||= 0
      end
    end

    def format_delta_count(delta_count)
      if delta_count.nil?
        '-'
      elsif delta_count > 0
        "+#{delta_count}"
      elsif delta_count == 0
        '0'
      else
        delta_count.to_s
      end
    end

    def delta
      @@storage_delta
    end

    def calculate_delta
      storage.nil? and load
      $logger.debug(:storage) { "Calculating Deltas" }

      storage_synchronize_all do
        @@previous_storage ||= deep_clone(@@storage)  # first run

        @@storage.keys.each do |item_name|
          count_delta = (@@storage[item_name] - (@@previous_storage[item_name] || 0))
          @@storage_delta_history[item_name] << count_delta
          delta_count = [@@storage_delta_history[item_name].size, 60].min
          @@storage_delta_history[item_name] = @@storage_delta_history[item_name][-delta_count, delta_count]
          @@storage_delta[item_name] = format_delta_count(@@storage_delta_history[item_name].sum.div(@@storage_delta_history[item_name].size))
        end

        @@previous_storage = deep_clone(@@storage)
      end

      true
    end

  end

  extend(ClassMethods)
end
