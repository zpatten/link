--provider-chest.lua

local item = table.deepcopy(data.raw.item["logistic-chest-requester"])
item.name = REQUESTER_PROVIDER_CHEST_NAME
item.place_result = REQUESTER_PROVIDER_CHEST_NAME
-- item.icons = {
--   {
--     icon = item.icon
--   },
--   {
--     icon = "__base__/graphics/icons/logistic-chest-requester.png"
--   }
-- }

local requester_provider_chest = table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
-- local requester_provider_chest = table.deepcopy(data.raw.container["steel-chest"])

requester_provider_chest.name = REQUESTER_PROVIDER_CHEST_NAME
-- requester_provider_chest.icon = data.raw["logistic-container"]["logistic-chest-requester"].icon
requester_provider_chest.inventory = 60
requester_provider_chest.logistic_slots_count = 18
requester_provider_chest.minable = { mining_time = 0.5, result = REQUESTER_PROVIDER_CHEST_NAME }

local recipe = table.deepcopy(data.raw.recipe["logistic-chest-requester"])
recipe.enabled = true
recipe.name = REQUESTER_PROVIDER_CHEST_NAME
recipe.result = REQUESTER_PROVIDER_CHEST_NAME

data:extend{item, requester_provider_chest, recipe}
