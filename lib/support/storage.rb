# frozen_string_literal: true

class Storage

  module ClassMethods

################################################################################

    @@lock ||= Concurrent::ReadWriteLock.new
    @@mutex ||= Mutex.new
    @@storage ||= Concurrent::Hash.new

################################################################################

    def [](item_name)
      item_name = sanitize_item_name(item_name)

      @@lock.with_read_lock do
        @@storage[item_name].value
      end
    end

    def []=(item_name, item_count)
      item_name = sanitize_item_name(item_name)

      @@lock.with_write_lock do
        @@storage[item_name].nil? and @@storage[item_name] = Concurrent::AtomicFixnum.new(0)
        @@storage[item_name].update { |value| item_count }
      end

      item_count
    end

    def filename
      File.join(LINK_ROOT, "storage.json")
    end

################################################################################

    def load
      @@lock.with_write_lock do
        h = (JSON.parse(IO.read(filename)) rescue Hash.new)
        h.transform_values! { |v| Concurrent::AtomicFixnum.new(v) }
        $logger.debug(:storage) { h.ai }
        @@storage.merge!(h)
      end

      true
    end

    def save
      return false if @@storage.nil?

      @@lock.with_read_lock do
        IO.write(filename, JSON.pretty_generate(self.clone.sort.to_h))
      end

      true
    end

################################################################################

    def clone
      @@lock.with_read_lock do
        Hash[@@storage.clone].transform_values { |v| v.value.to_i }.delete_if{ |k,v| v == 0 }
      end
    end

    def sanitize_item_name(item_name)
      if item_name =~ /link-fluid-(?!.*(provider|requester)).*/
        item_name.gsub('link-fluid-', '')
      else
        item_name
      end
    end

################################################################################

    def add(item_name, item_count)
      item_name = sanitize_item_name(item_name)

      @@lock.with_write_lock do
        @@storage[item_name].nil? and @@storage[item_name] = Concurrent::AtomicFixnum.new(0)
        @@storage[item_name].update do |value|
          value + item_count
        end
      end

      item_count
    end

    def remove(item_name, item_count)
      return 0 if @@storage[item_name].nil?

      removed_count = 0

      @@lock.with_write_lock do
        @@storage[item_name].update do |value|
          removed_count = [value, item_count].min
          value - removed_count
        end
      end

      removed_count
    end

################################################################################

    def bulk_add(items)
      items.each do |item_name, item_count|
        add(item_name, item_count)
      end
    end

    def bulk_remove(items)
      removed_items = Hash.new
      items.each do |item_name, item_count|
        removed_items[item_name] = remove(item_name, item_count)
      end
      removed_items
    end

################################################################################

    def metrics_handler
      self.clone.each do |item_name, item_count|
        Metrics::Prometheus[:storage_items_total].set(item_count,
          labels: { item_name: item_name, item_type: ItemType[item_name] })
      end

      true
    end

################################################################################

  end

  extend(ClassMethods)
end
