require 'ostruct'

require_relative "support/logger"

require_relative "support/config"
require_relative "support/memory_cache"
require_relative "support/metric"
require_relative "support/requests"
require_relative "support/storage"
require_relative "support/thread_pool"

def platform
  case RUBY_PLATFORM
  when /mingw/i
    :windows
  when /linux/i
    :linux
  end
end

class OpenStruct
  def count
    self.to_h.count
  end
end

# https://gist.github.com/Integralist/9503099
class Object
  def deep_symbolize_keys!
    return self.reduce({}) do |memo, (k, v)|
      memo.tap { |m| m[k.to_sym] = v.deep_symbolize_keys! }
    end if self.is_a? Hash

    return self.reduce([]) do |memo, v|
      memo << v.deep_symbolize_keys!; memo
    end if self.is_a? Array

    self
  end
end

def pp_inline(object)
  PP.singleline_pp(object, "")
end



# Displays RCON response packets for debugging or other uses (i.e. when we do not care about the response)
def rcon_print(host, packet_fields, data)
  # $logger.debug { "RCON Received Packet: #{packet_fields.inspect}" }
end

def deep_clone(object)
  Marshal.load(Marshal.dump(object))
end

# Redirect RCON output to other servers
def rcon_redirect(host, packet_fields, (player_index, command, origin_host))
  origin = Servers.find_by_name(origin_host)
  payload = packet_fields.payload.strip
  message = %(#{host}#{command}: #{payload})
  command = %(/#{rcon_executor} game.players[#{player_index}].print(#{message.dump}, {r = 1, g = 1, b = 1}))
  origin.rcon_command_nonblock(command, method(:rcon_print))
end

def schedule_task(what, frequency=nil, server=nil, &block)
  frequency = if frequency.nil?
    Config.master_value(:scheduler, what)
  else
    frequency
  end
  ThreadPool.register(what, frequency, server, &block)
end

def schedule_server(what, &block)
  $logger.info { "Scheduling #{what}..." }

  servers = Servers.find(what)
  servers.each do |server|
    frequency = Config.server_value(server.name, :scheduler, what)
    schedule_task(what, frequency, server, &block)
  end
end

def schedule_servers(what, &block)
  $logger.info { "Scheduling #{what}..." }

  servers = Servers.find(what)
  frequency = Config.master_value(:scheduler, what)
  schedule_task(what, frequency, servers, &block)
end

# RCON Executor
# Switch between using 'c' or 'silent-command' depending on the debug flag.
def rcon_executor
  # (debug? ? "c" : "silent-command")
  "silent-command"
end

def debug?
  !!ENV["DEBUG"]
end

class RescueRetry
  module ClassMethods
    def default_max_attempts
      3
    end

    def default_sleep_for
      3
    end

    def default_rescue_exceptions
      [
        Errno::ECONNABORTED,
        Errno::ECONNREFUSED,
        Errno::ECONNRESET,
        Errno::ENOTSOCK,
        Errno::EPIPE,
        IOError
      ]
    end

    def attempt(options={}, &block)
      max_attempts      = (options.delete(:max_attempts) || default_max_attempts)
      rescue_exceptions = (options.delete(:rescue_exceptions) || default_rescue_exceptions)
      sleep_for         = (options.delete(:sleep_for) || default_sleep_for)
      on_exception      = options.delete(:on_exception)

      attempts = 1

      begin
        block.call
      rescue *rescue_exceptions => e
        # calculate how long to sleep for; make sure we at most retry every minute
        # sleep_for = (3 * attempts)
        # sleep_for = 60 if sleep_for > 60

        # let the user know what is going on
        $logger.fatal { "Exception: #{e.full_message}" }
        $logger.fatal { "Sleeping for #{sleep_for} seconds then retrying...  (Attempt #{attempts} of #{max_attempts})" }

        # if we exceed the max attempts throw the exception
        raise e if ((max_attempts != -1) && (attempts > max_attempts))

        # if we have an on_exception callback fire it
        on_exception.nil? or on_exception.call(e)

        # sleep before we try again
        sleep sleep_for
        attempts += 1
        retry
      end

    end
  end

  extend ClassMethods
end
