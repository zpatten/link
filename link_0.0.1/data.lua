require "constants"
require "support"
require "util"

function link_add_tint(o)
  -- EVERYTHING ELSE
  if o.picture then
    for _, layer in pairs(o.picture.layers) do
      layer.hr_version.tint = LINK_TINT
      layer.tint = LINK_TINT
    end
  end

  if o.pictures and o.pictures.picture then
    for _, layer in pairs(o.pictures.picture.sheets) do
      layer.hr_version.tint = LINK_TINT
      layer.tint = LINK_TINT
    end
  end

  if o.animation then
    for _, layer in pairs(o.animation.layers) do
      layer.hr_version.tint = LINK_TINT
      layer.tint = LINK_TINT
    end
  end

  if o.sprites then
    for _, direction in pairs(o.sprites) do
      for _, layer in pairs(direction.layers) do
        layer.hr_version.tint = LINK_TINT
        layer.tint = LINK_TINT
      end
    end
  end

  -- TANKS
  if o.fluid_box and o.fluid_box.pipe_covers then
    for _, direction in pairs(o.fluid_box.pipe_covers) do
      for _, layer in pairs(direction.layers) do
        layer.hr_version.tint = LINK_TINT
        layer.tint = LINK_TINT
      end
    end
  end

  -- ASSEMBLERS
  if o.fluid_boxes then
    for _, fluid_box in pairs(o.fluid_boxes) do
      if type(fluid_box) == "table" then
        if fluid_box.pipe_covers then
          for _, direction in pairs(fluid_box.pipe_covers) do
            for _, layer in pairs(direction.layers) do
              layer.hr_version.tint = LINK_TINT
              layer.tint = LINK_TINT
            end
          end
        end
        if fluid_box.pipe_picture then
          for _, direction in pairs(fluid_box.pipe_picture) do
            direction.hr_version.tint = LINK_TINT
            direction.tint = LINK_TINT
          end
        end
      end
    end
  end
end

require "prototypes.link-groups"

require "prototypes.chest-active-provider"
require "prototypes.chest-buffer"
require "prototypes.chest-requester-provider"
require "prototypes.chest-storage"

require "prototypes.fluid-items"
require "prototypes.fluid-provider"
require "prototypes.fluid-requester"

require "prototypes.electrical-provider"
require "prototypes.electrical-requester"

require "prototypes.signals"

require "prototypes.combinator-inventory"
require "prototypes.combinator-network-id"

require "prototypes.signal-receiver"
require "prototypes.signal-transmitter"
