local item = table.deepcopy(data.raw.item["accumulator"])
item.name = LINK_ELECTRICAL_REQUESTER_NAME
item.place_result = LINK_ELECTRICAL_REQUESTER_NAME
item.subgroup = LINK_ELECTRICAL_SUBGROUP

local electrical_requester = table.deepcopy(data.raw["accumulator"]["accumulator"])

electrical_requester.name = LINK_ELECTRICAL_REQUESTER_NAME
electrical_requester.minable = { mining_time = 0.5, result = LINK_ELECTRICAL_REQUESTER_NAME }
electrical_requester.energy_source.buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY
electrical_requester.energy_source.input_flow_limit = "0kW"
electrical_requester.energy_source.output_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT

local recipe = table.deepcopy(data.raw.recipe["accumulator"])
recipe.enabled = true
recipe.name = LINK_ELECTRICAL_REQUESTER_NAME
recipe.result = LINK_ELECTRICAL_REQUESTER_NAME

data:extend{item, electrical_requester, recipe}
