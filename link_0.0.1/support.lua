-- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
function table_count(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

-- https://stackoverflow.com/questions/9168058/how-to-dump-a-table-to-console
function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

-- http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end
