class Storage

  module ClassMethods

    @@storage = nil
    @@storage_mutex = Mutex.new

    def filename
      File.join(Dir.pwd, "storage.json")
    end

    def load
      @@storage_mutex.synchronize do
        @@storage = (JSON.parse(IO.read(filename)) rescue Hash.new)
      end
    end

    def save
      @@storage_mutex.synchronize do
        @@storage.nil? or IO.write(filename, JSON.pretty_generate(@@storage))
      end
    end

    def add(item_name, item_count)
      @@storage.nil? and load

      @@storage_mutex.synchronize do
        @@storage[item_name] ||= 0
        @@storage[item_name] += item_count
      end

      item_count
    end

    def clone
      @@storage.nil? and load

      storage_clone = nil
      @@storage_mutex.synchronize do
        storage_clone = @@storage.clone
      end
      storage_clone.delete_if { |n,c| (c == 0) }
    end

    def remove(item_name, item_count)
      @@storage.nil? and load

      removed_count = 0
      @@storage_mutex.synchronize do
        @@storage[item_name] ||= 0

        removed_count = if @@storage[item_name] < item_count
          @@storage[item_name]
        else
          item_count
        end
        @@storage[item_name] -= removed_count
      end

      removed_count
    end

    def count(item_name)
      @@storage.nil? and load

      @@storage_mutex.synchronize do
        @@storage[item_name] ||= 0
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

    def delta
      @@storage.nil? and load

      @@storage_mutex.synchronize do
        @@previous_storage ||= @@storage.clone  # first run

        storage_delta = Hash.new

        @@storage.each do |item_name, item_count|
          count_delta = (@@storage[item_name] - (@@previous_storage[item_name] || 0))
          storage_delta[item_name] = count_delta
        end

        @@previous_storage = @@storage.clone

        if storage_delta.keys.count > 0
          # puts ("-" * 80)
          # puts "  Storage Delta: "
          # puts ("-" * 80)
          $logger.info { "-----------------------------------------+----------+----------+----------+----------------" }
          $logger.info { " STORAGE REPORT                Item Name | Delta-1  | Delta-5  | Delta-15 | In Storage" }
          $logger.info { "-----------------------------------------+----------+----------+----------+----------------" }
          storage_delta.each do |item_name, delta_count|

            storage_count = @@storage[item_name]
            delta_count_1, delta_count_5, delta_count_15 = delta_averages(item_name, delta_count)
            next if delta_count_15 == "-" && storage_count == 0

            $logger.info { "%40s | %-8s | %-8s | %-8s | %-8s" % [item_name, delta_count_1, delta_count_5, delta_count_15, storage_count] }
          end
        end
      end
    end

  end

  extend(ClassMethods)
end
