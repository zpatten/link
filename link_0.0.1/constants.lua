--------------------------------------------------------------------------------

LINK_FORMAT_NAME = 'link-%s-%s'
LINK_FORMAT_ORDER = '%s-[%s]'
LINK_FORMAT_SUBGROUP = 'link-%s-subgroup'
LINK_GROUP = "link-group"

--------------------------------------------------------------------------------

LINK_GROUP_NAME = "link-group"

--------------------------------------------------------------------------------

LINK_ACTIVE_PROVIDER_CHEST_NAME = "link-active-provider-chest"
LINK_BUFFER_CHEST_NAME = "link-buffer-chest"
LINK_REQUESTER_PROVIDER_CHEST_NAME = "link-requester-provider-chest"
LINK_STORAGE_CHEST_NAME = "link-storage-chest"

LINK_CHEST_ORDER = "a-[link-%s]"
LINK_CHEST_SUBGROUP_NAME = "link-chest-subgroup"

--------------------------------------------------------------------------------

LINK_INVENTORY_COMBINATOR_NAME = "link-inventory-combinator"
LINK_NETWORK_ID_COMBINATOR_NAME = "link-network-id-combinator"
LINK_RECEIVER_COMBINATOR_NAME = "link-receiver-combinator"
LINK_TRANSMITTER_COMBINATOR_NAME = "link-transmitter-combinator"

LINK_COMBINATOR_ORDER = "c-[link-%s]"
LINK_COMBINATOR_SUBGROUP_NAME = "link-combinator-subgroup"

--------------------------------------------------------------------------------

LINK_ELECTRICAL_PROVIDER_NAME = "link-electrical-provider"
LINK_ELECTRICAL_REQUESTER_NAME = "link-electrical-requester"

LINK_ELECTRICAL_ORDER = "e-[link-%s]"
LINK_ELECTRICAL_SUBGROUP = "link-electrical-subgroup"

LINK_ELECTRICAL_BUFFER_CAPACITY = "10GJ"
LINK_ELECTRICAL_FLOW_LIMIT = "1GW"
LINK_ELECTRICAL_ITEM_NAME = "electricity"

--------------------------------------------------------------------------------

LINK_FLUID_PROVIDER_NAME = "link-fluid-provider"
LINK_FLUID_REQUESTER_NAME = "link-fluid-requester"

LINK_FLUID_ORDER_FORMAT = "f-[link-%s]"
LINK_FLUID_PREFIX = "link-fluid"
LINK_FLUID_SUBGROUP_NAME = "link-fluid-subgroup"

LINK_FLUID_RECIPE_REQUESTER_SUBGROUP_NAME = "link-fluid-provider-recipe-subgroup"

LINK_FLUID_RECIPE_PROVIDER_SUBGROUP_NAME = "link-fluid-requester-recipe-subgroup"

LINK_FLUID_RECIPE_AMOUNT = 1000
LINK_FLUID_RECIPE_CRAFTING_TIME = 0.1

LINK_FLUID_BASE_AREA = LINK_FLUID_RECIPE_AMOUNT / 100

--------------------------------------------------------------------------------

LINK_SIGNAL_ELECTRICITY_NAME = "signal-link-electricity"
LINK_SIGNAL_EPOCH_NAME = "signal-link-epoch"
LINK_SIGNAL_LOCAL_ID_NAME = "signal-link-local-id"
LINK_SIGNAL_NETWORK_ID_NAME = "signal-link-network-id"
LINK_SIGNAL_SOURCE_ID_NAME = "signal-link-source-id"

LINK_SIGNAL_ORDER = "s-[link-%s]"
LINK_SIGNAL_SUBGROUP_NAME = "link-signal-subgroup"

--------------------------------------------------------------------------------

-- LINK_TINT = { r = 221 / 255, g = 160 / 255, b = 221 / 255 }
LINK_TINT = { r = 238 / 255, g = 130 / 255, b = 238 / 255, a = 1 }

--------------------------------------------------------------------------------

LINK_EVENT_FILTER = {
  { filter = "name", name = LINK_ACTIVE_PROVIDER_CHEST_NAME },
  { filter = "name", name = LINK_BUFFER_CHEST_NAME },
  { filter = "name", name = LINK_REQUESTER_PROVIDER_CHEST_NAME },
  { filter = "name", name = LINK_STORAGE_CHEST_NAME },

  { filter = "name", name = LINK_FLUID_PROVIDER_NAME },
  { filter = "name", name = LINK_FLUID_REQUESTER_NAME },

  { filter = "name", name = LINK_ELECTRICAL_PROVIDER_NAME },
  { filter = "name", name = LINK_ELECTRICAL_REQUESTER_NAME },

  { filter = "name", name = LINK_INVENTORY_COMBINATOR_NAME },
  { filter = "name", name = LINK_RECEIVER_COMBINATOR_NAME },
  { filter = "name", name = LINK_TRANSMITTER_COMBINATOR_NAME }
}
