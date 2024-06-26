# frozen_string_literal: true

require 'concurrent-edge'

class Saves

################################################################################

  def initialize
    # LinkLogger.info(:item_types) { "Loaded Item Types: #{filename.ai}" }
    # LinkLogger.debug(:item_types) { @item_types.ai }
  end

################################################################################



  def filename
    File.expand_path(File.join(LINK_ROOT, "item_types.json"))
  end

  def save
    IO.write(filename, JSON.pretty_generate(to_h.sort.to_h)+"\n")
    LinkLogger.info(:item_types) { "Saved Item Types" }

    true
  end

  def to_h
    item_types = Hash.new
    @item_types.each do |item_name, item_type|
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

      LinkLogger.debug(:item_types) { "#{item_name} == #{@item_types[item_name]}" }
    end
    type
  end

  def []=(item_name, item_type)
    @item_types[item_name] = item_type
  end

################################################################################

  module ClassMethods
    @@item_types ||= Saves.new

    def method_missing(method_name, *args, **options, &block)
      @@item_types.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
