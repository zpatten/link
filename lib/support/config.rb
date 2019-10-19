require 'ostruct'

class Config

  module ClassMethods
    def filename
      File.join(Dir.pwd, "config.json")
    end

    def load
      @@config = JSON.parse(IO.read(filename)).deep_stringify_keys!
    end

    def save!
      puts JSON.pretty_generate(@@config)
    end

    def master_value(*keys)
      keys = keys.map(&:to_s)
      $logger.info { "keys = #{keys}" }
      MemoryCache.fetch(key) do
        (@@config.dig('master', *keys) rescue nil)
      end
    end

    def server_value(server, *keys)
      key = [server, *keys].flatten.compact.map(&:to_s).join("_")
      $logger.info { "key = #{key}" }
      server = server.to_s
      $logger.info { "server = #{server}" }
      keys = keys.map(&:to_s)
      $logger.info { "keys = #{keys}" }
      MemoryCache.fetch(key) do
        sv = (@@config.dig('servers', server, *keys) rescue nil) #['servers'][server].dig(*keys) rescue nil)
        mv = (@@config.dig('master', *keys) rescue nil) #['master'].dig(*keys) rescue nil)
        (sv || mv)
      end
    end

    def [](key)
      @@config[key]
    end

    def []=(key, value)
      @@config[key] = value
    end

    def method_missing(method_name, *method_args, &block)
      @@config[method_name.to_s]
    end

  end

  extend ClassMethods

  # def initialize(filename)
  #   @config = JSON.parse(IO.read(filename)).deep_stringify_keys!
  #   # @config = deep_ostruct_convert(config)
  # end

  # # def deep_ostruct_convert(h)
  # #   h.each do |key, value|
  # #     if value.is_a?(Hash)
  # #       h[key] = deep_ostruct_convert(value)
  # #     end
  # #   end
  # #   OpenStruct.new(h)
  # # end

  # # def method_missing(method_name, *method_args, &block)
  # #   @config.send(method_name, *method_args, &block)
  # # end

end
