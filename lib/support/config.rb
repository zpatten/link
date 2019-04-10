require 'ostruct'

class Config

  module ClassMethods
    def load(filename)
      filename = File.join(Dir.pwd, filename)
      @@config = Config.new(filename)
    end

    def master_value(*keys)
      key = keys.map(&:to_sym)
      MemoryCache.fetch(key) do
        (@@config.master.dig(*keys) rescue nil)
      end
    end

    def server_value(server, *keys)
      key = [server, *keys].flatten.compact.map(&:to_s).join("_")
      server = server.to_sym
      keys.map(&:to_sym)
      MemoryCache.fetch(key) do
        sv = (@@config.servers.send(server).dig(*keys) rescue nil)
        mv = (@@config.master.dig(*keys) rescue nil)
        (sv || mv)
      end
    end

    def method_missing(method_name, *method_args, &block)
      @@config.send(method_name, *method_args, &block)
    end

  end

  extend ClassMethods

  def initialize(filename)
    config = JSON.parse(IO.read(filename))
    @config = deep_ostruct_convert(config)
  end

  def deep_ostruct_convert(h)
    h.each do |key, value|
      if value.is_a?(Hash)
        h[key] = deep_ostruct_convert(value)
      end
    end
    OpenStruct.new(h)
  end

  def method_missing(method_name, *method_args, &block)
    @config.send(method_name, *method_args, &block)
  end

end
