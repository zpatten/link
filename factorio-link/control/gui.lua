function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = player.gui.screen.add{
      type = 'frame',
      name = 'link-frame',
      caption = 'Link'
    }

    global.link_gui.add{
      type = 'tabbed-pane',
      name = 'tabbed-pane'
    }

--------------------------------------------------------------------------------

    local servers_tab = global.link_gui['tabbed-pane'].add{
      type = 'tab',
      caption = 'Servers'
    }
    local servers_flow = global.link_gui['tabbed-pane'].add{
      type = 'flow',
      direction = 'vertical'
    }
    global.link_gui_servers_table = servers_flow.add{
      type = 'table',
      name = 'servers_table',
      column_count = 5,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    global.link_gui['tabbed-pane'].add_tab(servers_tab, servers_flow)

--------------------------------------------------------------------------------

    local storage_tab = global.link_gui['tabbed-pane'].add{
      type = 'tab',
      caption = 'Storage'
    }
    local storage_flow = global.link_gui['tabbed-pane'].add{
      type = 'scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy = 'auto-and-reserve-space'
    }
    global.link_gui_storage_table = storage_flow.add{
      type = 'table',
      name = 'storage_table',
      column_count = 3,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    global.link_gui['tabbed-pane'].add_tab(storage_tab, storage_flow)

--------------------------------------------------------------------------------

    global.link_gui.force_auto_center()
    global.link_gui.visible = false

--------------------------------------------------------------------------------

  end
end

function link_gui_update(player)
  link_gui_servers_table_update(player)
end

function link_gui_servers_table_update(player)
  if global.link_gui_servers_table and global.link_gui_servers_table.valid then
    global.link_gui_servers_table.clear()
    global.link_gui_servers_table.add{
      type = 'label'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Name'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Research'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Responsive?'
    }
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'RTT'
    }
    if global.link_server_list then
      for _, server in pairs(global.link_server_list) do
        global.link_gui_servers_table.add{
          name = server.name,
          type = 'button',
          caption = 'Connect'
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = server.name
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.research)
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.responsive)
        }
        global.link_gui_servers_table.add{
          type = 'label',
          caption = tostring(server.rtt)
        }
      end
    end
  end
end

function link_gui_destroy(player)
  if global.link_gui and global.link_gui.valid then
    global.link_gui.destroy()
    global.link_gui = nil
  end
end

function link_gui_toggle(player)
  if global.link_gui and global.link_gui.valid then
    global.link_gui.visible = not global.link_gui.visible
  end
end

function on_gui_click(event)
  local player = game.players[event.player_index]
  local element = event.element
  if element.parent.name == 'servers_table' then
    server = global.link_server_list[element.name]
    player.connect_to_server{
      address = string.format('%s:%s', server.host, server.port),
      name = server.name
    }
  end
end
script.on_event(defines.events.on_gui_click, on_gui_click)
