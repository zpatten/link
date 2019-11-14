--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["logistic-chest-active-provider"])
recipe.enabled = true
recipe.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
recipe.order = string.format(LINK_CHEST_ORDER, LINK_ACTIVE_PROVIDER_CHEST_NAME)
recipe.result = LINK_ACTIVE_PROVIDER_CHEST_NAME
recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["logistic-chest-active-provider"])
-- item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
item.order = string.format(LINK_CHEST_ORDER, LINK_ACTIVE_PROVIDER_CHEST_NAME)
item.place_result = LINK_ACTIVE_PROVIDER_CHEST_NAME
item.subgroup = LINK_CHEST_SUBGROUP_NAME
link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw.container["steel-chest"])
-- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
entity.icon = data.raw["logistic-container"]["logistic-chest-active-provider"].icon
entity.inventory = 60
entity.minable = { mining_time = 0.5, result = LINK_ACTIVE_PROVIDER_CHEST_NAME }
entity.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
entity.picture = table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"].animation)
link_add_tint(entity)


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
