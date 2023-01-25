# frozen_string_literal: true

class Storage

  module ClassMethods

################################################################################

    @@storage ||= Concurrent::Hash.new
    @@storage_delta_history ||= Hash.new { |h,k| h[k] = Array.new }
    @@storage_delta ||= Hash.new(0)
    @@storage_mutex ||= Mutex.new
    @@storage_statistics ||= Hash.new

################################################################################

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

################################################################################

    def load
      @@storage_mutex.synchronize do
        h = (JSON.parse(IO.read(filename)) rescue Hash.new)
        puts h.ai
        h.transform_values! do |v|
          puts v.ai
          Concurrent::AtomicFixnum.new(v)
        end
        @@storage.merge!(h)
      end
    end

    def save
      unless @@storage.nil?
        @@storage_mutex.synchronize do
          h = Hash.new
          @@storage.each do |k,v|
            h[k] = v.value if v.value > 0
          end
          # @@storage.delete_if { |k,v| v == 0 }
          IO.write(filename, JSON.pretty_generate(h.sort.to_h))
        end
      end
    end

################################################################################

    def clone
      deep_clone(@@storage)
    end

    # def select(item_names)
    #   selected_items = self.clone.select do |item_name, item_count|
    #     item_names.include?(item_name)
    #   end
    #   Hash.new(0).merge(selected_items)
    # end

    def sanitize_item_name(item_name)
      if item_name =~ /link-fluid-(?!.*(provider|requester)).*/
        item_name.gsub('link-fluid-', '')
      else
        item_name
      end
    end

################################################################################

    def add(item_name, item_count)
      RescueRetry.attempt do
      item_name = sanitize_item_name(item_name)

      @@storage[item_name] = Concurrent::AtomicFixnum.new(0) if @@storage[item_name].nil?
      @@storage[item_name].update do |value|
        value += item_count
      end

      item_count

      end
    end

    def remove(item_name, item_count)
      return 0 if @@storage[item_name].nil?

      RescueRetry.attempt do
      removed_count = 0

      @@storage[item_name].update do |value|
        removed_count = [value, item_count].min
        value -= removed_count
      end

      removed_count

      end
    end

################################################################################

    def bulk_add(items)
      items.each do |item_name, item_count|
        add(item_name, item_count)
      end
    end

    def bulk_remove(items)
      hash = Hash.new(0)
      items.each do |item_name, item_count|
        hash[item_name] = remove(item_name, item_count)
      end
      hash
    end

################################################################################

    # def format_delta_count(delta_count)
    #   if delta_count.nil?
    #     '-'
    #   elsif delta_count > 0
    #     "+#{countsize(delta_count)}"
    #   elsif delta_count == 0
    #     '0'
    #   elsif delta_count < 0
    #     "-#{countsize(-delta_count)}"
    #   end
    # end

    # def delta
    #   @@storage_delta
    # end

    def item_metrics
      # @@previous_storage ||= self.clone

      @@storage.each do |item_name, item_count|
        item_count = item_count.value
        # count_delta = (self.storage[item_name] - (@@previous_storage[item_name] || 0))
        # @@storage_delta_history[item_name] << count_delta
        # delta_counts = [@@storage_delta_history[item_name].size, 60].min

        # @@storage_delta_history[item_name] = @@storage_delta_history[item_name][-delta_counts, delta_counts]

        # sec_rate = @@storage_delta_history[item_name].map(&:to_f).sum / @@storage_delta_history[item_name].size
        # min_rate = @@storage_delta_history[item_name].sum

        # @@storage_delta[item_name] = [
        #   format_delta_count(sec_rate),
        #   format_delta_count(min_rate)
        # ]

        # update_websocket(item_name, item_count)
        # # storage_delta_instrumentation(item_name, sec_rate)
        # storage_item_instrumentation(item_name, item_count)
        if item_name == 'electricity'
          Metrics::Prometheus[:electrical_total].set(item_count) #, type: ItemType[item_name] })
        else
          Metrics::Prometheus[:storage_items_total].set(item_count,
            labels: { item_name: item_name, item_type: ItemType[item_name] })

          # Metrics::InfluxDB.write('storage_item_count',
          #   values: { count: item_count },
          #   tags: { name: item_name, type: ItemType[item_name] }
          # )
        end
      end

      # @@previous_storage = self.clone

      true
    end

################################################################################

    # def storage_item_instrumentation(item_name, item_count)
    #   if item_name == 'electricity'
    #     Metrics::Prometheus[:electrical_count].set(item_count, labels: { name: item_name }) #, type: ItemType[item_name] })
    #   else
    #     Metrics::Prometheus[:storage_item_count].set(item_count, labels: { name: item_name, type: ItemType[item_name] })

    #     # Metrics::InfluxDB.write('storage_item_count',
    #     #   values: { count: item_count },
    #     #   tags: { name: item_name, type: ItemType[item_name] }
    #     # )
    #   end
    # end

    # def storage_delta_instrumentation(item_name, item_count)
    #   if item_name == 'electricity'
    #     Metrics::Prometheus[:electrical_delta_count].set(item_count, labels: { name: item_name }) #, type: ItemType[item_name] })
    #   else
    #     Metrics::Prometheus[:storage_delta_count].set(item_count, labels: { name: item_name, type: ItemType[item_name] })
    #   end
    # end

    # def update_websocket(item_name, item_count)
    #   ::WebServer.settings.storage_sockets.each do |s|
    #     s.send({
    #       name: item_name,
    #       count: countsize(item_count),
    #       delta_s: delta[item_name][0],
    #       delta_m: delta[item_name][1]
    #     }.to_json)
    #   end
    # end

################################################################################

  end

  extend(ClassMethods)
end

#Storage.load
