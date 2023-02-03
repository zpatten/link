# frozen_string_literal: true

class Config

################################################################################

  def initialize
    @config = Concurrent::Map.new
    config = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new)
    config.each do |key, value|
      @config[key] = value
    end

    LinkLogger.info(:config) { "Loaded Config" }
    LinkLogger.debug(:config) { to_h.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "config.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(to_h.sort.to_h))
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
    config    = to_h
    cache_key = keys.flatten.compact.join('-')
    keys      = keys.map(&:to_s)

    value = Cache.fetch(cache_key) do
      (config.dig(*keys) rescue nil)
    end

    LinkLogger.debug(:config) { "keys=#{keys.ai}, value=#{value.ai}" }

    value
  end

  def server(server, *keys)
    config    = to_h
    cache_key = [server, *keys].flatten.compact.join('-')
    keys      = keys.map(&:to_s)

    value = Cache.fetch(cache_key) do
      sv = (config.dig('servers', server.to_s, *keys) rescue nil)
      mv = (config.dig(*keys) rescue nil)
      (sv || mv)
    end

    LinkLogger.debug(:config) { "server=#{server.ai}, keys=#{keys.ai}, value=#{value.ai}" }

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

################################################################################

  module ClassMethods
    @@config ||= Config.new

    def method_missing(method_name, *args, &block)
      @@config.send(method_name, *args, &block)
    end
  end

  extend ClassMethods

################################################################################

end
