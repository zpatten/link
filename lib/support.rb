# frozen_string_literal: true

require_relative 'support/config'
require_relative 'support/item_type'
require_relative 'support/logger'
require_relative 'support/logistics'
require_relative 'support/memory_cache'
require_relative 'support/method_proxy'
require_relative 'support/metrics'
require_relative 'support/signals'
require_relative 'support/storage'
require_relative 'support/thread_pool'

def master?
  Process.pid == MASTER_PID
end

# def shutdown!
#   $shutdown = true
#   # EventMachine.stop
#   ThreadPool.shutdown!
#   # sleep 3
#   # sleep SLEEP_TIME while running?

#   if master?
#     # Servers.shutdown!
#     # Storage.save
#   else
#   end

#   $logger.close
#   # Process.kill('TERM', Process.pid)
# end

def running?
  ThreadPool.running?
end

def shutdown?
  !!$shutdown
end

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
# class Object
#   def deep_symbolize_keys!
#     return self.reduce({}) do |memo, (k, v)|
#       memo.tap { |m| m[k.to_sym] = v.deep_symbolize_keys! }
#     end if self.is_a? Hash

#     return self.reduce([]) do |memo, v|
#       memo << v.deep_symbolize_keys!; memo
#     end if self.is_a? Array

#     self
#   end
# end

def filesize(size)
  units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'Pib', 'EiB']

  return '0.0 B' if size == 0
  exp = (Math.log(size) / Math.log(1024)).to_i
  exp = 6 if exp > 6

  '%.1f %s' % [size.to_f / 1024 ** exp, units[exp]]
end

def countsize(size)
  units = ['', 'k', 'M', 'G', 'T', 'P', 'E']
  decimal = [0, 1, 1, 2, 2, 3, 3]
  size = size.to_i

  return '0' if size == 0
  exp = (Math.log(size) / Math.log(1000)).to_i
  exp = 6 if exp > 6

  "%.#{decimal[exp]}f %s" % [size.to_f / 1000 ** exp, units[exp]]
end

def deep_clone(object)
  Marshal.load(Marshal.dump(object))
end

def run_command(tag, name, *args)
  args << %(2>/dev/null)
  command = args.flatten.compact.join(' ')
  output = %x(#{command}).strip
  $logger.debug(tag) { "[#{name}] Command: #{command.inspect} -> #{output.inspect}" }
  output
end

# Redirect RCON output to other servers
def rcon_redirect(host, packet_fields, (player_index, command, origin_host))
  origin = Servers.find_by_name(origin_host)
  payload = packet_fields.payload.strip
  message = %(#{host}#{command}: #{payload})
  command = %(game.players[#{player_index}].print(#{message.dump}, {r = 1, g = 1, b = 1}))
  origin.rcon_command_nonblock(command, method(:rcon_print))
end

def debug?
  !!ENV['DEBUG']
end

at_exit do
  $logger.fatal(:at_exit) { 'Shutting down!' }
  ThreadPool.shutdown!
  if master?
    Servers.shutdown!
    ItemType.save
    Storage.save
  end
end

def trap_signals
  %w( INT TERM QUIT ).each do |signal|
    Signal.trap(signal, 'EXIT')
    # Signal.trap(signal) do
    #   if Thread.current.name.nil?
    #     $stderr.puts "[#{Process.pid}] Caught Signal: #{signal}"
    #   else
    #     $stderr.puts "[#{Thread.current.name}] Caught Signal: #{signal}"
    #   end
    #   exit
    # end
  end
end

def generate_port_number
  port_number = nil
  loop do
    port_number = SecureRandom.random_number(65_535 - 1_024) + 1_024
    existing_port_numbers = Servers.all.collect { |s| [s['factorio_port'], s['client_port']] }.flatten.compact
    break if !existing_port_numbers.include?(port_number)
  end
  port_number
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
        IOError,
        Net::OpenTimeout
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
        # sleep_for = attempts**2
        # sleep_for = 60 if sleep_for > 60

        # let the user know what is going on
        $logger.fatal(:exception) { "Exception: #{e.full_message}" }
        $logger.fatal(:exception) { "Sleeping for #{sleep_for} seconds then retrying...  (Attempt #{attempts} of #{max_attempts})" }

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
