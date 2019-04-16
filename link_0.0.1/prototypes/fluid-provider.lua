--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["storage-tank"])
recipe.enabled = true
recipe.name = LINK_FLUID_PROVIDER_NAME
recipe.order = string.format(LINK_FLUID_ORDER, recipe.name)
recipe.result = LINK_FLUID_PROVIDER_NAME
recipe.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["storage-tank"])
item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_FLUID_PROVIDER_NAME
item.order = string.format(LINK_FLUID_ORDER, item.name)
item.place_result = LINK_FLUID_PROVIDER_NAME
item.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
entity.minable = { mining_time = 0.5, result = LINK_FLUID_PROVIDER_NAME }
entity.name = LINK_FLUID_PROVIDER_NAME
link_add_tint(entity)

log(inspect(entity))


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
