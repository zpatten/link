--------------------------------------------------------------------------------
-- FLUID RECIPES
--------------------------------------------------------------------------------
local link_requester_fluid_recipe_category = {
  name = LINK_FLUID_RECIPE_CATEGORY_NAME,
  type = "recipe-category"
}
data:extend{link_requester_fluid_recipe_category}

for _, fluid in pairs(data.raw.fluid) do
  local fluid_recipe = {}
  fluid_recipe.name = string.format("link-%s", fluid.name)
  fluid_recipe.type = "recipe"
  fluid_recipe.icon = table.deepcopy(fluid.icon)
  fluid_recipe.icon_size = table.deepcopy(fluid.icon_size)
  fluid_recipe.category = LINK_FLUID_RECIPE_CATEGORY_NAME
  fluid_recipe.subgroup = LINK_FLUID_RECIPE_SUBGROUP_NAME
  fluid_recipe.order = string.format(LINK_FLUID_RECIPE_ORDER, fluid_recipe.name)
  fluid_recipe.enabled = true
  fluid_recipe.ingredients = {}
  fluid_recipe.results = {
    { type = "fluid", name = fluid.name, amount = -1 }
  }
  data:extend{fluid_recipe}
end


--------------------------------------------------------------------------------
-- ITEM RECIPE
--------------------------------------------------------------------------------
local recipe = table.deepcopy(data.raw.recipe["assembling-machine-3"])
recipe.enabled = true
recipe.name = LINK_FLUID_REQUESTER_NAME
recipe.order = string.format(LINK_FLUID_ORDER, recipe.name)
recipe.result = LINK_FLUID_REQUESTER_NAME
recipe.subgroup = LINK_FLUID_SUBGROUP_NAME


--------------------------------------------------------------------------------
-- ITEM
--------------------------------------------------------------------------------
local item = table.deepcopy(data.raw.item["assembling-machine-3"])
item.name = LINK_FLUID_REQUESTER_NAME
item.place_result = LINK_FLUID_REQUESTER_NAME
item.subgroup = LINK_FLUID_SUBGROUP_NAME
item.icons = {
  {
    icon = item.icon,
    tint = LINK_TINT
  }
}


--------------------------------------------------------------------------------
-- ENTITY
--------------------------------------------------------------------------------
local entity = table.deepcopy(data.raw["assembling-machine"]["assembling-machine-3"])
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
        position = { 0, 2 },
        type = "output"
      }
    }
  },
  off_when_no_fluid_recipe = false
}
entity.minable = { mining_time = 0.5, result = LINK_FLUID_REQUESTER_NAME }
entity.module_specification = { module_slots = 0 }
entity.name = LINK_FLUID_REQUESTER_NAME
entity.order = string.format(LINK_FLUID_ORDER, LINK_FLUID_REQUESTER_NAME)
entity.animation.layers[1].tint = LINK_TINT
entity.animation.layers[1].hr_version.tint = LINK_TINT


--------------------------------------------------------------------------------
data:extend{item, entity, recipe}
--------------------------------------------------------------------------------
