-- local link_provider_fluid_recipe_category = {
--   name = LINK_FLUID_PROVIDER_CATEGORY_NAME,
--   type = "recipe-category"
-- }
-- data:extend{link_provider_fluid_recipe_category}

-- for _, fluid in pairs(data.raw.fluid) do
--   local fluid_recipe = {}
--   fluid_recipe.name = string.format("provide-%s", fluid.name)
--   fluid_recipe.type = "recipe"
--   fluid_recipe.icon = table.deepcopy(fluid.icon)
--   fluid_recipe.icon_size = table.deepcopy(fluid.icon_size)
--   fluid_recipe.category = LINK_FLUID_PROVIDER_CATEGORY_NAME
--   fluid_recipe.subgroup = LINK_FLUID_SUBGROUP_NAME
--   fluid_recipe.order = string.format("b[empty-%s-barrel]", fluid.name)
--   fluid_recipe.enabled = true
--   fluid_recipe.energy_required = 1
--   fluid_recipe.ingredients = {
--     {
--       amount = 100,
--       name = fluid.name,
--       type = "fluid"
--     }
--   }
--   fluid_recipe.results = {
--     { type = "fluid", name = fluid.name, amount = 100 }
--   }
--   data:extend{fluid_recipe}
-- end



local item = table.deepcopy(data.raw.item["storage-tank"])
item.name = LINK_FLUID_PROVIDER_NAME
item.place_result = LINK_FLUID_PROVIDER_NAME
item.subgroup = LINK_FLUID_SUBGROUP_NAME

local fluid_provider = table.deepcopy(data.raw["storage-tank"]["storage-tank"])
fluid_provider.name = LINK_FLUID_PROVIDER_NAME
-- fluid_provider.crafting_categories = { LINK_FLUID_PROVIDER_CATEGORY_NAME }
-- fluid_provider.module_specification.module_slots = 0
fluid_provider.minable = { mining_time = 0.5, result = LINK_FLUID_PROVIDER_NAME }
-- fluid_provider.ingredient_count = 1
-- fluid_provider.fluid_boxes = {
--   {
--     production_type = "input",
--     pipe_picture = assembler3pipepictures(),
--     pipe_covers = pipecoverspictures(),
--     base_area = 100,
--     base_level = -1,
--     pipe_connections = {
--       {
--         position = { 0, -2 },
--         type = "input"
--       }
--     }
--   },
--   {
--     production_type = "output",
--     pipe_picture = assembler3pipepictures(),
--     pipe_covers = pipecoverspictures(),
--     base_area = 100,
--     base_level = 1,
--     pipe_connections = {
--       {
--         position = { 0, 2 },
--         type = "output"
--       }
--     }
--   },
--   off_when_no_fluid_recipe = false
-- }

-- b[fluid]-a[storage-tank]
-- b[storage]-c[logistic-chest-active-provider]
-- a[items]-b[iron-chest]

local recipe = table.deepcopy(data.raw.recipe["storage-tank"])
recipe.enabled = true
recipe.name = LINK_FLUID_PROVIDER_NAME
recipe.result = LINK_FLUID_PROVIDER_NAME
recipe.subgroup = LINK_FLUID_SUBGROUP_NAME
recipe.order = string.format(LINK_FLUID_ORDER, recipe.name)

data:extend{item, fluid_provider, recipe}
