local localised_description = 'Requests fluids from the Link.'


--------------------------------------------------------------------------------
-- FLUID RECIPE CATEGORY
--------------------------------------------------------------------------------
local recipe_category = link_build_data({
  type = 'recipe-category',
  what = 'fluid',
  which = 'requester'
})


--------------------------------------------------------------------------------
-- FLUID RECIPES
--------------------------------------------------------------------------------
for _, fluid in pairs(data.raw.fluid) do
  local fluid_name = capitalize(string.gsub(fluid.name, '-', ' '))
  local localised_name = string.format('Link %s Requester', fluid_name)
  local localised_description = string.format('Converts Link %s to %s so it can be provided to the Link.', fluid_name, fluid_name)

  local fluid_recipe = link_build_data({
    type = 'recipe',
    name = fluid.name,
    what = 'fluid',
    which = 'requester',
    attributes = {
      energy_required = LINK_FLUID_RECIPE_CRAFTING_TIME,
      icon = fluid.icon,
      icon_size = fluid.icon_size,
      localised_name = localised_name,
      localised_description = localised_description,
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
    }
  })

  link_extend_data({fluid_recipe})
end


--------------------------------------------------------------------------------
-- SUBGROUP
--------------------------------------------------------------------------------
local recipe_subgroup = link_build_data({
  type = 'item-subgroup',
  what = 'fluid',
  which = 'requester'
})


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = link_build_data({
  inherit = data.raw.recipe['assembling-machine-3'],
  type = 'recipe',
  what = 'fluid',
  which = 'requester',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = link_build_data({
  inherit = data.raw.item['assembling-machine-3'],
  type = 'item',
  what = 'fluid',
  which = 'requester',
  attributes = {
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = link_build_data({
  inherit = data.raw['assembling-machine']['assembling-machine-3'],
  what = 'fluid',
  which = 'requester',
  attributes = {
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
    },
    localised_description = localised_description
  }
})


--------------------------------------------------------------------------------
link_extend_data({
  recipe_category,
  recipe_subgroup,
  recipe,
  item,
  entity
})
--------------------------------------------------------------------------------
