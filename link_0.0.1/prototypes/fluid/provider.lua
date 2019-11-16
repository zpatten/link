local localised_description = 'Provides fluids to the Link inventory'

--------------------------------------------------------------------------------
-- FLUID RECIPE CATEGORY
--------------------------------------------------------------------------------
-- local recipe_category = link_build_recipe_category_data({}, 'fluid', 'provider')
local recipe_category = link_build_data({
  type = 'recipe-category',
  what = 'fluid',
  which = 'provider'
})


--------------------------------------------------------------------------------
-- FLUID RECIPES
--------------------------------------------------------------------------------
for _, fluid in pairs(data.raw.fluid) do
  local localised_name = string.format('Link %s Provider', fluid.name)
  local localised_description = string.format('Converts %s to Link %s so it can be provided to the Link inventory', fluid.name, fluid.name)

  local fluid_recipe = link_build_data({
    type = 'recipe',
    name = fluid.name,
    what = 'fluid',
    which = 'provider',
    attributes = {
      energy_required = LINK_FLUID_RECIPE_CRAFTING_TIME,
      icon = fluid.icon,
      icon_size = fluid.icon_size,
      localised_name = localised_name,
      localised_description = localised_description,
      ingredients = {
        {
          amount = LINK_FLUID_RECIPE_AMOUNT,
          name = fluid.name,
          type = 'fluid'
        }
      },
      results = {
        {
          amount = LINK_FLUID_RECIPE_AMOUNT,
          name = string.format('link-fluid-%s', fluid.name),
          type = 'item'
        }
      }
    }
  })

  -- link_build_recipe_data(fluid_recipe, 'fluid', fluid.name)
  -- fluid_recipe.category = LINK_FLUID_PROVIDER_NAME
  -- fluid_recipe.enabled = true
  -- fluid_recipe.
  -- fluid_recipe.icon = fluid.icon
  -- fluid_recipe.icon_size = fluid.icon_size
  -- fluid_recipe.ingredients = {
  --   {
  --     amount = LINK_FLUID_RECIPE_AMOUNT,
  --     name = fluid.name,
  --     type = 'fluid'
  --   }
  -- }
  -- fluid_recipe.name = link_format_fluid_recipe_name(fluid.name, 'provider')
  -- fluid_recipe.order = link_format_fluid_order(fluid_recipe.name)
  -- fluid_recipe.hide_from_player_crafting = true
  -- fluid_recipe.return_ingredients_on_change = false
  -- fluid_recipe.results = {
  --   {
  --     amount = LINK_FLUID_RECIPE_AMOUNT,
  --     name = fluid_recipe.name,
  --     type = 'item'
  --   }
  -- }
  -- fluid_recipe.subgroup = link_format_subgroup(LINK_FLUID_SUBGROUP_NAME, 'provider')
  -- fluid_recipe.type = 'recipe'

  link_extend_data({fluid_recipe})
end


--------------------------------------------------------------------------------
-- SUBGROUP
--------------------------------------------------------------------------------
-- local recipe_subgroup = link_build_subgroup_data({}, 'fluid-recipe', 'provider')
local recipe_subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'fluid',
  which = 'provider'
})
-- local subgroup = link_build_subgroup_data({}, 'fluid', 'provider')
-- local subgroup = link_build_data({
--   type = 'item-subgroup',
--   what = 'fluid',
--   which = 'provider'
-- })


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
-- local recipe = table.deepcopy(data.raw.recipe['assembling-machine-3'])
local recipe = link_build_data({
  inherit = data.raw.recipe['assembling-machine-3'],
  type = 'recipe',
  what = 'fluid',
  which = 'provider',
  attributes = {
    localised_description = localised_description
  }
})
-- recipe.enabled = true
-- recipe.name = LINK_FLUID_PROVIDER_NAME
-- recipe.order = link_format_fluid_order(LINK_FLUID_PROVIDER_NAME)
-- recipe.result = recipe.name
-- recipe.result = LINK_FLUID_PROVIDER_NAME
-- recipe.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['assembling-machine-3'],
  type = 'item',
  what = 'fluid',
  which = 'provider',
  attributes = {
    localised_description = localised_description
  }
})
-- table.deepcopy(data.raw.item['assembling-machine-3'])
-- link_build_data(item, 'fluid', 'provider')
-- -- item.name = LINK_FLUID_PROVIDER_NAME
-- -- item.order = link_format_fluid_order(LINK_FLUID_PROVIDER_NAME)
-- item.place_result = LINK_FLUID_PROVIDER_NAME
-- item.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['assembling-machine']['assembling-machine-3'],
  what = 'fluid',
  which = 'provider',
  attributes = {
    fluid_boxes = {
      {
        base_area = LINK_FLUID_BASE_AREA,
        base_level = -1,
        pipe_connections = {
          {
            position = { 0, -2 },
            type = 'input'
          }
        },
        pipe_covers = pipecoverspictures(),
        pipe_picture = assembler3pipepictures(),
        production_type = 'input'
      }
    },
    localised_description = localised_description
  }
})

-- local entity = table.deepcopy(data.raw['assembling-machine']['assembling-machine-3'])
-- link_build_data(entity, 'fluid', 'provider')
-- entity.crafting_categories = { LINK_FLUID_PROVIDER_NAME }
-- entity.fluid_boxes = {
--   {
--     base_area = LINK_FLUID_BASE_AREA,
--     base_level = -1,
--     pipe_connections = {
--       {
--         position = { 0, -2 },
--         type = 'input'
--       }
--     },
--     pipe_covers = pipecoverspictures(),
--     pipe_picture = assembler3pipepictures(),
--     production_type = 'input'
--   }
-- }
-- entity.minable = { mining_time = 0.5, result = LINK_FLUID_PROVIDER_NAME }
-- entity.module_specification = { module_slots = 0 }
-- entity.name = LINK_FLUID_PROVIDER_NAME
-- entity.order = link_format_fluid_order(LINK_FLUID_PROVIDER_NAME)

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
