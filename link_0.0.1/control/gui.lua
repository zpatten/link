require "mod-gui"

LINK_GUI_TOGGLE_BUTTON = "link-gui-toggle-button"
function on_join(event)
  local player = game.players[event.player_index]
  -- if player.admin then
  mod_gui.get_button_flow(player).add{
    type = "button",
    name = LINK_GUI_TOGGLE_BUTTON,
    style = mod_gui.button_style,
    caption = "LINK"
  }
    -- if not parent[LINK_GUI_TOGGLE_BUTTON] then
    --   parent.add
    -- end
  -- end
end

script.on_event(defines.events.on_player_joined_game, on_join)
