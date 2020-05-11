# frozen_string_literal: true

module Link
  class Cache

################################################################################

    module ClassMethods
      @@cache ||= Concurrent::Map.new
      @@lock ||= Concurrent::Hash.new do |hash, key|
        hash[key] = Concurrent::ReadWriteLock.new
      end

      def fetch(key, options={}, &block)
        value = nil
        if (value = read(key, options)).nil?
          return nil if !block_given?
          logger.debug { "Fetch: #{key.inspect} (#{options})" }
          value = block.call
          write(key, value, options)
        else
          logger.debug { "Hit: #{key.inspect} (#{options})" }
        end

        value
      end

      def read(key, options={})
        cache_item = @@lock[key].with_read_lock do
          @@cache[key]
        end

        unless cache_item.nil?
          if expired?(cache_item[:expires_at])
            logger.debug { "Expired: #{key.inspect} (#{options})" }
            delete(key, options)
          else
            logger.debug { "Read: #{key.inspect} (#{options})" }
            return cached_value(cache_item).deep_clone
          end
        end

        nil
      end

      def write(key, value, options={})
        expires_in = (options.delete(:expires_in) || -1)
        expires_at = (expires_in == -1 ? -1 : (Time.now.to_f + expires_in))

        logger.debug { "Write: #{key.inspect} (#{options})" }

        value = :nil if value.nil?

        @@lock[key].with_write_lock do
          @@cache[key] = {
            value: value.deep_clone,
            expires_at: expires_at
          }
        end

        value
      end

      def delete(key, options={})
        cache_item = @@lock[key].with_write_lock do
          @@cache.delete(key)
        end
        logger.debug { "Delete: #{key.inspect} (#{options})" }
        cached_value(cache_item)
      end

    private

      def cached_value(cache_item)
        ((cache_item[:value] == :nil) ? nil : cache_item[:value])
      end

      def expired?(expires_at)
        expires_at ||= -1

        return false if expires_at == -1

        ((expires_at <= Time.now.to_f) ? true : false)
      end

    end

    extend ClassMethods

################################################################################

  end
end
