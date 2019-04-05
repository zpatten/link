require 'ostruct'

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

# Displays RCON response packets for debugging or other uses (i.e. when we do not care about the response)
def rcon_print(host, packet_fields, data)
  $logger.debug { "RCON Received Packet: #{packet_fields.inspect}" }
end

# Redirect RCON output to other servers
def rcon_redirect(host, packet_fields, (player_index, command, origin_host))
  origin = Servers.find_by_name(origin_host)
  payload = packet_fields.payload.strip
  message = %(#{host}#{command}: #{payload})
  command = %(/#{rcon_executor} game.players[#{player_index}].print(#{message.dump}, {r = 1, g = 1, b = 1}))
  origin.rcon_command(command, method(:rcon_print))
end

# RTT
def ping(host, packet_fields, started_at)
  # Calculate the RTT based on how much time passed from the start of the inital
  # request until we received the response here.
  rtt = (Time.now.to_f - started_at)

  # Update Factorio Servers with our current RTT
  server = Servers.find_by_name(host)
  command = %(/#{rcon_executor} remote.call('link', 'rtt', '#{rtt}'))
  server.rcon_command(command, method(:rcon_print))
  $logger.debug { "#{(rtt * 1000.0).round(0)}ms RTT - #{host}" }
end

# def threaded_task(*args, &block)
#   $threads << Thread.new do
#     next_run_at = Time.now.to_f
#     loop do
#       while (next_run_at > Time.now.to_f) do
#         sleep SLEEP_TIME
#       end

#       if (args.nil? || (args.count == 0))
#         $logger.info { "[#{what}]  next_run_at: #{next_run_at}  frequency: #{frequency}" }
#       else
#         $logger.info { "[#{what}] (#{args.first.name})  next_run_at: #{next_run_at}  frequency: #{frequency}" }
#       end

#       now = Time.now.to_f
#       next_run_at = (now + (frequency - (now % frequency)))
#       block.call(*args)
#     end
#   end
# end

def schedule_task(what, frequency=nil, server=nil, &block)
  frequency = if frequency.nil?
    Config.master.scheduler.send(what)
  else
    frequency
  end
  args = [server].compact

  $threads << Thread.new do

    next_run_at = Time.now.to_f
    loop do
      while (next_run_at > Time.now.to_f) do
        sleep SLEEP_TIME
      end

      if server.nil?
        sleep 1 while Servers.unavailable?
      else
        sleep 1 while server.unavailable?
      end

      now = Time.now.to_f
      next_run_at = (now + (frequency - (now % frequency)))

      if server.nil?
        $logger.info { "[#{what}]  next_run_at: #{next_run_at}  frequency: #{frequency}" }
      else
        $logger.info { "[#{what}] (#{server.name})  next_run_at: #{next_run_at}  frequency: #{frequency}" }
      end

      block.call(*args)
    end
  end
end

def schedule_servers(what, servers=nil, &block)
  s = if servers.nil?
    Servers.find(what)
  elsif servers.is_a?(Symbol)
    Servers.find_by(servers)
  else
    servers
  end

  $logger.info { "Scheduling #{what}..." }

  s.each do |server|
    frequency = Config.server_value(server.name, :scheduler, what)
    schedule_task(what, frequency, server, &block)
  end
end

# RCON Executor
# Switch between using 'c' or 'silent-command' depending on the debug flag.
def rcon_executor
  (debug? ? "c" : "silent-command")
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
        Errno::ECONNRESET,
        Errno::ECONNREFUSED,
        Errno::ECONNABORTED,
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
        $logger.fatal { "Exception: #{e}" }
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
