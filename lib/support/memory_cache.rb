# frozen_string_literal: true

class MemoryCache
  module ClassMethods

    $_memory_cache_store = Concurrent::Hash.new

    def fetch(key, options={}, &block)
      $_memory_cache_fetch_mutex ||= Mutex.new
      $_memory_cache_fetch_mutex.synchronize do
        value = nil
        if (value = read(key, options)).nil?
          # $logger.debug(:cache) { "Fetch: #{key}#{options.empty? ? "" : "(#{options})"}" }
          return nil if !block_given?
          value = block.call
          write(key, value, options)
        # else
        #   $logger.debug { "MemoryCache fetch-hit: #{key}#{options.empty? ? "" : "(#{options})"}" }
        end

        value
      end
    end

    def read(key, options={})
      $_memory_cache_read_mutex ||= Mutex.new
      $_memory_cache_read_mutex.synchronize do
        cache_item = $_memory_cache_store[key]

        unless cache_item.nil?
          if expired?(cache_item[:expires_at])
            # $logger.debug(:cache) { "Expired: #{key}" }
            delete(key, options)
          else
            # $logger.debug(:cache) { "Read-Hit: #{key}" }
            value = (cache_item[:value] == :nil ? nil : cache_item[:value])
            return deep_clone(value)
          end
        end
      end

      # $logger.debug(:cache) { "Miss: #{key}" }

      nil
    end

    def write(key, value, options={})
      $_memory_cache_write_mutex ||= Mutex.new
      $_memory_cache_write_mutex.synchronize do
        expires_in = (options.delete(:expires_in) || -1)
        expires_at = (expires_in == -1 ? -1 : (Time.now.to_i + expires_in))

        # $logger.debug(:cache) { "Write: #{key}#{options.empty? ? "" : "(#{options})"}" }

        value = :nil if value.nil?

        cache_item = {
          :value => deep_clone(value),
          :expires_at => expires_at
        }

        $_memory_cache_store[key] = cache_item
      end

      true
    end

    def delete(key, options={})
      $_memory_cache_delete_mutex ||= Mutex.new
      $_memory_cache_delete_mutex.synchronize do
        $_memory_cache_store.delete(key)
      end

      # $logger.debug(:cache) { "Deleted: #{key}" }
    end

    def expired?(expires_at)
      return false if (expires_at == -1)

      ((expires_at <= Time.now.to_i) ? true : false)
    end

  end

  extend ClassMethods
end
