local remote_interface = {
  get_chats = get_link_chats,
  get_commands = get_link_commands,
  get_current_research = get_link_current_research,
  get_providables = get_link_providables,
  get_receiver_combinator_network_ids = get_link_receiver_combinator_network_ids,
  get_requests = get_link_requests,
  get_research = get_link_research,
  get_transmitter_combinator = get_link_transmitter_combinator,
  lookup_item_type = link_lookup_item_type,
  ping = ping,
  reset = on_init,
  rtt = rtt,
  set_command_whitelist = set_link_command_whitelist,
  set_current_research = set_link_current_research,
  set_fulfillments = set_link_fulfillments,
  set_id = set_link_id,
  set_receiver_combinator = set_link_receiver_combinator,
  set_research = set_link_research,
  set_server_list = set_link_server_list,
  set_logistics_provided = set_link_logistics_provided,
  set_logistics_requested = set_link_logistics_requested,
  set_logistics_fulfilled = set_link_logistics_fulfilled,
  set_logistics_unfulfilled = set_link_logistics_unfulfilled,
  set_logistics_overflow = set_link_logistics_overflow
}

remote.add_interface("link", remote_interface)
