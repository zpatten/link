local item = table.deepcopy(data.raw.item["logistic-chest-buffer"])
item.name = BUFFER_CHEST_NAME
item.place_result = BUFFER_CHEST_NAME
-- item.icons = {
--   {
--     icon = item.icon
--   },
--   {
--     icon = "__base__/graphics/icons/logistic-chest-buffer.png"
--   }
-- }

local buffer_chest = table.deepcopy(data.raw["logistic-container"]["logistic-chest-buffer"])
-- local buffer_chest = table.deepcopy(data.raw.container["steel-chest"])

buffer_chest.name = BUFFER_CHEST_NAME
-- buffer_chest.icon = data.raw["logistic-container"]["logistic-chest-buffer"].icon
buffer_chest.inventory = 60
buffer_chest.logistic_slots_count = 18
buffer_chest.minable = { mining_time = 0.5, result = BUFFER_CHEST_NAME }

local recipe = table.deepcopy(data.raw.recipe["logistic-chest-buffer"])
recipe.enabled = true
recipe.name = BUFFER_CHEST_NAME
recipe.result = BUFFER_CHEST_NAME

data:extend{item, buffer_chest, recipe}
