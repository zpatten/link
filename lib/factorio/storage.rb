# frozen_string_literal: true

require 'concurrent-edge'

module Factorio
  class Storage

################################################################################

    def initialize
      @storage = Concurrent::Map.new { 0 }
      storage = (JSON.parse(IO.read(filename).strip) rescue Concurrent::Map.new { 0 })
      storage.each do |item_name, item_count|
        @storage[item_name] = item_count
      end

      LinkLogger.info(:storage) { "Loaded Storage: #{filename.ai}" }
      LinkLogger.debug(:storage) { @storage.ai }
    end

################################################################################

    def filename
      File.expand_path(File.join(LINK_ROOT, "storage.json"))
    end

    def save
      IO.write(filename, JSON.pretty_generate(to_h.sort.to_h)+"\n")
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

      @storage.compute(item_name) do |current_value|
        current_value ||= 0
        current_value + item_count
      end

      item_count
    end

    def remove(item_name, item_count)
      return 0 if @storage[item_name].nil?
      removed_count = 0

      @storage.compute(item_name) do |current_value|
        current_value ||= 0
        removed_count = [current_value, item_count].min
        current_value - removed_count
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
          labels: { item_name: item_name, item_type: Factorio::ItemTypes[item_name] })
      end

      true
    end

################################################################################

    module ClassMethods
      @@storage ||= Factorio::Storage.new
      @@storage_methods ||= @@storage.public_methods

      def method_missing(method_name, *args, &block)
        if @@storage_methods.include?(method_name)
          @@storage.send(method_name, *args, &block)
        else
          super
        end
      end

      def respond_to?(method_name, include_private=false)
        @@storage_methods.include?(method_name) || super
      end

      def respond_to_missing?(method_name, include_private=false)
        @@storage_methods.include?(method_name) || super
      end
    end

    extend ClassMethods

################################################################################

  end
end
