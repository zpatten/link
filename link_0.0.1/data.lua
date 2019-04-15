require "constants"
require "support"
require "util"

function link_add_tint(o)
  if o.animation then
    o.animation.layers[1].hr_version.tint = LINK_TINT
    o.animation.layers[1].tint = LINK_TINT
  elseif o.sprites then
    for _, direction in pairs(o.sprites) do
      direction.layers[1].hr_version.tint = LINK_TINT
      direction.layers[1].tint = LINK_TINT
    end
  end
end

require "prototypes.link-groups"

require "prototypes.chest-active-provider"
require "prototypes.chest-buffer"
require "prototypes.chest-requester-provider"

require "prototypes.signals"

require "prototypes.combinator-inventory"
require "prototypes.combinator-network-id"

require "prototypes.signal-receiver"
require "prototypes.signal-transmitter"

require "prototypes.fluid-provider"
require "prototypes.fluid-requester"

require "prototypes.electrical-provider"
require "prototypes.electrical-requester"
