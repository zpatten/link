local

--------------------------------------------------------------------------------
-- SIGNAL SUBGROUP
--------------------------------------------------------------------------------
local subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'signal'
})

local epoch = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'epoch',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_E.png",
    icon_size = 32,
    localised_name = 'Link UNIX EPOCH Time',
    localised_description = 'Link signal set to the current UNIX EPOCH time value.'
  }
})
-- local epoch = {
--   icons = {
--     {
--       icon = "__base__/graphics/icons/signal/signal_E.png",
--       icon_size = 32,
--       tint = LINK_TINT
--     }
--   },
--   name = LINK_SIGNAL_EPOCH_NAME,
--   order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_EPOCH_NAME),
--   subgroup = "virtual-signal-link",
--   type = "virtual-signal"
-- }

local local_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'local-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_L.png",
    icon_size = 32
    localised_name = 'Link Local Server ID',
    localised_description = 'Link signal set to the factorio server ID which is receiving the network signals.'
  }
})
-- local local_id = {
--   icons = {
--     {
--       icon = "__base__/graphics/icons/signal/signal_L.png",
--       icon_size = 32,
--       tint = LINK_TINT
--     }
--   },
--   name = LINK_SIGNAL_LOCAL_ID_NAME,
--   order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_LOCAL_ID_NAME),
--   subgroup = "virtual-signal-link",
--   type = "virtual-signal"
-- }

local network_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'network-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_N.png",
    icon_size = 32
    localised_name = 'Link Network ID',
    localised_description = 'Link signal set to the ID of the Link signal network to be transmitted or received.'
  }
})
-- local network_id = {
--   icons = {
--     {
--       icon = "__base__/graphics/icons/signal/signal_N.png",
--       icon_size = 32,
--       tint = LINK_TINT
--     }
--   },
--   name = LINK_SIGNAL_NETWORK_ID_NAME,
--   order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_NETWORK_ID_NAME),
--   subgroup = "virtual-signal-link",
--   type = "virtual-signal"
-- }

local source_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'source-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_S.png",
    icon_size = 32,
    localised_name = 'Link Source Server ID',
    localised_description = 'Link signal set to the factorio server ID which is transmitting the network signals.  If more than one factorio server is transmitting to this signal network this value will be unreliable.'
  }
})
-- local source_id = {
--   icons = {
--     {
--       icon = "__base__/graphics/icons/signal/signal_S.png",
--       icon_size = 32,
--       tint = LINK_TINT
--     }
--   },
--   name = LINK_SIGNAL_SOURCE_ID_NAME,
--   order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_SOURCE_ID_NAME),
--   subgroup = "virtual-signal-link",
--   type = "virtual-signal"
-- }

local electricity = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'electricity',
  attributes = {
    icons = {
      -- {
      --   icon = "__base__/graphics/icons/signal/shape_square.png",
      --   icon_size = 32
      -- },
      {
        icon = "__base__/graphics/icons/signal/signal_G.png",
        icon_size = 32,
        scale = 0.5,
        shift = {
          -7,
          0
        }
      },
      {
        icon = "__base__/graphics/icons/signal/signal_J.png",
        icon_size = 32,
        scale = 0.5,
        shift = {
          7,
          0
        }
      }
    },
    localised_name = 'Link Electricity',
    localised_description = 'Link signal set to the amount of electricity stored in the Link.  This value is in Gigajoules (GJ).'
  }
})
-- local electricity = {
--   icons = {
--     {
--       icon = "__base__/graphics/icons/signal/signal_X.png",
--       icon_size = 32,
--       tint = LINK_TINT
--     }
--   },
--   name = LINK_SIGNAL_ELECTRICITY_NAME,
--   order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_ELECTRICITY_NAME),
--   subgroup = "virtual-signal-link",
--   type = "virtual-signal"
-- }

-- local subgroup = link_build_data({
--   type = 'item-subgroup',
--   what = 'signal'
-- })
-- link_extend_data({subgroup})

-- local subgroup = {
--   group = "signals",
--   name = "virtual-signal-link",
--   order = "f",
--   type = "item-subgroup"
-- }
print(string.format("--------------------\n%s\n", serpent.block(electricity)))
print(string.format("--------------------\n%s\n", serpent.block(epoch)))
print(string.format("--------------------\n%s\n", serpent.block(local_id)))
print(string.format("--------------------\n%s\n", serpent.block(network_id)))
print(string.format("--------------------\n%s\n", serpent.block(source_id)))

link_extend_data({
  subgroup,
  electricity,
  epoch,
  local_id,
  network_id,
  source_id
})
