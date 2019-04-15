local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = LINK_INVENTORY_COMBINATOR_NAME
item.place_result = LINK_INVENTORY_COMBINATOR_NAME
item.subgroup = LINK_SIGNAL_SUBGROUP_NAME

local inventory_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
inventory_combinator.name = LINK_INVENTORY_COMBINATOR_NAME
inventory_combinator.item_slot_count = 1024
inventory_combinator.minable = { mining_time = 0.5, result = LINK_INVENTORY_COMBINATOR_NAME }

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.enabled = true
recipe.name = LINK_INVENTORY_COMBINATOR_NAME
recipe.result = LINK_INVENTORY_COMBINATOR_NAME

data:extend{item, inventory_combinator, recipe}
