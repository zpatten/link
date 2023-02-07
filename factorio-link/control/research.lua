function get_link_current_research()
  local link_current_research = nil

  if game.forces.player.research_queue ~= nil then
    link_current_research = {
      research_queue_enabled = false,
      research_queue = {},
      research_progress = 0
    }
    link_current_research.research_queue_enabled = game.forces.player.research_queue_enabled
    for _, technology in pairs(game.forces.player.research_queue) do
      table.insert(link_current_research.research_queue, technology.name)
    end
    link_current_research.research_progress = game.forces.player.research_progress
  end

  rcon.print(game.table_to_json(link_current_research))
end

function set_link_current_research(data)
  local link_current_research = game.json_to_table(data)

  if table_size(link_current_research.research_queue) > 0 then
    game.forces.player.research_queue_enabled = link_current_research.research_queue_enabled
    game.forces.player.research_queue = link_current_research.research_queue
    game.forces.player.research_progress = link_current_research.research_progress
  else
    game.forces.player.research_queue_enabled = link_current_research.research_queue_enabled
    game.forces.player.research_queue = nil
  end

  rcon.print("OK")
end

function get_link_research()
  local link_research = {}

  for _, technology in pairs(game.forces.player.technologies) do
    local data = { researched = technology.researched, level = technology.level }
    link_research[technology.name] = data
  end

  rcon.print(game.table_to_json(link_research))
end

function set_link_research(data)
  local link_research = game.json_to_table(data)

  for _, technology in pairs(game.forces.player.technologies) do
    if link_research[technology.name] then
      technology.researched = link_research[technology.name].researched
      technology.level = link_research[technology.name].level

      -- script.raise_event(defines.events.on_research_finished, {research=technology, by_script=true})
      -- game.play_sound({path="utility/research_completed"})
    end
  end

  rcon.print("OK")
end
