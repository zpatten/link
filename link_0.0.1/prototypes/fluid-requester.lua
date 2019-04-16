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
  fluid_recipe.category = LINK_FLUID_RECIPE_CATEGORY_NAME
  fluid_recipe.enabled = true
  fluid_recipe.icon = table.deepcopy(fluid.icon)
  fluid_recipe.icon_size = table.deepcopy(fluid.icon_size)
  fluid_recipe.ingredients = {}
  fluid_recipe.name = string.format("link-%s", fluid.name)
  fluid_recipe.order = string.format(LINK_FLUID_RECIPE_ORDER, fluid_recipe.name)
  fluid_recipe.results = {
    {
      type = "fluid",
      name = fluid.name,
      amount = -1
    }
  }
  fluid_recipe.subgroup = LINK_FLUID_RECIPE_SUBGROUP_NAME
  fluid_recipe.type = "recipe"
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
item.icon = data.raw.item["storage-tank"].icon
item.icons = { { icon = item.icon, tint = LINK_TINT } }
item.name = LINK_FLUID_REQUESTER_NAME
item.order = string.format(LINK_FLUID_ORDER, item.name)
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
  },
  off_when_no_fluid_recipe = false
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
