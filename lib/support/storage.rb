# frozen_string_literal: true

class Storage

  module ClassMethods

    @@storage = Concurrent::Hash.new(0) #Hash.new(0)
    @@storage_delta_history ||= Hash.new { |h,k| h[k] = Array.new }
    @@storage_delta ||= Hash.new(0)
    @@storage_mutex ||= Mutex.new
    # @@storage_item_mutex ||= Hash.new
    @@storage_statistics ||= Hash.new

    # def storage_item_synchronize(item_name, &block)
    #   @@storage_item_mutex[item_name] ||= Mutex.new
    #   @@storage_item_mutex[item_name].synchronize(&block)
    # end

    # def storage_items_synchronize(item_names, &block)
    #   item_names.each do |item_name|
    #     @@storage_item_mutex[item_name] ||= Mutex.new
    #     @@storage_item_mutex[item_name].lock
    #   end

    #   block.call

    #   item_names.each do |item_name|
    #     @@storage_item_mutex[item_name].unlock
    #   end

    #   true
    # end

    # def storage_synchronize_all(&block)
    #   @@storage_global_mutex.synchronize(&block)
    # end

    def [](item_name)
      # @@storage.nil? and load

      self.storage[item_name]
    end

    # def []=(item_name, item_count)
    #   # @@storage.nil? and load

    #   self.storage[item_name] = item_count
    # end

    def storage
      @@storage.nil? and load

      @@storage
    end

    def filename
      File.join(Dir.pwd, "storage.json")
    end

    def load
      @@storage_mutex.synchronize do
        h = (JSON.parse(IO.read(filename)) rescue Hash.new)
        @@storage.merge!(h)
      end
    end

    def save
      # pid = Process.fork do
      unless @@storage.nil?
        @@storage_mutex.synchronize do
          # @@storage.delete_if { |k,v| v == 0 }
          IO.write(filename, JSON.pretty_generate(@@storage.sort.to_h))
        end
      end
      # end
      # Process.detach(pid)
    end

    def storage_item_instrumentation(item_name, item_count)
      if item_name == 'electricity'
        Metrics[:electrical_count].set(item_count, labels: { name: item_name })
      else
        Metrics[:storage_item_count].set(item_count, labels: { name: item_name })
      end
    end

    def storage_delta_instrumentation(item_name, item_count)
      if item_name == 'electricity'
        Metrics[:electrical_delta_count].set(item_count, labels: { name: item_name })
      else
        Metrics[:storage_delta_count].set(item_count, labels: { name: item_name })
      end
    end

    def clone
      # storage.nil? and load

      # storage_clone = nil
      # @@storage_mutex.synchronize do
      deep_clone(self.storage)
      # end
      # storage_synchronize_all do
      #   storage_clone = deep_clone(storage)
      # end
      # storage_clone.delete_if { |n,c| (c == 0) }
    end

    def update_websocket(item_name, item_count)
      ::WebServer.settings.storage_sockets.each do |s|
        s.send({
          name: item_name,
          count: countsize(item_count),
          delta_s: delta[item_name][0],
          delta_m: delta[item_name][1]
        }.to_json)
      end
    end

    def add(item_name, item_count)
      # storage.nil? and load

      # @@storage_mutex.synchronize do
      #   storage[item_name] ||= 0
      #   storage[item_name] += item_count
      # end
      # storage_item_synchronize(item_name) do
        self.storage[item_name] += item_count
      # end
      Storage.save

      # $logger.info(:storage) { "#{item_name}: +#{item_count}" }

      # storage_synchronize(item_name) do
      #   storage[item_name] ||= 0
      #   storage[item_name] += item_count
      # end

      # Signals.update_inventory_signals
      update_websocket(item_name, self.storage[item_name])
      storage_item_instrumentation(item_name, self.storage[item_name])

      # Storage.save

      item_count
    end

    def bulk_add(items)
      self.storage.merge!(items) { |k,o,n| o + n }
      Storage.save

      true
    end

    def bulk_remove(items)
      # storage_items_synchronize(items.keys) do
      self.storage.merge!(items) { |k,o,n| o - n }
      # end
      Storage.save

      true
    end

    def remove(item_name, item_count)
      # storage.nil? and load

      removed_count = 0
      # storage_item_synchronize(item_name) do
        removed_count = if self.storage[item_name] < item_count
          self.storage[item_name]
        else
          item_count
        end
        self.storage[item_name] -= removed_count
        if self.storage[item_name] == 0
          self.storage.delete(item_name)
        end
      # end
      Storage.save

      # @@storage_mutex.synchronize do
      #   storage[item_name] ||= 0

      #   removed_count = if storage[item_name] < item_count
      #     storage[item_name]
      #   else
      #     item_count
      #   end
      #   storage[item_name] -= removed_count
      # end



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

      # Signals.update_inventory_signals
      update_websocket(item_name, self.storage[item_name])
      storage_item_instrumentation(item_name, self.storage[item_name])

      # Storage.save

      removed_count
    end

    # def count(item_name)
    #   storage.nil? and load

    #   @@storage_mutex.synchronize do
    #     storage[item_name] ||= 0
    #   end
    #   # storage_synchronize(item_name) do
    #   #   storage[item_name] ||= 0
    #   # end
    # end

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
      $logger.debug(:storage) { "Calculating Deltas" }

      # @@storage_mutex.synchronize do
        @@previous_storage ||= self.clone #deep_clone(self.storage)  # first run

        self.storage.keys.each do |item_name|
          count_delta = (self.storage[item_name] - (@@previous_storage[item_name] || 0))
          @@storage_delta_history[item_name] << count_delta
          delta_counts = [@@storage_delta_history[item_name].size, 60].min

          @@storage_delta_history[item_name] = @@storage_delta_history[item_name][-delta_counts, delta_counts]

          sec_rate = @@storage_delta_history[item_name].map(&:to_f).sum / @@storage_delta_history[item_name].size
          min_rate = @@storage_delta_history[item_name].sum

          @@storage_delta[item_name] = [
            format_delta_count(sec_rate),
            format_delta_count(min_rate)
          ]

          storage_delta_instrumentation(item_name, sec_rate)
        end

        @@previous_storage = self.clone #deep_clone(@@storage)
      # end
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
