# frozen_string_literal: true

class MemoryCache
  module ClassMethods

    $_memory_cache_store = Concurrent::Hash.new
    $_memory_cache_read_mutex ||= Mutex.new
    $_memory_cache_write_mutex ||= Mutex.new

    def fetch(key, options={}, &block)
      # $_memory_cache_fetch_mutex.synchronize do
        value = nil
        if (value = read(key, options)).nil?
          # LinkLogger.debug(:cache) { "Fetch: #{key} (#{options})" }
          return nil if !block_given?
          value = block.call
          write(key, value, options)
        else
          # LinkLogger.debug(:cache) { "Hit: #{key} (#{options})" }
        end

        value
      # end
    end

    def read(key, options={})
      $_memory_cache_read_mutex.synchronize do
        cache_item = $_memory_cache_store[key]

        unless cache_item.nil?
          if expired?(cache_item[:expires_at])
            # LinkLogger.debug(:cache) { "Expired: #{key} (#{options})" }
            delete(key, options)
          else
            # LinkLogger.debug(:cache) { "Read: #{key} (#{options})" }
            value = (cache_item[:value] == :nil ? nil : cache_item[:value])
            return value
          end
        end
      end

      # LinkLogger.debug(:cache) { "Miss: #{key} (#{options})" }

      nil
    end

    def write(key, value, options={})
      $_memory_cache_write_mutex.synchronize do
        expires_in = (options.delete(:expires_in) || -1)
        expires_at = (expires_in == -1 ? -1 : (Time.now.to_i + expires_in))

        # LinkLogger.debug(:cache) { "Write: #{key} (#{options})" }

        value = :nil if value.nil?

        cache_item = {
          :value => value,
          :expires_at => expires_at
        }

        $_memory_cache_store[key] = cache_item
      end

      true
    end

    def delete(key, options={})
      $_memory_cache_write_mutex.synchronize do
        $_memory_cache_store.delete(key)
      end

      # LinkLogger.debug(:cache) { "Delete: #{key}" }
    end

    def expired?(expires_at)
      expires_at ||= -1

      return false if (expires_at == -1)

      ((expires_at <= Time.now.to_i) ? true : false)
    end

  end

  extend ClassMethods
end
