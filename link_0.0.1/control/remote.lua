local remote_interface = {
  get_chats = get_link_chats,
  get_commands = get_link_commands,
  get_current_research = get_link_current_research,
  get_providables = get_link_providables,
  get_requests = get_link_requests,
  get_research = get_link_research,
  ping = ping,
  reset = on_init,
  rtt = rtt,
  set_command_whitelist = set_link_command_whitelist,
  set_current_research = set_link_current_research,
  set_fulfillments = set_link_fulfillments,
  set_id = set_link_id,
  get_receiver_combinator_network_ids = get_link_receiver_combinator_network_ids,
  set_inventory_combinator = set_link_inventory_combinator,
  set_receiver_combinator = set_link_receiver_combinator,
  get_transmitter_combinator = get_link_transmitter_combinator,
  set_research = set_link_research,
  lookup_item_type = link_lookup_item_type
}

remote.add_interface("link", remote_interface)
