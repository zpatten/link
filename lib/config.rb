require 'ostruct'

class Config

  module ClassMethods
    @@config = nil
    @@configuration_mutex = Mutex.new

    def load(filename)
      @@configuration_mutex.synchronize do
        return unless @@config.nil?
        filename = File.join(Dir.pwd, filename)
        @@config = Config.new(filename)
      end
    end

    def server_value(server, *keys)
      server = server.to_sym
      keys.map(&:to_sym)
      @@server_values ||= Hash.new
      @@server_values["#{server}_#{keys}"] ||= begin
        # sv = (@@config.servers.send(server.to_sym).send(key.to_sym) rescue nil)
        # mv = (@@config.master.send(key.to_sym) rescue nil)
        sv = (@@config.servers.send(server.to_sym).dig(*keys) rescue nil)
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
