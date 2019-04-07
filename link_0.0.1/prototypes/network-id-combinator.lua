local item = table.deepcopy(data.raw.item["constant-combinator"])
item.name = NETWORK_ID_COMBINATOR_NAME
item.place_result = NETWORK_ID_COMBINATOR_NAME

local receiver_combinator = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])

receiver_combinator.name = NETWORK_ID_COMBINATOR_NAME
receiver_combinator.item_slot_count = 1
receiver_combinator.minable = { mining_time = 0.5, result = NETWORK_ID_COMBINATOR_NAME }

local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.enabled = true
recipe.name = NETWORK_ID_COMBINATOR_NAME
recipe.result = NETWORK_ID_COMBINATOR_NAME

data:extend{item, receiver_combinator, recipe}
