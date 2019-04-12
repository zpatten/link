local item = table.deepcopy(data.raw.item["accumulator"])
item.name = ELECTRICAL_PROVIDER_NAME
item.place_result = ELECTRICAL_PROVIDER_NAME

local electrical_provider = table.deepcopy(data.raw["accumulator"]["accumulator"])
electrical_provider.name = ELECTRICAL_PROVIDER_NAME
electrical_provider.minable = { mining_time = 0.5, result = ELECTRICAL_PROVIDER_NAME }
electrical_provider.energy_source.buffer_capacity = ELECTRICAL_BUFFER_CAPACITY
electrical_provider.energy_source.input_flow_limit = ELECTRICAL_FLOW_LIMIT
electrical_provider.energy_source.output_flow_limit = "0kW"

local recipe = table.deepcopy(data.raw.recipe["accumulator"])
recipe.enabled = true
recipe.name = ELECTRICAL_PROVIDER_NAME
recipe.result = ELECTRICAL_PROVIDER_NAME

data:extend{item, electrical_provider, recipe}
