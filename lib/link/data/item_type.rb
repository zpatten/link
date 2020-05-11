# frozen_string_literal: true

module Link

  def self.item_type
    Link::ItemType
  end

  class Data
    class ItemType

################################################################################

      module ClassMethods
        @@item_type = nil
        @@item_type_mutex ||= Mutex.new

        def filename
          File.join(LINK_ROOT, 'item_types.json')
        end

        def read!
          @@item_type_mutex.synchronize do
            logger.debug { 'Reading Item Types' }
            @@item_type = Concurrent::Hash[JSON.parse(IO.read(filename))]
          end
        end

        def write!
          @@item_type_mutex.synchronize do
            logger.debug { 'Writing Item Types' }
            IO.write(filename, JSON.pretty_generate(@@item_type))
          end
        end

        def update(key)
          @@item_type_mutex.synchronize do
            if (type = item_type[key]).nil?
              # command = %(remote.call('link', 'lookup_item_type', '#{key}'))
              # while type.nil? do
              #   type = Servers.random.rcon_command(command: command)
              # end
              # item_type[key] = type.strip!
              # logger.debug { "#{key} == #{self.item_type[key]}" }
            end
          end

          item_type[key]
        end

        def item_type
          @@item_type || read
        end

        def [](key)
          item_type[key] or update(key)
        end

        def []=(key, value)
          item_type[key] = value
        end

        def method_missing(method_name, *method_args, &method_block)
          if item_type.respond_to?(method_name)
            item_type.send(method_name, *method_args, &method_block)
          else
            item_type[method_name.to_s]
          end
        end

      end

      extend ClassMethods

################################################################################

    end
  end
end
