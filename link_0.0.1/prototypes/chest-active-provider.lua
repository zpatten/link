--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["logistic-chest-active-provider"])
recipe.enabled = true
recipe.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
recipe.order = string.format(LINK_CHEST_ORDER, recipe.name)
recipe.result = LINK_ACTIVE_PROVIDER_CHEST_NAME
recipe.subgroup = LINK_CHEST_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["logistic-chest-active-provider"])
item.icon = data.raw["logistic-container"]["logistic-chest-active-provider"].icon
item.icons = {
  {
    icon = item.icon,
    tint = LINK_TINT
  }
}
item.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
item.order = string.format(LINK_CHEST_ORDER, item.name)
item.place_result = LINK_ACTIVE_PROVIDER_CHEST_NAME
item.subgroup = LINK_CHEST_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw.container["steel-chest"])
entity.animation = table.deepcopy(data.raw["logistic-container"]["logistic-chest-active-provider"].animation)
entity.animation.layers[1].hr_version.tint = LINK_TINT
entity.animation.layers[1].tint = LINK_TINT
entity.inventory = 60
entity.minable = { mining_time = 0.5, result = LINK_ACTIVE_PROVIDER_CHEST_NAME }
entity.name = LINK_ACTIVE_PROVIDER_CHEST_NAME
-- entity.logistic_mode = "requester"
-- entity.logistic_slots_count = 1


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
