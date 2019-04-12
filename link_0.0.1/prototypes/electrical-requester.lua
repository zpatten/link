local item = table.deepcopy(data.raw.item["accumulator"])
item.name = ELECTRICAL_REQUESTER_NAME
item.place_result = ELECTRICAL_REQUESTER_NAME

local electrical_requester = table.deepcopy(data.raw["accumulator"]["accumulator"])

electrical_requester.name = ELECTRICAL_REQUESTER_NAME
electrical_requester.minable = { mining_time = 0.5, result = ELECTRICAL_REQUESTER_NAME }
electrical_requester.energy_source.buffer_capacity = ELECTRICAL_BUFFER_CAPACITY
electrical_requester.energy_source.input_flow_limit = "0kW"
electrical_requester.energy_source.output_flow_limit = ELECTRICAL_FLOW_LIMIT

local recipe = table.deepcopy(data.raw.recipe["accumulator"])
recipe.enabled = true
recipe.name = ELECTRICAL_REQUESTER_NAME
recipe.result = ELECTRICAL_REQUESTER_NAME

data:extend{item, electrical_requester, recipe}
