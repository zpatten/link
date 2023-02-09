--------------------------------------------------------------------------------

LINK_ACTIVE_PROVIDER_CHEST_NAME = 'link-chest-active-provider'
LINK_BUFFER_CHEST_NAME = 'link-chest-buffer'
LINK_REQUESTER_PROVIDER_CHEST_NAME = 'link-chest-requester-provider'
LINK_STORAGE_CHEST_NAME = 'link-chest-storage'

--------------------------------------------------------------------------------

LINK_INVENTORY_COMBINATOR_NAME = 'link-combinator-inventory'
LINK_NETWORK_ID_COMBINATOR_NAME = 'link-combinator-network-id'
LINK_RECEIVER_COMBINATOR_NAME = 'link-combinator-receiver'
LINK_TRANSMITTER_COMBINATOR_NAME = 'link-combinator-transmitter'

--------------------------------------------------------------------------------

LINK_ELECTRICAL_PROVIDER_NAME = 'link-electrical-provider'
LINK_ELECTRICAL_REQUESTER_NAME = 'link-electrical-requester'

LINK_GIGAJOULE = 1000000000
LINK_ELECTRICAL_BUFFER_CAPACITY = '10GJ'
LINK_ELECTRICAL_FLOW_LIMIT = '1GW'
LINK_ELECTRICAL_ITEM_NAME = 'electricity'

--------------------------------------------------------------------------------

LINK_FLUID_PROVIDER_NAME = 'link-fluid-provider'
LINK_FLUID_REQUESTER_NAME = 'link-fluid-requester'

LINK_FLUID_RECIPE_AMOUNT = 1000
LINK_FLUID_RECIPE_CRAFTING_TIME = 0.1

LINK_FLUID_BASE_AREA = LINK_FLUID_RECIPE_AMOUNT / 100

--------------------------------------------------------------------------------

LINK_SHORTCUT_GUI = 'link-shortcut-gui'

--------------------------------------------------------------------------------

-- LINK_TINT = { r = 221 / 255, g = 160 / 255, b = 221 / 255 }
-- LINK_TINT = { r = 0 / 255, g = 255 / 255, b = 255 / 255, a = 1 }
LINK_TINT = { r = 1, g = 1, b = 1, a = 0.5 }

LINK_TINT_BLUE = { r = 173 / 255, g = 216 / 255, b = 230 / 255 }
LINK_TINT_GREEN = { r = 144 / 255, g = 238 / 255, b = 144 / 255 }
LINK_TINT_PURPLE = { r = 197 / 255, g = 139 / 255, b = 231 / 255 }
LINK_TINT_YELLOW = { r = 1, g = 1 }
LINK_TINT_RED = { r = 240 / 255, g = 128 / 255, b = 128 / 255 }
-- { r = 1, g = 64 / 255, b = 64 / 255 }

LINK_TINTS = {}
LINK_TINTS['link-chest-active-provider'] = LINK_TINT_PURPLE
LINK_TINTS['link-chest-buffer'] = LINK_TINT_GREEN
LINK_TINTS['link-chest-requester-provider'] = LINK_TINT_BLUE
LINK_TINTS['link-chest-storage'] = LINK_TINT_YELLOW
LINK_TINTS['link-combinator-inventory'] = LINK_TINT_YELLOW
LINK_TINTS['link-combinator-receiver'] = LINK_TINT_BLUE
LINK_TINTS['link-combinator-transmitter'] = LINK_TINT_RED
LINK_TINTS['link-electrical-provider'] = LINK_TINT_RED
LINK_TINTS['link-electrical-requester'] = LINK_TINT_BLUE
LINK_TINTS['link-fluid-provider'] = LINK_TINT_RED
LINK_TINTS['link-fluid-requester'] = LINK_TINT_BLUE

--------------------------------------------------------------------------------

LINK_EVENT_FILTER = {
  { filter = 'name', name = LINK_ACTIVE_PROVIDER_CHEST_NAME },
  { filter = 'name', name = LINK_BUFFER_CHEST_NAME },
  { filter = 'name', name = LINK_REQUESTER_PROVIDER_CHEST_NAME },
  { filter = 'name', name = LINK_STORAGE_CHEST_NAME },

  { filter = 'name', name = LINK_FLUID_PROVIDER_NAME },
  { filter = 'name', name = LINK_FLUID_REQUESTER_NAME },

  { filter = 'name', name = LINK_ELECTRICAL_PROVIDER_NAME },
  { filter = 'name', name = LINK_ELECTRICAL_REQUESTER_NAME },

  { filter = 'name', name = LINK_INVENTORY_COMBINATOR_NAME },
  { filter = 'name', name = LINK_RECEIVER_COMBINATOR_NAME },
  { filter = 'name', name = LINK_TRANSMITTER_COMBINATOR_NAME }
}

--------------------------------------------------------------------------------
