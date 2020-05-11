# frozen_string_literal: true

module Link

  def self.storage
    Link::Storage
  end

  class Data
    class Storage

################################################################################

      module ClassMethods
        @@storage = nil
        @@storage_mutex ||= Mutex.new

        def filename
          File.join(LINK_ROOT, 'storage.json')
        end

        def read!
          @@storage_mutex.synchronize do
            logger.debug { 'Reading Storage' }
            @@storage = Concurrent::Map[JSON.parse(IO.read(filename))]
          end
        end

        def write!
          @@storage_mutex.synchronize do
            logger.debug { 'Writing Storage' }
            IO.write(filename, JSON.pretty_generate(@@storage))
          end
        end

        def storage
          @@storage || read
        end

        def [](key)
          storage.fetch(key, 0)
        end

        def []=(key, value)
          storage[key] = value
        end

        def method_missing(method_name, *method_args, &method_block)
          if storage.respond_to?(method_name)
            storage.send(method_name, *method_args, &method_block)
          else
            storage[method_name.to_s]
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
          storage.compute(item_name) do |current_count|
            (current_count || 0) + item_count
          end
        end

        def remove(item_name, item_count)
          item_name = sanitize_item_name(item_name)
          storage.compute(item_name) do |current_count|
            (current_count || 0) - item_count
          end
        end

################################################################################

        def bulk_add(items)
          items.each_pair do |item_name, item_count|
            item_name = sanitize_item_name(item_name)
            add(item_name, item_count)
          end
        end

        def bulk_remove(items)
          items.each_pair do |item_name, item_count|
            item_name = sanitize_item_name(item_name)
            remove(item_name, item_count)
          end
        end

################################################################################

      end

      extend ClassMethods

################################################################################

    end
  end
end
