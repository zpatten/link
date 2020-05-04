function link_shortcut(event)
  if event.prototype_name == LINK_SHORTCUT_SERVERS and event.player_index and event.player_index ~= -1 then
    local player = game.players[event.player_index]
    link_gui_destroy(player)
    link_gui_create(player)
    link_gui_update(player)
    link_gui_toggle(player)
  end
end
script.on_event(defines.events.on_lua_shortcut, link_shortcut)
