# frozen_string_literal: true

require 'concurrent-edge'

class Config

################################################################################

  def initialize
    @config = Concurrent::Map.new
    config = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new)
    config.each do |key, value|
      @config[key] = value
    end

    LinkLogger.info(:config) { "Loaded Config: #{filename.ai}" }
    LinkLogger.debug(:config) { to_h.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "config.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(to_h.sort.to_h)+"\n")
    LinkLogger.info(:config) { "Saved Config" }

    true
  end

  def to_h
    config = Hash.new
    @config.each do |key, value|
      config[key] = value
    end
    config
  end

################################################################################

  def value(*keys)
    cache_key = keys.flatten.compact.join('-')
    keys      = keys.map(&:to_s)

    value = Cache.fetch(cache_key) do
      (to_h.dig(*keys) rescue nil)
    end

    # LinkLogger.debug(:config) { "keys=#{keys.ai}, value=#{value.ai}" }

    value
  end

  def server(server, *keys)
    cache_key = [server, *keys].flatten.compact.join('-')
    keys      = keys.map(&:to_s)

    value = Cache.fetch(cache_key) do
      config = to_h
      sv     = (config.dig('servers', server.to_s, *keys) rescue nil)
      mv     = (config.dig(*keys) rescue nil)
      (sv || mv)
    end

    # LinkLogger.debug(:config) { "server=#{server.ai}, keys=#{keys.ai}, value=#{value.ai}" }

    value
  end

################################################################################

  def [](key)
    @config[key.to_s]
  end

  def []=(key, value)
    @config[key.to_s] = value
  end

################################################################################

  def method_missing(method_name, *args, &block)
    self[method_name]
  end

  def respond_to?(method_name, include_private=false)
    @config.keys.include?(method_name) || super
  end

  def respond_to_missing?(method_name, include_private=false)
    @config.keys.include?(method_name) || super
  end

################################################################################

  module ClassMethods
    @@config ||= Config.new
    @@config_public_methods ||= (@@config.public_methods + @@config.to_h.keys.map(&:to_sym)).flatten

    def method_missing(method_name, *args, &block)
      if @@config_public_methods.include?(method_name)
        @@config.send(method_name, *args, &block)
      else
        super
      end
    end

    def respond_to?(method_name, include_private=false)
      @@config_public_methods.include?(method_name) || super
    end

    def respond_to_missing?(method_name, include_private=false)
      @@config_public_methods.include?(method_name) || super
    end
  end

  extend ClassMethods

################################################################################

end
