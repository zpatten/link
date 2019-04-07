class MemoryCache
  module ClassMethods

    $_memory_cache_store ||= Hash.new

    def fetch(key, options={}, &block)
      value = nil
      if (value = read(key, options)).nil?
        $logger.debug { "MemoryCache generate: #{key}#{options.empty? ? "" : "(#{options})"}" }
        return nil if !block_given?
        value = block.call
        write(key, value, options)
      else
        $logger.debug { "MemoryCache fetch-hit: #{key}#{options.empty? ? "" : "(#{options})"}" }
      end

      value
    end

    def read(key, options={})
      unless (cache_item = $_memory_cache_store[key]).nil?
        if expired?(cache_item[:expires_at])
          $logger.debug { "MemoryCache expired: #{key}" }
          delete(key, options)
        else
          $logger.debug { "MemoryCache read-hit: #{key}" }
          value = (cache_item[:value] == :nil ? nil : cache_item[:value])
          return cache_item[:value]
        end
      end
      $logger.debug { "MemoryCache miss: #{key}" }

      nil
    end

    def write(key, value, options={})
      expires_in = (options.delete(:expires_in) || -1)
      expires_at = (expires_in == -1 ? -1 : (Time.now.to_i + expires_in))
      # mutex = (options.delete(:mutex) || $_memory_cache_mutex)

      $logger.debug { "MemoryCache write: #{key}#{options.empty? ? "" : "(#{options})"}" }

      value = :nil if value.nil?

      cache_item = {
        :value => value,
        :expires_at => expires_at
      }

      $_memory_cache_store[key] = cache_item

      true
    end

    def delete(key, options={})
      # mutex = (options.delete(:mutex) || $_memory_cache_mutex)
      $_memory_cache_store.delete(key)
      # mutex.synchronize do
      #   $_memory_cache_store.delete(key)
      # end
      $logger.debug { "MemoryCache deleted: #{key}" }
    end

    def expired?(expires_at)
      return false if (expires_at == -1)

      ((expires_at <= Time.now.to_i) ? true : false)
    end

  end

  extend ClassMethods
end
