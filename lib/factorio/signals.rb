require_relative 'signals/receive'
require_relative 'signals/support'
require_relative 'signals/transmit'

class Signals
  extend Signals::Receive
  extend Signals::Support
  extend Signals::Transmit
end
