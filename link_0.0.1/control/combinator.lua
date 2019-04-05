function set_link_inventory_combinator(data)
  local storage = game.json_to_table(data)
  local signals = {}

  local fluids = game.fluid_prototypes
  local items = game.item_prototypes
  local virtuals = game.virtual_signal_prototypes

  for item_name, item_count in pairs(storage) do
    local signal_id = {}
    if items[item_name] then
      signal_id = { name = item_name, type = "item" }
    elseif fluids[item_name] then
      signal_id = { name = item_name, type = "fluid" }
    elseif virtuals[item_name] then
      signal_id = { name = item_name, type = "virtual" }
    end
    signals[#signals+1] = { signal = signal_id, count = item_count, index = #signals+1 }
    for unit_number, inventory_combinator_control in pairs(global.link_inventory_combinators) do
      if inventory_combinator_control.valid then
        inventory_combinator_control.parameters = { parameters = signals }
        inventory_combinator_control.enabled = true
      end
    end
  end
end
