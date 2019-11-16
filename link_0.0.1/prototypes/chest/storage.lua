local localised_description = 'Provides contents to the Link acting as a storage chest for the logistic network.'

--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-storage'],
  type = 'recipe',
  what = 'chest',
  which = 'storage',
  attributes = {
    localised_description = localised_description
  }
})

-- local recipe = table.deepcopy(data.raw.recipe["logistic-chest-storage"])
-- recipe.enabled = true
-- recipe.name = LINK_STORAGE_CHEST_NAME
-- recipe.order = string.format(LINK_CHEST_ORDER, LINK_STORAGE_CHEST_NAME)
-- recipe.result = LINK_STORAGE_CHEST_NAME
-- recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-storage'],
  type = 'item',
  what = 'chest',
  which = 'storage',
  attributes = {
    localised_description = localised_description
  }
})

-- local item = table.deepcopy(data.raw.item["logistic-chest-storage"])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_STORAGE_CHEST_NAME
-- item.order = string.format(LINK_CHEST_ORDER, LINK_STORAGE_CHEST_NAME)
-- item.place_result = LINK_STORAGE_CHEST_NAME
-- item.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-storage'],
  what = 'chest',
  which = 'storage',
  attributes = {
    inventory = 60,
    render_not_in_network_icon = false,
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw["logistic-container"]["logistic-chest-storage"])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.inventory = 60
-- entity.minable = { mining_time = 0.5, result = LINK_STORAGE_CHEST_NAME }
-- entity.name = LINK_STORAGE_CHEST_NAME
-- entity.render_not_in_network_icon = false
-- link_add_tint(entity)


link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
