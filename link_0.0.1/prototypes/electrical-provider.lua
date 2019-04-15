local item = table.deepcopy(data.raw.item["accumulator"])
item.name = LINK_ELECTRICAL_PROVIDER_NAME
item.place_result = LINK_ELECTRICAL_PROVIDER_NAME
item.subgroup = LINK_ELECTRICAL_SUBGROUP

local electrical_provider = table.deepcopy(data.raw["accumulator"]["accumulator"])
electrical_provider.name = LINK_ELECTRICAL_PROVIDER_NAME
electrical_provider.minable = { mining_time = 0.5, result = LINK_ELECTRICAL_PROVIDER_NAME }
electrical_provider.energy_source.buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY
electrical_provider.energy_source.input_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT
electrical_provider.energy_source.output_flow_limit = "0kW"

local recipe = table.deepcopy(data.raw.recipe["accumulator"])
recipe.enabled = true
recipe.name = LINK_ELECTRICAL_PROVIDER_NAME
recipe.result = LINK_ELECTRICAL_PROVIDER_NAME

data:extend{item, electrical_provider, recipe}
