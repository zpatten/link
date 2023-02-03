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
    config = to_h

    keys.delete_if { |x| x.is_a?(Hash) }
    key  = keys.join('-')
    keys = keys.map(&:to_s)
    value = Cache.fetch(key) do
      (config.dig(*keys) rescue nil)
    end
    LinkLogger.debug(:config) { "keys=#{keys.ai}, value=#{value.ai}" }
    value
  end

  def server(server, *keys)
    config = to_h

    key    = [server, *keys].flatten.compact.join("-")
    keys   = keys.map(&:to_s)
    server = server.to_s
    value = Cache.fetch(key) do
      sv = (config.dig('servers', server, *keys) rescue nil)
      mv = (config.dig(*keys) rescue nil)
      (sv || mv)
    end
    LinkLogger.debug(:config) { "server=#{server.ai}, keys=#{keys.ai}, value=#{value.ai}" }
    value
  end

################################################################################

  def [](key)
    @config[key]
  end

  def []=(key, value)
    @config[key] = value
  end

################################################################################

  def method_missing(method_name, *args, &block)
    @config[method_name.to_s]
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
