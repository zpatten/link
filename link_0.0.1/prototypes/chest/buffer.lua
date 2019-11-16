local localised_description = 'Requests from the Link inventory acting as a buffer chest for logistic networks'

--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['logistic-chest-buffer'],
  type = 'recipe',
  what = 'chest',
  which = 'buffer',
  attributes = {
    localised_description = localised_description
  }
})

-- local recipe = table.deepcopy(data.raw.recipe['logistic-chest-buffer'])
-- recipe.enabled = true
-- recipe.name = LINK_BUFFER_CHEST_NAME
-- recipe.order = string.format(LINK_CHEST_ORDER, LINK_BUFFER_CHEST_NAME)
-- recipe.result = LINK_BUFFER_CHEST_NAME
-- recipe.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['logistic-chest-buffer'],
  type = 'item',
  what = 'chest',
  which = 'buffer',
  attributes = {
    localised_description = localised_description
  }
})

-- local item = table.deepcopy(data.raw.item['logistic-chest-buffer'])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_BUFFER_CHEST_NAME
-- item.order = string.format(LINK_CHEST_ORDER, LINK_BUFFER_CHEST_NAME)
-- item.place_result = LINK_BUFFER_CHEST_NAME
-- item.subgroup = LINK_CHEST_SUBGROUP_NAME
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['logistic-container']['logistic-chest-buffer'],
  what = 'chest',
  which = 'buffer',
  attributes = {
    inventory = 60,
    logistic_slots_count = 18,
    render_not_in_network_icon = false,
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw['logistic-container']['logistic-chest-buffer'])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.inventory = 60
-- entity.logistic_slots_count = 18
-- entity.minable = { mining_time = 0.5, result = LINK_BUFFER_CHEST_NAME }
-- entity.name = LINK_BUFFER_CHEST_NAME
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
