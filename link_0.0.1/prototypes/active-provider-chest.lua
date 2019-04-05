--provider-chest.lua

local item = table.deepcopy(data.raw.item["logistic-chest-active-provider"])
item.name = ACTIVE_PROVIDER_CHEST_NAME
item.place_result = ACTIVE_PROVIDER_CHEST_NAME
-- item.icons = table.deepcopy(data.raw.item["logistic-chest-active-provider"].icons)
-- item.icons = {
--   {
--     icon = item.icon
--   },
--   {
--     icon = "__base__/graphics/icons/logistic-chest-active-provider.png"
--   }
-- }

local active_provider_chest = table.deepcopy(data.raw.container["steel-chest"])
-- local active_provider_chest = table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"])

active_provider_chest.name = ACTIVE_PROVIDER_CHEST_NAME
active_provider_chest.icon = data.raw["logistic-container"]["logistic-chest-active-provider"].icon
active_provider_chest.inventory = 60
active_provider_chest.animation = data.raw["logistic-container"]["logistic-chest-active-provider"].animation
-- active_provider_chest.logistic_mode = "requester"
-- active_provider_chest.logistic_slots_count = 1
active_provider_chest.minable = { mining_time = 4, result = ACTIVE_PROVIDER_CHEST_NAME }

local recipe = table.deepcopy(data.raw.recipe["logistic-chest-active-provider"])
recipe.enabled = true
recipe.name = ACTIVE_PROVIDER_CHEST_NAME
recipe.result = ACTIVE_PROVIDER_CHEST_NAME

data:extend{item, active_provider_chest, recipe}
