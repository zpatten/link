# frozen_string_literal: true

class Storage

################################################################################

  def initialize
    @storage = Concurrent::Map.new { 0 }
    storage = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new { 0 })
    storage.each do |item_name, item_count|
      @storage[item_name] = item_count
    end

    LinkLogger.info(:storage) { "Loaded Storage" }
    LinkLogger.debug(:storage) { @storage.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "storage.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(copy.sort.to_h))
    LinkLogger.info(:storage) { "Saved Storage" }

    true
  end

  def to_h
    storage = Hash.new
    @storage.each do |item_name, item_count|
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

    @storage.compute(item_name) do |value|
      value + item_count
    end

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

  module ClassMethods
    @@storage ||= Storage.new

    def method_missing(method_name, *args, &block)
      @@storage.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
