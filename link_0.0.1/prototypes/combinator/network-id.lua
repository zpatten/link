--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.enabled = true
recipe.hidden = true
recipe.name = LINK_NETWORK_ID_COMBINATOR_NAME
recipe.order = string.format(LINK_COMBINATOR_ORDER, LINK_NETWORK_ID_COMBINATOR_NAME)
recipe.result = LINK_NETWORK_ID_COMBINATOR_NAME
recipe.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["constant-combinator"])
-- item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_NETWORK_ID_COMBINATOR_NAME
item.order = string.format(LINK_COMBINATOR_ORDER, LINK_NETWORK_ID_COMBINATOR_NAME)
item.place_result = LINK_NETWORK_ID_COMBINATOR_NAME
item.subgroup = LINK_COMBINATOR_SUBGROUP_NAME
link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
-- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
entity.item_slot_count = 1
entity.minable = { mining_time = 0.5, result = LINK_NETWORK_ID_COMBINATOR_NAME }
entity.name = LINK_NETWORK_ID_COMBINATOR_NAME
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
