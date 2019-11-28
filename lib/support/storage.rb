# frozen_string_literal: true

class Storage

  module ClassMethods

    @@storage = Concurrent::Hash.new(0)
    @@storage_delta_history ||= Hash.new { |h,k| h[k] = Array.new }
    @@storage_delta ||= Hash.new(0)
    @@storage_mutex ||= Mutex.new
    @@storage_statistics ||= Hash.new

    def [](item_name)
      self.storage[item_name]
    end

    def storage
      @@storage.nil? and load

      @@storage
    end

    def filename
      File.join(LINK_ROOT, "storage.json")
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
          @@storage.delete_if { |k,v| v == 0 }
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
      deep_clone(self.storage)
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
      self.storage[item_name] += item_count
      Storage.save

      update_websocket(item_name, self.storage[item_name])
      storage_item_instrumentation(item_name, self.storage[item_name])

      item_count
    end

    def bulk_add(items)
      self.storage.merge!(items) { |k,o,n| o + n }
      Storage.save

      true
    end

    def bulk_remove(items)
      self.storage.merge!(items) { |k,o,n| o - n }
      Storage.save

      true
    end

    def remove(item_name, item_count)
      removed_count = if self.storage[item_name] < item_count
        self.storage[item_name]
      else
        item_count
      end
      self.storage[item_name] -= removed_count
      if self.storage[item_name] == 0
        self.storage.delete(item_name)
      end
      Storage.save

      update_websocket(item_name, self.storage[item_name])
      storage_item_instrumentation(item_name, self.storage[item_name])

      removed_count
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
      $logger.debug(:storage) { "Calculating Deltas" }

      @@previous_storage ||= self.clone

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

      @@previous_storage = self.clone

      true
    end

  end

  extend(ClassMethods)
end
