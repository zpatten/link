-- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
function table_count(t)
  local count = 0
  if not t then
    return 0
  end
  for _ in pairs(t) do count = count + 1 end
  return count
end

function uniq(a)
  local hash = {}
  local res = {}

  for _,v in ipairs(a) do
    if (not hash[v]) then
      res[#res+1] = v -- you could print here instead of saving to result table if you wanted
      hash[v] = true
    end
  end

  return res
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
