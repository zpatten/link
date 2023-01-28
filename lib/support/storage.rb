# frozen_string_literal: true

class Storage

################################################################################

  def initialize
    @storage = Concurrent::Hash.new
    @storage.merge!((JSON.parse(IO.read(filename)) rescue Concurrent::Hash.new))
    @storage.transform_values! { |value| Concurrent::AtomicFixnum.new(value) }

    $logger.info(:storage) { "Loaded Storage" }
    $logger.debug(:storage) { @storage.ai }
  end

  def filename
    File.join(LINK_ROOT, "storage.json")
  end

################################################################################

  def save
    IO.write(filename, JSON.pretty_generate(clone.sort.to_h))

    true
  end

  def clone
    @storage.transform_values { |value| value.value.to_i }
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

    @storage[item_name] = Concurrent::AtomicFixnum.new(0) if @storage[item_name].nil?

    @storage[item_name].update do |value|
      value + item_count
    end

    @storage[item_name].value
  end

  def remove(item_name, item_count)
    return 0 if @storage[item_name].nil?
    removed_count = 0

    @storage[item_name].update do |value|
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
      item_count = item_count.value
      Metrics::Prometheus[:storage_items_total].set(item_count,
        labels: { item_name: item_name, item_type: ItemType[item_name] })
    end

    true
  end

################################################################################

end
