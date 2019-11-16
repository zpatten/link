local localised_description = 'Transmits signals to a Link circuit network.'

--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['decider-combinator'],
  type = 'recipe',
  what = 'combinator',
  which = 'transmitter',
  attributes = {
    localised_description = localised_description
  }
})

-- local recipe = table.deepcopy(data.raw.recipe["decider-combinator"])
-- recipe.enabled = true
-- recipe.name = LINK_TRANSMITTER_COMBINATOR_NAME
-- recipe.order = string.format(LINK_SIGNAL_ORDER, LINK_TRANSMITTER_COMBINATOR_NAME)
-- recipe.result = LINK_TRANSMITTER_COMBINATOR_NAME
-- recipe.subgroup = LINK_SIGNAL_SUBGROUP_NAME
-- link_add_tint(recipe)


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['decider-combinator'],
  type = 'item',
  what = 'combinator',
  which = 'transmitter',
  attributes = {
    localised_description = localised_description
  }
})

-- local item = table.deepcopy(data.raw.item["decider-combinator"])
-- -- item.icons = { { icon = item.icon, tint = LINK_TINT } }
-- item.name = LINK_TRANSMITTER_COMBINATOR_NAME
-- item.order = string.format(LINK_SIGNAL_ORDER, LINK_TRANSMITTER_COMBINATOR_NAME)
-- item.place_result = LINK_TRANSMITTER_COMBINATOR_NAME
-- item.subgroup = LINK_SIGNAL_SUBGROUP_NAME
-- link_add_tint(item)


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['decider-combinator']['decider-combinator'],
  what = 'combinator',
  which = 'transmitter',
  attributes = {
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw["decider-combinator"]["decider-combinator"])
-- -- entity.icons = { { icon = entity.icon, tint = LINK_TINT } }
-- entity.minable = { mining_time = 0.5, result = LINK_TRANSMITTER_COMBINATOR_NAME }
-- entity.name = LINK_TRANSMITTER_COMBINATOR_NAME
-- link_add_tint(entity)

link_extend_data({
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------
-- data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
