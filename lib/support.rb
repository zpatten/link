# frozen_string_literal: true

require_relative 'support/logger'

require_relative 'support/cache'
require_relative 'support/config'

################################################################################

def external_host
  Socket.getifaddrs.map(&:addr).select(&:ipv4?).reject(&:ipv4_loopback?).reject(&:ipv4_multicast?).last.ip_address
end

class OpenStruct
  def count
    self.to_h.count
  end
end

def filesize(size)
  units = ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'Pib', 'EiB']

  return '0.0 B' if size == 0
  exp = (Math.log(size) / Math.log(1024)).to_i
  exp = 6 if exp > 6

  '%.1f %s' % [size.to_f / 1024 ** exp, units[exp]]
end

def countsize(size)
  units = [''] + %w( k M G T P E Z Y R Q )
  decimal = [0, 1, 1, 2, 2, 3, 3, 3, 3, 3]
  size = size.to_i

  return '0' if size == 0
  exp = (Math.log(size) / Math.log(1000)).to_i
  exp = units.length if exp > units.length

  "%.#{decimal[exp]}f %s" % [size.to_f / 1000 ** exp, units[exp]]
end

def deep_clone(object)
  Marshal.load(Marshal.dump(object))
end

def run_command(tag, *args)
  tag = "#{tag}.COMMAND"
  args << %(2>/dev/null)
  command = args.flatten.compact.join(' ')
  output = %x(#{command}).strip
  LinkLogger.info(tag) { "#{command.ai} -> #{output.ai}" } unless command =~ /docker inspect/
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

# def debug?
#   !!ENV['DEBUG']
# end

def generate_port_number
  port_number = nil
  existing_port_numbers = Servers.collect { |s| [s['factorio_port'], s['client_port']] }.flatten.compact
  loop do
    port_number = SecureRandom.random_number(65_535 - 1_024) + 1_024
    break unless existing_port_numbers.include?(port_number)
  end
  port_number
end
