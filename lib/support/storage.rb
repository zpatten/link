# frozen_string_literal: true

class Storage

  module ClassMethods

################################################################################

    @@storage ||= Concurrent::Hash.new
    @@storage_mutex ||= Mutex.new

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
          Concurrent::AtomicFixnum.new(v)
        end
        @@storage.merge!(h)
      end

      true
    end

    def save
      return false if @@storage.nil?

      @@storage_mutex.synchronize do
        h = Hash.new
        self.clone.each do |k,v|
          h[k] = v.value if v.value > 0
        end
        h.delete_if { |k,v| v == 0 }
        IO.write(filename, JSON.pretty_generate(h.sort.to_h))
      end

      true
    end

################################################################################

    def clone
      #deep_clone(@@storage)
      @@storage.clone
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

      @@storage[item_name].nil? and @@storage[item_name] = Concurrent::AtomicFixnum.new(0)
      @@storage[item_name].update do |value|
        value += item_count
      end

      item_count
    end

    def remove(item_name, item_count)
      return 0 if @@storage[item_name].nil?

      removed_count = 0

      @@storage[item_name].update do |value|
        removed_count = [value, item_count].min
        value -= removed_count
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
      hash = Hash.new(0)
      items.each do |item_name, item_count|
        hash[item_name] = remove(item_name, item_count)
      end
      hash
    end

################################################################################

    def metrics_handler
      self.clone.each do |item_name, item_count|
        item_count = item_count.value
        Metrics::Prometheus[:storage_items_total].set(item_count,
          labels: { item_name: item_name, item_type: ItemType[item_name] })
      end

      true
    end

################################################################################

  end

  extend(ClassMethods)
end
