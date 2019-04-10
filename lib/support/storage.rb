class Storage

  module ClassMethods

    @@storage = nil
    @@storage_mutex ||= Hash.new
    @@storage_statistics ||= Hash.new


    def storage_synchronize(item_name, &block)
      @@storage_mutex[item_name] ||= Mutex.new
      @@storage_mutex[item_name].synchronize(&block)
    end

    def storage_synchronize_all(&block)
      # @@storage_mutex.values.map(&:lock)
      block.call
      # @@storage_mutex.values.map(&:unlock)
    end

    def storage
      @@storage
    end

    def clone_storage
      storage_synchronize_all do
        storage.clone
      end
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
        s.send({ name: item_name, count: item_count }.to_json)
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

      removed_count
    end

    def count(item_name)
      storage.nil? and load

      storage_synchronize(item_name) do
        storage[item_name] ||= 0
      end
    end

    def format_delta_count(delta_count)
      if delta_count > 0
        "+#{delta_count}"
      elsif delta_count == 0
        "-"
      else
        delta_count.to_s
      end
    end

    def delta_averages(item_name, delta_count)
      @@previous_storage_deltas ||= Hash.new { |h,k| h[k] = Array.new }

      @@previous_storage_deltas[item_name] << delta_count

      rindex_15 = [@@previous_storage_deltas[item_name].count, 15].min
      @@previous_storage_deltas[item_name] = @@previous_storage_deltas[item_name][-(rindex_15),15]
      delta_count_15 = format_delta_count(@@previous_storage_deltas[item_name].sum.div(rindex_15))

      rindex_5 = [@@previous_storage_deltas[item_name].count, 5].min
      delta_count_5 = format_delta_count(@@previous_storage_deltas[item_name][-(rindex_5),5].sum.div(rindex_5))

      delta_count_1 = format_delta_count(delta_count)

      [delta_count_1, delta_count_5, delta_count_15]
    end

    def statistics
      deep_clone(@@storage_statistics)
    end

    def calculate_statistics
      storage.nil? and load

      storage_synchronize_all do
        @@previous_storage ||= storage.clone  # first run

        storage_delta = Hash.new

        storage.each do |item_name, item_count|
          count_delta = (storage[item_name] - (@@previous_storage[item_name] || 0))
          storage_delta[item_name] = count_delta
        end

        @@previous_storage = storage.clone

        if storage_delta.keys.count > 0

          storage_delta.each do |item_name, delta_count|
            storage_count = storage[item_name]
            delta_count_1, delta_count_5, delta_count_15 = delta_averages(item_name, delta_count)
            next if delta_count_15 == "-" && storage_count == 0

            @@storage_statistics[item_name] = OpenStruct.new(
              delta_count: delta_count,
              delta_count_1: delta_count_1,
              delta_count_5: delta_count_5,
              delta_count_15: delta_count_15
            )
          end
        end
      end

      @@storage_statistics
    end

  end

  extend(ClassMethods)
end
