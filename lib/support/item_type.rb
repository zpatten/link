# frozen_string_literal: true

class ItemTypes

################################################################################

  module ClassMethods
    def method_missing(method_name, *args, **options, &block)
      @@item_types ||= ItemTypes.new
      @@item_types.send(method_name, *args, **options, &block)
    end
  end
  extend ClassMethods

  def initialize
    @item_types = Concurrent::Map.new
    item_types = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new)
    item_types.each do |item_name, item_type|
      @item_types[item_name] = item_type
    end

    $logger.info(:item_types) { "Loaded Item Types" }
    $logger.debug(:item_types) { @item_types.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "item_types.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(copy.sort.to_h))
    $logger.info(:item_types) { "Saved Item Types" }

    true
  end

  def copy
    item_types = Hash.new
    @item_types.clone.each do |item_name, item_type|
      item_types[item_name] = item_type
    end
    item_types
  end

################################################################################

  def [](item_name)
    type = (item_name == 'electricity' ? 'electricity' : @item_types[item_name])
    if type.nil?
      command = %(remote.call('link', 'lookup_item_type', '#{item_name}'))
      while type.nil? do
        type = Servers.random.rcon_command(command)
      end
      type.strip!
      @item_types[item_name] = type

      $logger.debug(:item_type) { "#{item_name} == #{@item_types[item_name]}" }
    end
    type
  end

  def []=(item_name, item_type)
    @item_types[item_name] = item_type
  end

################################################################################

end
