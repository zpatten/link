require_relative 'signals/receive'
require_relative 'signals/support'
require_relative 'signals/transmit'

module Factorio
  class Signals
    extend Factorio::Signals::Receive
    extend Factorio::Signals::Support
    extend Factorio::Signals::Transmit
  end
end
