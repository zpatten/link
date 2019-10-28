inspect = require "inspect"

function link_log(what, message)
  if global.link_debug then
    log(string.format("[LINK:%s] %s", what, message))
  end
end

-- https://stackoverflow.com/questions/2705793/how-to-get-number-of-entries-in-a-lua-table
-- function table_count(t)
--   local count = 0
--   if not t then
--     return 0
--   end
--   for _ in pairs(t) do count = count + 1 end
--   return count
-- end

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
-- function dump(o, indent)
--   if not indent then
--     indent = 0
--   end

--   indent_str = string.rep(" ", indent)

--   if type(o) == 'table' then
--     local s = string.format("{ \n")
--     for k,v in pairs(o) do
--       if type(k) ~= 'number' then k = string.format("%s\"%s\"", indent_str, k) end
--       if type(v) == 'table' then
--         s = string.format("%s%s[%s] = %s", indent_str, s, k, dump(v, indent + 2))
--       else
--         s = string.format("%s%s[%s] = %s,\n", indent_str, s, k, tostring(v))
--       end
--     end
--     return string.format("%s%s }\n", indent_str, s)
--   elseif type(o) == "number" then
--     return string.format("%s%f\n", indent_str, tonumber(o))
--   else
--     return string.format("%s%s\n", indent_str, tostring(o))
--   end
-- end

-- http://lua-users.org/wiki/SimpleRound
function round(num, numDecimalPlaces)
  return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end
