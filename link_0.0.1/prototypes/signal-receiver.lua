--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["constant-combinator"])
recipe.enabled = true
recipe.name = LINK_RECEIVER_COMBINATOR_NAME
recipe.order = string.format(LINK_SIGNAL_ORDER, LINK_RECEIVER_COMBINATOR_NAME)
recipe.result = LINK_RECEIVER_COMBINATOR_NAME
recipe.subgroup = LINK_SIGNAL_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["constant-combinator"])
item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_RECEIVER_COMBINATOR_NAME
item.order = string.format(LINK_SIGNAL_ORDER, LINK_RECEIVER_COMBINATOR_NAME)
item.place_result = LINK_RECEIVER_COMBINATOR_NAME
item.subgroup = LINK_SIGNAL_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"])
entity.item_slot_count = 1024
entity.minable = { mining_time = 0.5, result = LINK_RECEIVER_COMBINATOR_NAME }
entity.name = LINK_RECEIVER_COMBINATOR_NAME
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
