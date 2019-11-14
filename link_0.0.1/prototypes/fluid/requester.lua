--------------------------------------------------------------------------------
-- FLUID RECIPE CATEGORY
--------------------------------------------------------------------------------
-- local recipe_category = link_build_recipe_category_data({}, 'fluid', 'requester')
local recipe_category = link_build_data({
  type = 'recipe-category',
  what = 'fluid',
  which = 'requester'
})


--------------------------------------------------------------------------------
-- FLUID RECIPES
--------------------------------------------------------------------------------
for _, fluid in pairs(data.raw.fluid) do
  -- local fluid_recipe = {}
  local fluid_recipe = link_build_data({
    type = 'recipe',
    name = fluid.name,
    what = 'fluid',
    which = 'requester',
    icon = fluid.icon,
    icon_size = fluid.icon_size,
    energy_required = LINK_FLUID_RECIPE_CRAFTING_TIME,
    ingredients = {
      {
        amount = LINK_FLUID_RECIPE_AMOUNT,
        name = string.format('link-fluid-%s', fluid.name),
        type = 'item'
      }
    },
    results = {
      {
        amount = LINK_FLUID_RECIPE_AMOUNT,
        name = fluid.name,
        type = 'fluid'
      }
    }
  })
  -- link_build_recipe_data(fluid_recipe, 'fluid', fluid.name)
  -- fluid_recipe.category = LINK_FLUID_REQUESTER_NAME
  -- fluid_recipe.enabled = true
  -- fluid_recipe.energy_required = LINK_FLUID_RECIPE_CRAFTING_TIME
  -- fluid_recipe.icon = fluid.icon
  -- fluid_recipe.icon_size = fluid.icon_size
  -- fluid_recipe.ingredients = {
  --   {
  --     amount = LINK_FLUID_RECIPE_AMOUNT,
  --     name = link_format_fluid_name(fluid.name),
  --     type = 'item'
  --   }
  -- }
  -- fluid_recipe.name = link_format_fluid_recipe_name(fluid.name, 'requester')
  -- fluid_recipe.order = link_format_fluid_order(fluid_recipe.name)
  -- fluid_recipe.hide_from_player_crafting = true
  -- fluid_recipe.return_ingredients_on_change = false
  -- fluid_recipe.results = {
  --   {
  --     amount = LINK_FLUID_RECIPE_AMOUNT,
  --     name = fluid.name,
  --     type = 'fluid'
  --   }
  -- }
  -- fluid_recipe.subgroup = link_format_subgroup(LINK_FLUID_SUBGROUP_NAME, 'requester')
  -- fluid_recipe.type = 'recipe'

  link_extend_data({fluid_recipe})
end


--------------------------------------------------------------------------------
-- SUBGROUP
--------------------------------------------------------------------------------
-- local recipe_subgroup = link_build_subgroup_data({}, 'fluid-recipe', 'requester')
local recipe_subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'fluid',
  which = 'requester'
})
-- local subgroup = link_build_subgroup_data({}, 'fluid', 'requester')
-- local subgroup = link_build_data({
--   type = 'item-subgroup',
--   what = 'fluid',
--   which = 'requester'
-- })


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['assembling-machine-3'],
  type = 'recipe',
  what = 'fluid',
  which = 'requester'
})
-- local recipe = table.deepcopy(data.raw.recipe['assembling-machine-3'])
-- link_build_data(recipe, 'fluid', 'requester')
-- recipe.enabled = true
-- recipe.name = LINK_FLUID_REQUESTER_NAME
-- recipe.order = link_format_fluid_order(LINK_FLUID_REQUESTER_NAME)
-- recipe.result = recipe.name
-- recipe.result = LINK_FLUID_REQUESTER_NAME
-- recipe.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['assembling-machine-3'],
  type = 'item',
  what = 'fluid',
  which = 'requester'
})
-- local item = table.deepcopy(data.raw.item['assembling-machine-3'])
-- link_build_data(item, 'fluid', 'requester')
-- item.name = LINK_FLUID_REQUESTER_NAME
-- item.order = link_format_fluid_order(LINK_FLUID_REQUESTER_NAME)
-- item.place_result = LINK_FLUID_REQUESTER_NAME
-- item.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['assembling-machine']['assembling-machine-3'],
  what = 'fluid',
  which = 'requester',
  fluid_boxes = {
    {
      base_area = LINK_FLUID_BASE_AREA,
      base_level = 1,
      pipe_connections = {
        {
          position = { 0, -2 },
          type = 'output'
        }
      },
      pipe_covers = pipecoverspictures(),
      pipe_picture = assembler3pipepictures(),
      production_type = 'output'
    }
  }
})
-- local entity = table.deepcopy(data.raw['assembling-machine']['assembling-machine-3'])
-- link_build_data(entity, 'fluid', 'requester')
-- entity.crafting_categories = { LINK_FLUID_REQUESTER_NAME }
-- entity.fluid_boxes = {
--   {
--     base_area = LINK_FLUID_BASE_AREA,
--     base_level = 1,
--     pipe_connections = {
--       {
--         position = { 0, -2 },
--         type = 'output'
--       }
--     },
--     pipe_covers = pipecoverspictures(),
--     pipe_picture = assembler3pipepictures(),
--     production_type = 'output'
--   }
-- }
-- entity.minable = { mining_time = 0.5, result = LINK_FLUID_REQUESTER_NAME }
-- entity.module_specification = { module_slots = 0 }
-- entity.name = LINK_FLUID_REQUESTER_NAME
-- entity.order = link_format_fluid_order(LINK_FLUID_REQUESTER_NAME)


link_extend_data({
  recipe_category,
  recipe_subgroup,
  recipe,
  item,
  entity
})

--------------------------------------------------------------------------------

-- log(inspect(recipe_category))
-- log(inspect(recipe_subgroup))
-- log(inspect(subgroup))
-- log(inspect(recipe))
-- log(inspect(item))
-- log(inspect(entity))

--------------------------------------------------------------------------------
-- data:extend{
--   recipe_category,
--   recipe_subgroup,
--   subgroup,
--   recipe,
--   item,
--   entity
-- }
--------------------------------------------------------------------------------
