# frozen_string_literal: true

class Config

################################################################################

  module ClassMethods
    def method_missing(method_name, *args, **options, &block)
      @@config ||= Config.new
      @@config.send(method_name, *args, **options, &block)
    end
  end
  extend ClassMethods

  def initialize
    @config = Concurrent::Map.new
    config = (JSON.parse(IO.read(filename)) rescue Concurrent::Map.new)
    config.each do |item_name, item_count|
      @config[item_name] = item_count
    end

    $logger.info(:config) { "Loaded Config" }
    $logger.debug(:config) { copy.ai }
  end

################################################################################

  def filename
    File.join(LINK_ROOT, "config.json")
  end

  def save
    IO.write(filename, JSON.pretty_generate(copy.sort.to_h))
    $logger.info(:config) { "Saved Config" }

    true
  end

  def copy
    config = Hash.new
    @config.clone.each do |item_name, item_count|
      config[item_name] = item_count
    end
  end

################################################################################

  def master_value(*keys)
    key  = keys.join('-')
    keys = keys.map(&:to_s)
    $logger.debug { "keys=#{keys}" }
    MemoryCache.fetch(key) do
      (copy.dig('master', *keys) rescue nil)
    end
  end

  def server_value(server, *keys)
    key    = [server, *keys].flatten.compact.join("-")
    keys   = keys.map(&:to_s)
    server = server.to_s
    MemoryCache.fetch(key) do
      sv = (copy.dig('servers', server, *keys) rescue nil)
      mv = (copy.dig('master', *keys) rescue nil)
      (sv || mv)
    end
  end

################################################################################

  def [](key)
    @config[key]
  end

  def []=(key, value)
    @config[key] = value
  end

################################################################################

  def to_h
    @config
  end

  def method_missing(method_name, *args, **options, &block)
    @config[method_name.to_s]
  end

################################################################################

end
