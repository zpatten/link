# frozen_string_literal: true

module Link

  def self.config
    Link::Config
  end

  class Data
    class Config

################################################################################

      module ClassMethods
        @@config = nil
        @@config_mutex ||= Mutex.new

        def filename
          File.join(LINK_ROOT, 'config.json')
        end

        def read
          @@config_mutex.synchronize do
            logger.debug { 'Reading Configuration' }
            @@config = Concurrent::Hash[JSON.parse(IO.read(filename))]
          end
        end

        def write
          @@config_mutex.synchronize do
            logger.debug { 'Writing Configuration' }
            IO.write(filename, JSON.pretty_generate(@@config))
          end
        end

        def config
          @@config || read
        end

        def [](key)
          config[key]
        end

        def []=(key, value)
          config[key] = value
        end

        def method_missing(method_name, *method_args, &method_block)
          if config.respond_to?(method_name)
            config.send(method_name, *method_args, &method_block)
          else
            config[method_name.to_s]
          end
        end

      end

      extend ClassMethods

################################################################################

    end
  end
end
