local epoch = {
  icons = {
    {
      icon = "__base__/graphics/icons/signal/signal_E.png",
      icon_size = 32,
      tint = LINK_TINT
    }
  },
  name = LINK_SIGNAL_EPOCH_NAME,
  order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_EPOCH_NAME),
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local local_id = {
  icons = {
    {
      icon = "__base__/graphics/icons/signal/signal_L.png",
      icon_size = 32,
      tint = LINK_TINT
    }
  },
  name = LINK_SIGNAL_LOCAL_ID_NAME,
  order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_LOCAL_ID_NAME),
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local network_id = {
  icons = {
    {
      icon = "__base__/graphics/icons/signal/signal_N.png",
      icon_size = 32,
      tint = LINK_TINT
    }
  },
  name = LINK_SIGNAL_NETWORK_ID_NAME,
  order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_NETWORK_ID_NAME),
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local source_id = {
  icons = {
    {
      icon = "__base__/graphics/icons/signal/signal_S.png",
      icon_size = 32,
      tint = LINK_TINT
    }
  },
  name = LINK_SIGNAL_SOURCE_ID_NAME,
  order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_SOURCE_ID_NAME),
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local electricity = {
  icons = {
    {
      icon = "__base__/graphics/icons/signal/signal_X.png",
      icon_size = 32,
      tint = LINK_TINT
    }
  },
  name = LINK_SIGNAL_ELECTRICITY_NAME,
  order = string.format(LINK_SIGNAL_ORDER, LINK_SIGNAL_ELECTRICITY_NAME),
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local subgroup = {
  group = "signals",
  name = "virtual-signal-link",
  order = "f",
  type = "item-subgroup"
}

data:extend{
  electricity,
  epoch,
  local_id,
  network_id,
  source_id,
  subgroup
}
