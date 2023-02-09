--------------------------------------------------------------------------------
-- SIGNAL SUBGROUP
--------------------------------------------------------------------------------
local subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'signal'
})


--------------------------------------------------------------------------------
-- ELECTRICITY SIGNAL
--------------------------------------------------------------------------------
local electricity = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'electricity',
  attributes = {
    icons = {
      {
        icon = "__base__/graphics/icons/signal/signal_blue.png",
        icon_size = 64
      },
      {
        icon = "__base__/graphics/icons/signal/signal_G.png",
        icon_size = 64,
        scale = 0.5,
        shift = {
          -10,
          0
        }
      },
      {
        icon = "__base__/graphics/icons/signal/signal_J.png",
        icon_size = 64,
        scale = 0.5,
        shift = {
          10,
          0
        }
      }
    },
    localised_name = 'Link Electricity',
    localised_description = 'Link signal set to the amount of electricity stored in the Link.  This value is in Gigajoules (GJ).'
  }
})


--------------------------------------------------------------------------------
-- EPOCH SIGNAL
--------------------------------------------------------------------------------
local epoch = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'epoch',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_E.png",
    icon_size = 64,
    localised_name = 'Link UNIX EPOCH Time',
    localised_description = 'Link signal set to the current UNIX EPOCH time value.'
  }
})


--------------------------------------------------------------------------------
-- LOCAL ID SIGNAL
--------------------------------------------------------------------------------
local local_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'local-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_L.png",
    icon_size = 64,
    localised_name = 'Link Local Server ID',
    localised_description = 'Link signal set to the factorio server ID which is receiving the network signals.'
  }
})


--------------------------------------------------------------------------------
-- NETWORK ID SIGNAL
--------------------------------------------------------------------------------
local network_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'network-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_N.png",
    icon_size = 64,
    localised_name = 'Link Network ID',
    localised_description = 'Link signal set to the ID of the Link signal network to be transmitted or received.'
  }
})


--------------------------------------------------------------------------------
-- SOURCE ID SIGNAL
--------------------------------------------------------------------------------
local source_id = link_build_data({
  type = 'virtual-signal',
  what = 'signal',
  which = 'source-id',
  attributes = {
    icon = "__base__/graphics/icons/signal/signal_S.png",
    icon_size = 64,
    localised_name = 'Link Source Server ID',
    localised_description = 'Link signal set to the factorio server ID which is transmitting the network signals.  If more than one factorio server is transmitting to this signal network this value will be unreliable.'
  }
})


--------------------------------------------------------------------------------
link_extend_data({
  subgroup,
  electricity,
  epoch,
  local_id,
  network_id,
  source_id
})
--------------------------------------------------------------------------------
