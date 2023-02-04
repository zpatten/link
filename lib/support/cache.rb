# frozen_string_literal: true

require 'concurrent-edge'

class Cache

################################################################################

  def initialize
    @cache = Concurrent::Map.new
    LinkLogger.debug(:cache) { "Loaded Cache" }
  end

################################################################################

  def fetch(key, options={}, &block)
    if (value = read(key, options)).nil?
      raise "Must supply a block!" unless block_given?
      LinkLogger.debug(:cache) { "Fetch: key=#{key.ai}, options=#{options.ai}" }
      value = write(key, nil, options, &block)
    else
      LinkLogger.debug(:cache) { "Hit: key=#{key.ai}, options=#{options.ai}" }
    end
    value
  end

  def read(key, options={})
    value = nil
    unless (cached_item = @cache[key]).nil?
      if expired?(cached_item)
        LinkLogger.debug(:cache) { "Expired: key=#{key.ai}, options=#{options.ai}" }
        delete(key, options)
      else
        LinkLogger.debug(:cache) { "Read: key=#{key.ai}, options=#{options.ai}" }
        value = cached_item[:value]
      end
    end
    value
  end

  def write(key, value=nil, options={}, &block)
    LinkLogger.debug(:cache) { "Write: key=#{key.ai}, value=#{value.ai}, options=#{options.ai}" }
    cached_item = @cache.compute(key) do |current_value|
      expires_in = (options[:expires_in] || -1)
      expires_at = (expires_in == -1 ? -1 : (Time.now.to_i + expires_in))

      {
        :value => (block_given? ? block.call(current_value) : value),
        :expires_at => expires_at
      }
    end
    cached_item[:value]
  end

  def delete(key, options={})
    LinkLogger.debug(:cache) { "Delete: key=#{key.ai}, options=#{options.ai}" }
    @cache.delete(key)
  end

  def expired?(cached_item)
    expires_at = cached_item[:expires_at] || -1

    return false if (expires_at == -1)

    ((expires_at <= Time.now.to_i) ? true : false)
  end

################################################################################

  module ClassMethods
    @@cache ||= Cache.new

    def method_missing(method_name, *args, &block)
      @@cache.send(method_name, *args, &block)
    end

  end

  extend ClassMethods

################################################################################

end
