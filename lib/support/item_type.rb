# frozen_string_literal: true

class ItemType

  module ClassMethods

################################################################################

    @@item_type ||= Concurrent::Hash.new
    @@item_type_mutex ||= Mutex.new

################################################################################

    def [](item_name)
      @@item_type_mutex.synchronize do
        type = self.item_type[item_name]
        if type.nil?
          command = %(remote.call('link', 'lookup_item_type', '#{item_name}'))
          while type.nil? do
            type = Servers.random.rcon_command(command: command)
          end
          type.strip!
          self.item_type[item_name] = type

          $logger.debug(:item_type) { "#{item_name} == #{self.item_type[item_name]}" }
        end

        type
      end
    end

    def []=(item_name, item_type)
      self.item_type[item_name] = item_type
    end

    def item_type
      @@item_type.nil? and load

      @@item_type
    end

    def filename
      File.join(LINK_ROOT, "item_types.json")
    end

################################################################################

    def load
      @@item_type_mutex.synchronize do
        h = (JSON.parse(IO.read(filename)) rescue Hash.new)
        @@item_type.merge!(h)
      end
    end

    def save
      unless @@item_type.nil?
        @@item_type_mutex.synchronize do
          @@item_type.delete_if { |k,v| v.nil? }
          IO.write(filename, JSON.pretty_generate(@@item_type.sort.to_h))
        end
      end
    end

################################################################################

  end

  extend(ClassMethods)
end

ItemType.load
