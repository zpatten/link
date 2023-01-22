# frozen_string_literal: true

class Config

  module ClassMethods

    def filename
      File.join(Dir.pwd, "config.json")
    end

    def config
      @@config ||= begin
        hash = (JSON.parse(IO.read(filename)) rescue {})
        puts hash.ai
        Concurrent::Hash[hash]
      end
      @@config
    end

    def save!
      IO.write(filename, JSON.pretty_generate(config))
    end

    def master_value(*keys)
      key  = keys.join('-')
      keys = keys.map(&:to_s)
      $logger.debug { "keys=#{keys}" }
      MemoryCache.fetch(key) do
        (config.dig('master', *keys) rescue nil)
      end
    end

    def server_value(server, *keys)
      key    = [server, *keys].flatten.compact.join("-")
      keys   = keys.map(&:to_s)
      server = server.to_s
      MemoryCache.fetch(key) do
        sv = (config.dig('servers', server, *keys) rescue nil)
        mv = (config.dig('master', *keys) rescue nil)
        (sv || mv)
      end
    end

    def [](key)
      config[key]
    end

    def []=(key, value)
      config[key] = value
    end

    def to_h
      config
    end

    def method_missing(method_name, *method_args, &block)
      config[method_name.to_s]
    end

  end

  extend ClassMethods

end
