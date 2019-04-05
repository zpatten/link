function get_link_current_research()
  global.ticks_since_last_link_operation = 0

  local link_current_research = {}

  if game.forces.player.current_research ~= nil then
    link_current_research.current_research = game.forces.player.current_research.name
    link_current_research.research_progress = game.forces.player.research_progress
  end

  rcon.print(game.table_to_json(link_current_research))
end

function set_link_current_research(data)
  global.ticks_since_last_link_operation = 0

  local link_current_research = game.json_to_table(data)

  if link_current_research.current_research then
    if game.forces.player.current_research ~= link_current_research.current_research then
      game.forces.player.current_research = nil

      game.forces.player.current_research = link_current_research.current_research
    end
    game.forces.player.research_progress = link_current_research.research_progress
  else
    game.forces.player.current_research = nil
  end

  rcon.print("OK")
end

function get_link_research()
  global.ticks_since_last_link_operation = 0
  local link_research = {}

  for _, technology in pairs(game.forces.player.technologies) do
    local data = { researched = technology.researched, level = technology.level }
    link_research[technology.name] = data
  end

  rcon.print(game.table_to_json(link_research))
end

function set_link_research(data)
  global.ticks_since_last_link_operation = 0
  local link_research = game.json_to_table(data)

  for _, technology in pairs(game.forces.player.technologies) do
    if link_research[technology.name] then
      technology.researched = link_research[technology.name].researched
      technology.level = link_research[technology.name].level

      script.raise_event(defines.events.on_research_finished, {research=technology, by_script=true})
      game.play_sound({path="utility/research_completed"})
    end
  end

  rcon.print("OK")
end
