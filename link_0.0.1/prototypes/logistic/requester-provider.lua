--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["logistic-chest-requester"])
recipe.enabled = true
recipe.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
recipe.order = string.format(LINK_CHEST_ORDER, recipe.name)
recipe.result = LINK_REQUESTER_PROVIDER_CHEST_NAME
recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["logistic-chest-requester"])
-- item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
item.order = string.format(LINK_CHEST_ORDER, item.name)
item.place_result = LINK_REQUESTER_PROVIDER_CHEST_NAME
item.subgroup = LINK_CHEST_SUBGROUP_NAME
link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
-- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
entity.inventory = 60
entity.logistic_slots_count = 18
entity.minable = { mining_time = 0.5, result = LINK_REQUESTER_PROVIDER_CHEST_NAME }
entity.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
