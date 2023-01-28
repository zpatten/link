# frozen_string_literal: true

class Storage

################################################################################

  module ClassMethods
    def method_missing(method_name, *args, **options, &block)
      @@storage ||= Storage.new
      @@storage.send(method_name, *args, **options, &block)
    end
  end
  extend ClassMethods

  def initialize
    @storage = Concurrent::Map.new
    storage = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new)
    storage.each do |item_name, item_count|
      @storage[item_name] = item_count
    end

    $logger.info(:storage) { "Loaded Storage" }
    $logger.debug(:storage) { @storage.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "storage.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(copy.sort.to_h))
    $logger.info(:storage) { "Saved Storage" }

    true
  end

  def copy
    storage = Hash.new
    @storage.clone.each do |item_name, item_count|
      storage[item_name] = item_count
    end
    storage
  end

################################################################################

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

    @storage[item_name] += item_count

    item_count
  end

  def remove(item_name, item_count)
    return 0 if @storage[item_name].nil?
    removed_count = 0

    @storage.compute(item_name) do |value|
      removed_count = [value, item_count].min
      value - removed_count
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
    @storage.each do |item_name, item_count|
      Metrics::Prometheus[:storage_items_total].set(item_count,
        labels: { item_name: item_name, item_type: ItemTypes[item_name] })
    end

    true
  end

################################################################################

end
