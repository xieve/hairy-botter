local discordia = require("discordia")
local json = require("json")
local cmd = require("command.lua")

local client = discordia.Client()

local players = {}
local objects = {}
local msg = {}
local meta = {
  __index = {
    inventory = {},
    hp = 30,
    level = 0,
    characterCreation = 0
  }
}

local msg

local prefix = ">"
local separator = "/"
local standardGuild = {}

--functions
function table.len(tbl)
  local val = 0
  for k,v in pairs(tbl) do
    val = val + 1
  end
  return val
end

function table.repop(tbl)
  local count = 0
  local newTbl = {}
  for key, value in pairs(tbl) do
    if value then
      count = count + 1
      newTbl[count] = value
    end
  end
  return newTbl
end

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

local function permCheck(member, permission)
  if not member then return end
  for role in member.roles do
    if role.permissions:has(permission) then
      return true
    end
  end
end

local function statUpdate(player, stat, statValue, displayValue, verificationMsg)
  players[player.id][stat] = statValue
  if players[player.id].characterCreation then
    if players[player.id].characterCreation == 4 then
      local success = false
      for role in standardGuild.roles do
        if role.name == displayValue then
          role:disableAllPermissions()
          standardGuild:getMember(player.id):addRole(role)
          success = true
        end
      end
      if not success then
        local role = createRole()
        role.name = displayValue
        role:disableAllPermissions()
        standardGuild:getMember(player.id):addRole(role)
      end
      if verificationMsg then
        msg:reply(verificationMsg)
      end
    else
      msg:reply("Bitte erstelle zuerst einen Charakter.")
    end
  else
    msg:reply("Bitte erstelle zuerst einen Charakter.")
  end
end

local function characterCreation(player, stat, statValue, displayValue, verificationMsg)
  players[player.id][stat] = statValue
  local success = false
  for role in standardGuild.roles do
    if role.name == displayValue then
      role:disableAllPermissions()
      standardGuild:getMember(player.id):addRole(role)
      success = true
    end
  end
  if not success then
    local role = standardGuild:createRole()
    role.name = displayValue
    role:disableAllPermissions()
    standardGuild:getMember(player.id):addRole(role)
  end
  if verificationMsg then
    msg:reply(verificationMsg)
  end
end

local function inventoryUpdate(user, object, amount)
  players[user.id].inventory = players[user.id].inventory or {}
  players[user.id].inventory[object] = players[user.id].inventory[object] or {}
  players[user.id].inventory[object].amount = players[user.id].inventory[object].amount or 0
  players[user.id].inventory[object].amount = players[user.id].inventory[object].amount + amount
end

print("Starting...")
players = readTable("players.json")
objects = readTable("objects.json")
print("loaded data:")
p(players)
p(objects)
math.randomseed(os.time())

client:on("ready", function()
  print("Logged in as ".. client.user.username)
  client:setGameName(prefix.."help")
  standardGuild = client:getGuild("272432542559502337")
end)

client:on("messageCreate", function(message)
  print(os.date('!%Y-%m-%d %H:%M:%S', message.createdAt).. ' <'.. message.author.name.. '> '.. message.content) --Screen output
  if not message.author.bot then
    msg = message
    local command = cmd.separate(msg.content, prefix, separator)

    -- Metatable Setup
    players[msg.author.id] = players[msg.author.id] or {}
    setmetatable(players[msg.author.id], meta)

    if command then
      -- User Interface
      if command.main == "help" then
        msg:reply("Mit `"..prefix.."stats` ruft man seine Statistiken ab und mit `"..prefix.."inventar` sein Inventar.")
      end

      -- Bot Control
      if command.main == "stop" then
        if msg.author.id == client.owner.id then
          print("Saving...")
          writeTable("players.json", players)
          writeTable("objects.json", objects)
          print("Saved.")
          os.exit()
        end
      elseif command.main == "restart" then
        if msg.author.id == client.owner.id then
          print("Saving...")
          writeTable("players.json", players)
          writeTable("objects.json", objects)
          print("Saved.")
          os.execute[[.\luvit bot.lua]]
          os.exit()
        end
      elseif command.main == "save" then
        if msg.author.id == client.owner.id then
          print("Saving...")
          writeTable("players.json", players)
          writeTable("objects.json", objects)
          print("Saved.")
        end

        -- Basic Commands
      elseif command.main == "start" then
        if players[msg.author.id].characterCreation == 0 then
          players[msg.author.id].characterCreation = 1
          msg.author:sendMessage("Willkommen auf unserem Server. Um als vollwertiges Mitglied am RPG teilzunehmen, musst du einen Charakter erstellen. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Da diese Eigenschaft als einzige keine Auswirkung auf meine Funktion hat, darfst du hier angeben was auch immer du willst.)")
        elseif players[msg.author.id].characterCreation == 1 then
          msg.author:sendMessage("Wähle dein Geschlecht.")
        elseif players[msg.author.id].characterCreation == 2 then
          msg.author:sendMessage("Wähle dein Haus: Gryffindor, Ravenclaw, Hufflepuff oder Slytherin?")
        elseif players[msg.author.id].characterCreation == 3 then
          msg.author:sendMessage("Wähle zwei Klassen: Besenflugstunden, Kräuterkunde, Pflege magischer Geschöpfe, Verteidigung gegen die dunklen Künste, Verwandlung, Zauberkunst oder Zaubertränke.")
        elseif players[msg.author.id].characterCreation == 4 then
          msg.author:sendMessage("Du hast bereits einen Charakter. Um ihn dir anzusehen, schreibe `"..prefix.."stats`")
        end
      elseif command.main == "stats" then
        if players[msg.author.id].characterCreation == 4 then
          msg:reply("**"..msg.author.mentionString.."s Stats:**\n**HP:** "..players[msg.author.id].hp.."\n**Level:** "..players[msg.author.id].level)
        else
          msg:reply("Bitte erstelle zuerst einen Charakter mit "..prefix.."start.")
        end
      elseif command.main == "inventar" then
        if players[msg.author.id].characterCreation == 4 then
          local inventoryString = ""
          for k,v in pairs(players[msg.author.id].inventory) do
            inventoryString = inventoryString..v.amount.." "..k.."\n"
          end
          msg:reply("**"..msg.author.mentionString.."s Inventar:**\n"..inventoryString.."Um genauere Informationen zu erhalten, schreibe `"..prefix.."info <Name des Gegenstandes>`.")
        else
          msg:reply("Bitte erstelle zuerst einen Charakter mit "..prefix.."start.")
        end
      elseif command.main == "info" then
        for key, val in pairs(players[msg.author.id].inventory) do
          if key == command.args[1] then
            msg:reply(objects[command.args[1]].info)
          end
        end
      elseif command.main == "newitem" and permCheck(msg.member, "administrator") then
        objects[command.args[1]] = {info = command.args[2]}
      end

    -- Character Creation
    elseif players[msg.author.id].characterCreation and players[msg.author.id].characterCreation < 4 and msg.channel.isPrivate then
      local house = msg.content:match("Gryffindor") or msg.content:match("Ravenclaw") or msg.content:match("Hufflepuff") or msg.content:match("Slytherin")
      local arts = {
        msg.content:match("Besenflugstunden"),
        msg.content:match("Kräuterkunde"),
        msg.content:match("Pflege magischer Geschöpfe"),
        msg.content:match("Verteidigung gegen die dunklen Künste"),
        msg.content:match("Verwandlung"),
        msg.content:match("Zauberkunst"),
        msg.content:match("Zaubertränke")
      }
      arts = table.repop(arts)

      if players[msg.author.id].characterCreation == 1 then
        characterCreation(msg.author, "gender", msg.content, "Geschlecht: "..msg.content, "Schöne Sache, "..msg.author.mentionString..", schöne Sache. Nun zu deinem Haus. Es gibt einige Tests im sagenumwobenen Internetz, doch der beste ist vermutlich der originale: Wenn du dir auf www.pottermore.com einen Account erstellst, bekommst du die Chance, diesen und viele weitere durchzuführen. Natürlich kannst du dir auch ein Haus aussuchen.")
        players[msg.author.id].characterCreation = 2
      elseif players[msg.author.id].characterCreation == 2 and house then
        characterCreation(msg.author, "house", house, house, "Ein "..house.." also. Als nächstes wähle zwei Fächer: Besenflugstunden, Kräuterkunde, Pflege magischer Geschöpfe, Verteidigung gegen die dunklen Künste, Verwandlung, Zauberkunst oder Zaubertränke.")
        players[msg.author.id].characterCreation = 3
      elseif players[msg.author.id].characterCreation == 3 and arts then
        if #arts == 2 and arts[1] ~= arts[2] then
          characterCreation(msg.author, "arts", nil, arts[1])
          characterCreation(msg.author, "arts", arts, arts[2], "Das war's auch schon. Viel Spaß!")
          players[msg.author.id].characterCreation = 4
        else
          msg:reply("**Zwei** Fächer, sagte ich.")
        end
      end

    --[[ Server-only Things (NOT WORKING RIGHT NOW WOULD NEED TO CHANGE statUpdate ARGS)
    elseif not msg.channel.isPrivate then

      -- DM-Commands

      if string.find(msg.content, "Level.*für") and permCheck(msg.member, "administrator") then
        if string.find(msg.content, "Abzug") then
          for user in msg.mentionedUsers do
            local lvlMod = tonumber(string.match(msg.content, "^%d*"))
            statUpdate(user, "level", players[user.id].level - lvlMod, user.mentionString.." ist jetzt auf Level "..players[user.id].level - lvlMod..".")
          end
        else
          for user in msg.mentionedUsers do
            local lvlMod = tonumber(string.match(msg.content, "^%d*"))
            statUpdate(user, "level", players[user.id].level + lvlMod, user.mentionString.." ist jetzt auf Level "..players[user.id].level + lvlMod..".")
          end
        end
      end

      -- Spells
    elseif string.find(msg.content, "Avada Kedabra") then
      for user in msg.mentionedUsers do
        statUpdate(user, "hp", players[user.id].hp - 1, user.mentionString.." wurde getroffen und hat jetzt nur noch "..tostring(players[user.id].hp - 1).." HP.")
      end
      ]]
    end

    -- Random Chests
    if math.random(1,15) == 3 and objects then
      local randval = math.random(1, table.len(objects)) -- get a random point
      local randentry
      local count = 0
      for k,v in pairs(objects) do
        count = count + 1
        if (count == randval) then
          randentry = {key = k, val = v}
        end
      end
      msg:reply("Du hast 1 "..randentry.key.." gefunden. Leider ist das momentan fast nutzlos.")
      inventoryUpdate(msg.author, randentry.key, 1)
    end
  end
end)

client:on("memberJoin", function(member)
  if players[msg.author.id].characterCreation == 0 then
    players[msg.author.id].characterCreation = 1
    msg.author:sendMessage("Willkommen auf unserem Server. Um als vollwertiges Mitglied am RPG teilzunehmen, musst du einen Charakter erstellen. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Da diese Eigenschaft als einzige keine Auswirkung auf meine Funktion hat, darfst du hier angeben was auch immer du willst.)")
  end
end)

client:run(args[2])
