local item = table.deepcopy(data.raw.item["assembling-machine-3"])
item.name = FLUID_REQUESTER_NAME
item.place_result = FLUID_REQUESTER_NAME

local fluid_requester = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
fluid_requester.name = FLUID_REQUESTER_NAME
fluid_requester.minable = { mining_time = 0.5, result = FLUID_REQUESTER_NAME }

local recipe = table.deepcopy(data.raw.recipe["assembling-machine-3"])
recipe.enabled = true
recipe.name = FLUID_REQUESTER_NAME
recipe.result = FLUID_REQUESTER_NAME

data:extend{item, fluid_requester, recipe}
