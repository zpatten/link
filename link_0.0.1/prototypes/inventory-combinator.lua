--provider-chest.lua

local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = INVENTORY_COMBINATOR_NAME
item.place_result = INVENTORY_COMBINATOR_NAME

local inventory_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

inventory_combinator.name = INVENTORY_COMBINATOR_NAME
inventory_combinator.item_slot_count = 1024
inventory_combinator.minable = { mining_time = 0.5, result = INVENTORY_COMBINATOR_NAME }

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.enabled = true
recipe.name = INVENTORY_COMBINATOR_NAME
recipe.result = INVENTORY_COMBINATOR_NAME

data:extend{item, inventory_combinator, recipe}
