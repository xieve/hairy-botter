local json = require("json")

local tbl = {}

local function writeTable(filename, tbl)
  local file = io.open(filename, "w")
  file:write(json.encode(tbl))
  file:close()
end

local function readTable(filename)
  local file = io.open(filename, "r")
  local data = json.decode(file:read("*all"))
  file:close()
  return data or {}
end

function tbl.save()
  writeTable("players.json", tbl.players)
  writeTable("objects.json", tbl.objects)
end

print("Starting xievengine...")
tbl.players = readTable("players.json")
tbl.objects = readTable("objects.json")
print("Loaded data:")
p(tbl.players)
p(tbl.objects)

return tbl
