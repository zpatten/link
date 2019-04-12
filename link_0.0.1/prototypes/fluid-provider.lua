local item = table.deepcopy(data.raw.item["assembling-machine-3"])
item.name = FLUID_PROVIDER_NAME
item.place_result = FLUID_PROVIDER_NAME

local fluid_provider = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
fluid_provider.name = FLUID_PROVIDER_NAME
fluid_provider.minable = { mining_time = 0.5, result = FLUID_PROVIDER_NAME }

local recipe = table.deepcopy(data.raw.recipe["assembling-machine-3"])
recipe.enabled = true
recipe.name = FLUID_PROVIDER_NAME
recipe.result = FLUID_PROVIDER_NAME

data:extend{item, fluid_provider, recipe}
