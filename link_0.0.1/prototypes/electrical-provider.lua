--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["accumulator"])
recipe.enabled = true
recipe.name = LINK_ELECTRICAL_PROVIDER_NAME
recipe.order = string.format(LINK_ELECTRICAL_ORDER, recipe.name)
recipe.result = LINK_ELECTRICAL_PROVIDER_NAME
recipe.subgroup = LINK_ELECTRICAL_SUBGROUP


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["accumulator"])
item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_ELECTRICAL_PROVIDER_NAME
item.order = string.format(LINK_ELECTRICAL_ORDER, item.name)
item.place_result = LINK_ELECTRICAL_PROVIDER_NAME
item.subgroup = LINK_ELECTRICAL_SUBGROUP


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["accumulator"]["accumulator"])
entity.energy_source.buffer_capacity = LINK_ELECTRICAL_BUFFER_CAPACITY
entity.energy_source.input_flow_limit = LINK_ELECTRICAL_FLOW_LIMIT
entity.energy_source.output_flow_limit = "0kW"
entity.minable = { mining_time = 0.5, result = LINK_ELECTRICAL_PROVIDER_NAME }
entity.name = LINK_ELECTRICAL_PROVIDER_NAME
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
