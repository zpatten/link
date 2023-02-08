function link_gui_create(player)
  if not global.link_gui then

--------------------------------------------------------------------------------

    global.link_gui = player.gui.screen.add{
      type      = 'frame',
      name      = 'link-outer-frame',
      direction = 'horizontal',
      caption   = 'Link',
      visible   = false
    }

    local server_list_inner_frame = global.link_gui.add{
      type      = 'frame',
      name      = 'link-server-list-frame',
      style     = 'inventory_frame',
      caption = 'Servers'
    }

    local server_list_scroll_pane = server_list_inner_frame.add{
      type                     = 'scroll-pane',
      name                     = 'link-server-list-scroll-pane',
      horizontal_scroll_policy = 'never',
      vertical_scroll_policy   = 'auto',
      style = 'inner_frame_scroll_pane'
    }

    global.link_gui_servers_table = server_list_scroll_pane.add{
      type = 'table',
      name = 'link-servers-table',
      column_count = 5,
      draw_horizontal_lines = true,
      draw_horizontal_lines_after_headers = true
    }
    global.link_gui_servers_table.style.width = 400

--------------------------------------------------------------------------------

    global.link_gui_storage_table    = link_gui_logistics_frame(global.link_gui, 'Storage')

--------------------------------------------------------------------------------

    local logistics_flow = global.link_gui.add{
      type      = 'flow',
      name      = 'link-logistics-flow',
      direction = 'vertical'
    }
    global.link_gui_logistics_table_provided    = link_gui_logistics_frame(logistics_flow, 'Provided')
    global.link_gui_logistics_table_requested   = link_gui_logistics_frame(logistics_flow, 'Requested')
    global.link_gui_logistics_table_fulfilled   = link_gui_logistics_frame(logistics_flow, 'Fulfilled')
    global.link_gui_logistics_table_unfulfilled = link_gui_logistics_frame(logistics_flow, 'Unfulfilled')
    global.link_gui_logistics_table_overflow    = link_gui_logistics_frame(logistics_flow, 'Overflow')

--------------------------------------------------------------------------------

    global.link_gui.force_auto_center()

--------------------------------------------------------------------------------

  end
end

function link_gui_servers_table_update(player)
  if global.link_gui_servers_table and global.link_gui_servers_table.valid then
    global.link_gui_servers_table.clear()
    global.link_gui_servers_table.add{
      type = 'label',
      caption = 'Connect'
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

function link_gui_logistics_frame_update(gui, items)
  if gui and gui.valid then
    gui.clear()
    if items then
      for item_name, item_count in pairs(items) do
        if item_name ~= 'electricity' then
          local sprite = gui.add{
            type = 'sprite-button',
            style = 'logistic_slot_button',
            sprite = lookup_item_type(item_name)..'/'..item_name,
            number = item_count,
            tooltip = item_name
          }
        end
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
  if element.parent.name == 'link-servers-table' then
    server = global.link_server_list[element.name]
    player.connect_to_server{
      address = string.format('%s:%s', server.host, server.port),
      name = server.name
    }
  end
end
script.on_event(defines.events.on_gui_click, on_gui_click)
