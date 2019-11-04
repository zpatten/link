--------------------------------------------------------------------------------
-- FLUID RECIPES
--------------------------------------------------------------------------------
local link_requester_fluid_recipe_category = {
  name = LINK_FLUID_RECIPE_CATEGORY_NAME,
  type = "recipe-category"
}
data:extend{link_requester_fluid_recipe_category}

for _, fluid in pairs(data.raw.fluid) do
  local fluid_item = {}
  fluid_item.icons = {
    {
      icon = data.raw.fluid[fluid.name].icon,
      icon_size = 32,
      tint = LINK_TINT
    }
  }
  fluid_item.name = link_fluid_name(fluid.name)
  fluid_item.order = string.format(LINK_FLUID_ORDER, link_fluid_name(fluid.name))
  fluid_item.subgroup = LINK_FLUID_ITEM_SUBGROUP_NAME
  fluid_item.stack_size = LINK_FLUID_MAX
  fluid_item.type = "item"

  local fluid_recipe = {}
  fluid_recipe.category = LINK_FLUID_RECIPE_CATEGORY_NAME
  fluid_recipe.enabled = true
  fluid_recipe.icons = {
    {
      icon = table.deepcopy(fluid.icon),
      icon_size = table.deepcopy(fluid.icon_size),
      tint = LINK_TINT
    }
  }
  fluid_recipe.ingredients = {
    {
      amount = LINK_FLUID_MAX,
      name = link_fluid_name(fluid.name),
      type = "item"
    }
  }
  fluid_recipe.name = link_fluid_name(fluid.name)
  fluid_recipe.order = string.format(LINK_FLUID_RECIPE_ORDER, fluid_recipe.name)
  fluid_recipe.hide_from_player_crafting = true
  fluid_recipe.return_ingredients_on_change = false
  fluid_recipe.results = {
    {
      amount = LINK_FLUID_MAX,
      name = fluid.name,
      type = "fluid"
    }
  }
  fluid_recipe.subgroup = LINK_FLUID_RECIPE_SUBGROUP_NAME
  fluid_recipe.type = "recipe"

  data:extend{ fluid_item, fluid_recipe }
end


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["assembling-machine-3"])
recipe.enabled = true
recipe.icons = {
  {
    icon = data.raw.item["storage-tank"].icon,
    icon_size = 32,
    tint = LINK_TINT
  }
}
recipe.name = LINK_FLUID_REQUESTER_NAME
recipe.order = string.format(LINK_FLUID_ORDER, LINK_FLUID_REQUESTER_NAME)
recipe.result = LINK_FLUID_REQUESTER_NAME
recipe.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["assembling-machine-3"])
item.icons = { { icon = data.raw.item["storage-tank"].icon, tint = LINK_TINT } }
item.name = LINK_FLUID_REQUESTER_NAME
item.order = string.format(LINK_FLUID_ORDER, LINK_FLUID_REQUESTER_NAME)
item.place_result = LINK_FLUID_REQUESTER_NAME
item.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
entity.animation.layers = table.deepcopy(data.raw["storage-tank"]["storage-tank"].pictures.picture.sheets)
entity.crafting_categories = { LINK_FLUID_RECIPE_CATEGORY_NAME }
entity.fluid_boxes = {
  {
    production_type = "output",
    pipe_picture = assembler3pipepictures(),
    pipe_covers = pipecoverspictures(),
    base_area = LINK_FLUID_BASE_AREA,
    base_level = 1,
    pipe_connections = {
      {
        position = { -1, -2 },
        type = "output"
      },
      {
        position = { 2, 1 },
        type = "output"
      },
      {
        position = { 1, 2 },
        type = "output"
      },
      {
        position = { -2, -1 },
        type = "output"
      }
    }
  }
}
entity.minable = { mining_time = 0.5, result = LINK_FLUID_REQUESTER_NAME }
entity.module_specification = { module_slots = 0 }
entity.name = LINK_FLUID_REQUESTER_NAME
entity.order = string.format(LINK_FLUID_ORDER, LINK_FLUID_REQUESTER_NAME)
link_add_tint(entity)

log(inspect(entity))


--------------------------------------------------------------------------------
data:extend{ recipe, item, entity }
--------------------------------------------------------------------------------
