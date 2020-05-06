require_relative 'signals/receive'
require_relative 'signals/support'
require_relative 'signals/transmit'

class Link
  class Signals
    extend Link::Signals::Receive
    extend Link::Signals::Support
    extend Link::Signals::Transmit
  end
end
