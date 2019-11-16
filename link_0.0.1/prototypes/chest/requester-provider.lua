local localised_description = 'Provides contents to the Link requesting specified items from the logistic network.'

--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-requester'],
  type = 'recipe',
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    localised_description = localised_description
  }
})

-- local recipe = table.deepcopy(data.raw.recipe["logistic-chest-requester"])
-- recipe.enabled = true
-- recipe.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
-- recipe.order = string.format(LINK_CHEST_ORDER, recipe.name)
-- recipe.result = LINK_REQUESTER_PROVIDER_CHEST_NAME
-- recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-requester'],
  type = 'item',
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    localised_description = localised_description
  }
})

-- local item = table.deepcopy(data.raw.item["logistic-chest-requester"])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
-- item.order = string.format(LINK_CHEST_ORDER, item.name)
-- item.place_result = LINK_REQUESTER_PROVIDER_CHEST_NAME
-- item.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-requester'],
  what = 'chest',
  which = 'requester-provider',
  attributes = {
    inventory = 60,
    logistic_slots_count = 18,
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw["logistic-container"]["logistic-chest-requester"])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.inventory = 60
-- entity.logistic_slots_count = 18
-- entity.minable = { mining_time = 0.5, result = LINK_REQUESTER_PROVIDER_CHEST_NAME }
-- entity.name = LINK_REQUESTER_PROVIDER_CHEST_NAME
-- link_add_tint(entity)


link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
