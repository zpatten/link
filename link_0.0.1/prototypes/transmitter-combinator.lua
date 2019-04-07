--provider-chest.lua

local item = table.deepcopy(data.raw.item["decider-combinator"])
item.name = TRANSMITTER_COMBINATOR_NAME
item.place_result = TRANSMITTER_COMBINATOR_NAME

local transmitter_combinator = table.deepcopy(data.raw["decider-combinator"]["decider-combinator"])

transmitter_combinator.name = TRANSMITTER_COMBINATOR_NAME
transmitter_combinator.minable = { mining_time = 0.5, result = TRANSMITTER_COMBINATOR_NAME }

local recipe = table.deepcopy(data.raw.recipe["decider-combinator"])
recipe.enabled = true
recipe.name = TRANSMITTER_COMBINATOR_NAME
recipe.result = TRANSMITTER_COMBINATOR_NAME

data:extend{item, transmitter_combinator, recipe}
