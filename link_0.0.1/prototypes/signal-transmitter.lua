--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["decider-combinator"])
recipe.enabled = true
recipe.name = LINK_TRANSMITTER_COMBINATOR_NAME
recipe.order = string.format(LINK_SIGNAL_ORDER, LINK_TRANSMITTER_COMBINATOR_NAME)
recipe.result = LINK_TRANSMITTER_COMBINATOR_NAME
recipe.subgroup = LINK_SIGNAL_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["decider-combinator"])
item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_TRANSMITTER_COMBINATOR_NAME
item.order = string.format(LINK_SIGNAL_ORDER, LINK_TRANSMITTER_COMBINATOR_NAME)
item.place_result = LINK_TRANSMITTER_COMBINATOR_NAME
item.subgroup = LINK_SIGNAL_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["decider-combinator"]["decider-combinator"])
entity.minable = { mining_time = 0.5, result = LINK_TRANSMITTER_COMBINATOR_NAME }
entity.name = LINK_TRANSMITTER_COMBINATOR_NAME
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
