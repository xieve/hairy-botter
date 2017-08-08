local discordia = require("discordia")
local cmd = require("command")
local xvngn = require("xievengine")

local client = discordia.Client()

local spells = require("spells.lua")
local msg = {}
local meta = {
  __index = {
    inventory = {},
    hp = {
      value = 30,
      max = 30
    },
    level = 0,
    characterCreation = 0
  }
}

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

local function permCheck(member, permission)
  if not member then return end
  for role in member.roles do
    if role.permissions:has(permission) then
      return true
    end
  end
end

local function statUpdate(player, stat, statValue, displayStat, verificationMsg)
  if xvngn.players[player.id].characterCreation then
    if xvngn.players[player.id].characterCreation == 4 then
      xvngn.players[player.id][stat] = statValue

      local member = standardGuild:getMember(player.id)
      local success = false
      local displayValue = type(statValue) == "table" and statValue.value and (statValue.max and displayStat..": "..statValue.value.."/"..statValue.max) or displayStat..": "..statValue.value

      for role in standardGuild.roles do
        if role.name == displayValue then
          member:addRole(role)
          success = true
        end
      end
      if not success then
        local role = standardGuild:createRole()
        role.name = displayValue
        role:disableAllPermissions()
        if type(statValue) == "table" and statValue.value and statValue.max then
          local greenValue = statValue.value * 255 / statValue.max > 127 and 255 or statValue.value * 620 / statValue.max
          local redValue = statValue.value * 255 / statValue.max < 128 and 255 or 620 - statValue.value * 620 / statValue.max
          local blueValue = 0
          role.color = discordia.Color(redValue, greenValue, blueValue)
        end

        for role in member.roles do
          if role.name:find("^"..displayStat) then
            member:removeRole(role)
          end
        end
        member:addRole(role)
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
  xvngn.players[player.id][stat] = statValue

  local member = standardGuild:getMember(player.id)
  local success = false

  for role in standardGuild.roles do
    if role.name == displayValue then
      member:addRole(role)
      success = true
    end
  end
  if not success then
    local role = standardGuild:createRole()
    role.name = displayValue
    role:disableAllPermissions()
    if type(statValue) == "table" and statValue.value and statValue.max then
      local greenValue = statValue.value * 255 / statValue.max > 127 and 255 or statValue.value * 620 / statValue.max
      local redValue = statValue.value * 255 / statValue.max < 128 and 255 or 620 - statValue.value * 620 / statValue.max
      local blueValue = 0
      role.color = discordia.Color(redValue, greenValue, blueValue)
    end
    member:addRole(role)
  end
  if verificationMsg then
    msg:reply(verificationMsg)
  end
end

local function inventoryUpdate(user, object, amount)
  xvngn.players[user.id].inventory = xvngn.players[user.id].inventory or {}
  xvngn.players[user.id].inventory[object] = xvngn.players[user.id].inventory[object] or {}
  xvngn.players[user.id].inventory[object].amount = xvngn.players[user.id].inventory[object].amount or 0
  xvngn.players[user.id].inventory[object].amount = xvngn.players[user.id].inventory[object].amount + amount
end

math.randomseed(os.time())

client:on("ready", function()
  print("Logged in as ".. client.user.username)
  client:setGameName(prefix.."hilfe")
  standardGuild = client:getGuild("248445888446464010")
end)

client:on("messageCreate", function(message)
  print(os.date('!%Y-%m-%d %H:%M:%S', message.createdAt).. ' <'.. message.author.name.. '> '.. message.content) -- Screen debug output
  if not message.author.bot then
    msg = message
    local command = cmd.separate(msg.content, prefix, separator)

    -- Metatable Setup
    xvngn.players[msg.author.id] = xvngn.players[msg.author.id] or {}
    setmetatable(xvngn.players[msg.author.id], meta)

    if command then
      -- User Interface
      if command.main == "hilfe" then
        msg:reply("Mit `"..prefix.."stats` ruft man seine Statistiken ab, mit `"..prefix.."inventar` sein Inventar und mit `"..prefix.."stundenglas` erfährt man den aktuellen Hauspunktestand.\nZu diesem Zeitpunkt kann jeder zaubern wie er möchte, dies wird in zukünftigen Updates durch Skills begrenzt werden. Verfügbar sind alle folgenden Zaubersprüche:\n"..spells.list)

      elseif command.main == "stundenglas" then
        msg:reply("```Gryffindor | "..xvngn.players.Gryffindor.points.."\nRavenclaw  | "..xvngn.players.Ravenclaw.points.."\nHufflepuff | "..xvngn.players.Hufflepuff.points.."\nSlytherin  | "..xvngn.players.Slytherin.points.."```")

      -- Bot Control
      elseif command.main == "stop" then
        if msg.author.id == client.owner.id then
          msg:reply("Saving and stopping...")
          print("Saving...")
          xvngn.save()
          print("Saved.")
          os.exit()
        end
      elseif command.main == "restart" then
        if msg.author.id == client.owner.id then
          msg:reply("Saving and restarting...")
          print("Saving...")
          xvngn.save()
          print("Saved.")
          os.execute[[./start.sh]]
          os.exit()
        end
      elseif command.main == "save" then
        if msg.author.id == client.owner.id then
          msg:reply("Saving...")
          print("Saving...")
          xvngn.save()
          print("Saved.")
        end

      -- Basic Commands
      elseif command.main == "start" then
        if xvngn.players[msg.author.id].characterCreation == 0 then
          xvngn.players[msg.author.id].characterCreation = 1
          msg.author:sendMessage("Willkommen auf unserem Server. Um als vollwertiges Mitglied am RPG teilzunehmen, musst du einen Charakter erstellen. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Da diese Eigenschaft als einzige keine Auswirkung auf meine Funktion hat, darfst du hier angeben was auch immer du willst.)")
        elseif xvngn.players[msg.author.id].characterCreation == 1 then
          msg.author:sendMessage("Wähle dein Geschlecht.")
        elseif xvngn.players[msg.author.id].characterCreation == 2 then
          msg.author:sendMessage("Wähle dein Haus: Gryffindor, Ravenclaw, Hufflepuff oder Slytherin?")
        elseif xvngn.players[msg.author.id].characterCreation == 3 then
          msg.author:sendMessage("Wähle zwei Klassen: Besenflugstunden, Kräuterkunde, Pflege magischer Geschöpfe, Verteidigung gegen die dunklen Künste, Verwandlung, Zauberkunst oder Zaubertränke.")
        elseif xvngn.players[msg.author.id].characterCreation == 4 then
          msg.author:sendMessage("Du hast bereits einen Charakter. Um ihn dir anzusehen, schreibe `"..prefix.."stats`")
        end
      elseif command.main == "stats" then
        if xvngn.players[msg.author.id].characterCreation == 4 then
          msg:reply("**"..msg.author.mentionString.."s Stats:**\n**HP:** "..xvngn.players[msg.author.id].hp.value.."/"..xvngn.players[msg.author.id].hp.max.."\n**Level:** "..xvngn.players[msg.author.id].level)
        else
          msg:reply("Bitte erstelle zuerst einen Charakter mit "..prefix.."start.")
        end
      elseif command.main == "inventar" then
        if xvngn.players[msg.author.id].characterCreation == 4 then
          local inventoryString = ""
          for k,v in pairs(xvngn.players[msg.author.id].inventory) do
            inventoryString = inventoryString..v.amount.." "..k.."\n"
          end
          msg:reply("**"..msg.author.mentionString.."s Inventar:**\n"..inventoryString.."Um genauere Informationen zu erhalten, schreibe `"..prefix.."info <Name des Gegenstandes>`.")
        else
          msg:reply("Bitte erstelle zuerst einen Charakter mit "..prefix.."start.")
        end
      elseif command.main == "info" then
        for key, val in pairs(xvngn.players[msg.author.id].inventory) do
          if key == command.args[1] then
            msg:reply(xvngn.objects[command.args[1]].info)
          end
        end
      elseif command.main == "newitem" and permCheck(msg.member, "administrator") then
        xvngn.objects[command.args[1]] = {info = command.args[2]}
      end

    -- House Points
    elseif msg.content:find("%d+ Punkte A?b?z?u?g?%s?für ") and permCheck(msg.member, "administrator") then
      local amount, minus = msg.content:match("(%d+) Punkte (A?b?z?u?g?)%s?für ")
      local house = msg.content:match("%d+ Punkte A?b?z?u?g?%s?für (Gryffindor)")
        or msg.content:match("%d+ Punkte A?b?z?u?g?%s?für (Ravenclaw)")
        or msg.content:match("%d+ Punkte A?b?z?u?g?%s?für (Hufflepuff)")
        or msg.content:match("%d+ Punkte A?b?z?u?g?%s?für (Slytherin)")
      if house then
        xvngn.players[house].points = (minus == "Abzug") and xvngn.players[house].points - amount or xvngn.players[house].points + amount
        msg:reply(house.." hat jetzt "..xvngn.players[house].points.." Punkte.")
      end

    -- Character Creation
    elseif xvngn.players[msg.author.id].characterCreation and xvngn.players[msg.author.id].characterCreation < 4 and msg.channel.isPrivate then
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

      if xvngn.players[msg.author.id].characterCreation == 1 then
        characterCreation(msg.author, "gender", msg.content, "Geschlecht: "..msg.content, "Schöne Sache, "..msg.author.mentionString..", schöne Sache. Nun zu deinem Haus. Es gibt einige Tests im sagenumwobenen Internetz, doch der beste ist vermutlich der originale: Wenn du dir auf www.pottermore.com einen Account erstellst, bekommst du die Chance, diesen und viele weitere durchzuführen. Natürlich kannst du dir auch ein Haus aussuchen.")
        xvngn.players[msg.author.id].characterCreation = 2
      elseif xvngn.players[msg.author.id].characterCreation == 2 and house then
        characterCreation(msg.author, "house", house, house, "Ein "..house.." also. Als nächstes wähle zwei Fächer: Besenflugstunden, Kräuterkunde, Pflege magischer Geschöpfe, Verteidigung gegen die dunklen Künste, Verwandlung, Zauberkunst oder Zaubertränke.")
        xvngn.players[msg.author.id].characterCreation = 3
      elseif xvngn.players[msg.author.id].characterCreation == 3 and arts then
        if #arts == 2 and arts[1] ~= arts[2] then
          characterCreation(msg.author, "hp", {value = 30, max = 30}, "HP: 30/30")
          characterCreation(msg.author, "arts", nil, arts[1])
          characterCreation(msg.author, "arts", arts, arts[2], "Das war's auch schon. Viel Spaß!")
          xvngn.players[msg.author.id].characterCreation = 4
        else
          msg:reply("**Zwei** Fächer, sagte ich.")
        end
      end

    -- Spells
    else
      local spell = spells[message.content:match("^(%S+)%s?")] or spells[message.content:match("^(%S+%s%S+)%s?")] -- Match the first or the first two words and check if they're a spell
      if spell then
        local response = message.content:match(spell.name.."%s(.+)")
        --if spell.init then spell.init(msg.author, response, msg) end
        if response and spell.replyWithObj then
          message:reply(spell.replyWithObj:format(response))
        elseif spell.replyWithoutObj then
          message:reply(spell.replyWithoutObj)
        end
      end
    end

    -- Random Chests
    if math.random(1,15) == 3 and xvngn.objects then
      local randval = math.random(1, table.len(xvngn.objects)) -- get a random point
      local randentry
      local count = 0
      for k,v in pairs(xvngn.objects) do
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
  -- Metatable Setup
  xvngn.players[member.id] = xvngn.players[member.id] or {}
  setmetatable(xvngn.players[member.id], meta)
  p(xvngn.players[member.id].characterCreation)

  -- Welcome Message
  if xvngn.players[member.id].characterCreation == 0 then
    xvngn.players[member.id].characterCreation = 1
    member:sendMessage("Willkommen auf unserem Server. Um als vollwertiges Mitglied am RPG teilzunehmen, musst du einen Charakter erstellen. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Da diese Eigenschaft als einzige keine Auswirkung auf meine Funktion hat, darfst du hier angeben was auch immer du willst.)")
  end
end)

client:run(args[2])
