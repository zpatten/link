# frozen_string_literal: true

module Link
  class Cache

################################################################################

    module ClassMethods

      $cache ||= Concurrent::Map.new
      $cache_mutex ||= Hash.new do |h, k|
        h[k] = Hash.new do |mh, mk|
          mh[mk] = Mutex.new
        end
      end

      def fetch(key, options={}, &block)
        $cache_mutex[:fetch][key].synchronize do
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
      end

      def read(key, options={})
        $cache_mutex[:read][key].synchronize do
          cache_item = $cache[key]

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
      end

      def write(key, value, options={})
        $cache_mutex[:write][key].synchronize do
          expires_in = (options.delete(:expires_in) || -1)
          expires_at = (expires_in == -1 ? -1 : (Time.now.to_f + expires_in))

          logger.debug { "Write: #{key.inspect} (#{options})" }

          value = :nil if value.nil?

          $cache[key] = {
            value: value.deep_clone,
            expires_at: expires_at
          }

          value
        end
      end

      def delete(key, options={})
        $cache_mutex[:delete][key].synchronize do
          cache_item = $cache.delete(key)
          logger.debug { "Delete: #{key.inspect} (#{options})" }
          cached_value(cache_item)
        end
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
