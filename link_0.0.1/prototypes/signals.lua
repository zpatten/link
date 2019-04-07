local epoch = {
  icon = "__base__/graphics/icons/signal/signal_E.png",
  icon_size = 32,
  name = "signal-link-epoch",
  order = "f[link]-[epoch]",
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local local_id = {
  icon = "__base__/graphics/icons/signal/signal_L.png",
  icon_size = 32,
  name = "signal-link-local-id",
  order = "f[link]-[local-id]",
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local network_id = {
  icon = "__base__/graphics/icons/signal/signal_N.png",
  icon_size = 32,
  name = "signal-link-network-id",
  order = "f[link]-[network-id]",
  subgroup = "virtual-signal-link",
  type = "virtual-signal"
}

local source_id = {
  icon = "__base__/graphics/icons/signal/signal_S.png",
  icon_size = 32,
  name = "signal-link-source-id",
  order = "f[link]-[source-id]",
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
  epoch,
  local_id,
  network_id,
  source_id,
  subgroup,
}
