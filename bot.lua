local discordia = require('discordia')
local json = require('json')
local cmd = require('command.lua')

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

local msg = ''
local prefix = '#'

--functions
function table.len(tbl)
  local val = 0
  for k,v in pairs(tbl) do
    val = val + 1
  end
  return val
end

local function writeTable(filename, tbl)
  local file = io.open(filename, 'w')
  file:write(json.encode(tbl))
  file:close()
end

local function readTable(filename)
  local file = io.open(filename, 'r')
  local data = json.decode(file:read('*all'))
  file:close()
  if data then
    return data
  else
    return {}
  end
end

local function permCheck(member, permission)
  for role in member.roles do
    if role.permissions:has(permission) then
      return true
    end
  end
end

local function statUpdate(player, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == 4 then
      players[player.id][stat] = statValue
      if verificationMsg then
        msg:reply(verificationMsg)
      end
    else
      msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart')
    end
  else
    msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart')
  end
end

local function characterCreation(step, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == step then
      players[msg.author.id][stat] = statValue
      players[msg.author.id].characterCreation = players[msg.author.id].characterCreation + 1
      if verificationMsg then
        msg:reply(verificationMsg)
      end
    else
      msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart')
    end
  else
    msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart')
  end
end

local function inventoryUpdate(user, object, amount)
  players[user.id].inventory = players[user.id].inventory or {}
  players[user.id].inventory[object] = players[user.id].inventory[object] or {}
  players[user.id].inventory[object].amount = players[user.id].inventory[object].amount or 0
  players[user.id].inventory[object].amount = players[user.id].inventory[object].amount + amount
end

do
  print('Starting...')
  players = readTable('players.json')
  objects = readTable('objects.json')
  print('loaded data:')
  p(players)
  p(objects)
  math.randomseed(os.time())
end

client:on('ready', function()
  print('Logged in as '.. client.user.username)
  client:setGameName(prefix..'help')
end)

client:on('messageCreate', function(message)
  print(message.timestamp..' <'..message.author.name..'> '..message.content) --Screen output
  if message.author.id ~= client.user.id then --If not himself
    msg = message
    local command = cmd.separate(prefix, msg.content)

    -- Metatable Setup
    if not players[msg.author.id] then
      players[msg.author.id] = {}
    end
    setmetatable(players[msg.author.id], meta)

    if command then
      -- User Interface
      if command.main == 'help' then
        msg:reply('**RPG**: Mit `'..prefix..'rpgstart` kommt man in die Charaktererstellung, mit `'..prefix..'stats` ruft man seine Statistiken ab und mit `'..prefix..'inventar` sein Inventar.')
      end

      -- Bot Control
      if command.main == 'stop' then
        if msg.author.id == client.owner.id then
          print('Saving...')
          writeTable('players.json', players)
          writeTable('objects.json', objects)
          print('Saved.')
          os.exit()
        end
      elseif command.main == 'restart' then
        if msg.author.id == client.owner.id then
          print('Saving...')
          writeTable('players.json', players)
          writeTable('objects.json', objects)
          print('Saved.')
          os.execute[[E:\DEV\Discordia_DumbleDalf\luvit bot.lua]]
          os.exit()
        end
      elseif command.main == 'save' then
        if msg.author.id == client.owner.id then
          print('Saving...')
          writeTable('players.json', players)
          writeTable('objects.json', objects)
          print('Saved.')
        end

        -- Basic Commands
      elseif command.main == 'rpgstart' then
        if players[msg.author.id].characterCreation == 0 then
          players[msg.author.id].characterCreation = 1
          msg.author:sendMessage('Willkommen zur Charaktererstellung. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Mann oder Frau, tut mir echt leid Andere.)')
        elseif players[msg.author.id].characterCreation == 1 then
          msg.author:sendMessage('Wähle dein Geschlecht: Mann oder Frau?')
        elseif players[msg.author.id].characterCreation == 2 then
          msg.author:sendMessage('Wähle deine Rasse: Elf, Zwerg, Halbling oder Mensch?')
        elseif players[msg.author.id].characterCreation == 3 then
          msg.author:sendMessage('Wähle deine Klasse: Priester, Assasine, Krieger oder Magier?')
        elseif players[msg.author.id].characterCreation == 4 then
          msg.author:sendMessage('Du hast bereits einen Charakter. Um ihn dir anzusehen, schreibe `'..prefix..'stats`')
        end
      elseif command.main == 'stats' then
        if players[msg.author.id].characterCreation == 4 then
          msg:reply('**'..msg.author.mentionString..'s Stats:**\n**HP:** '..players[msg.author.id].hp..'\n**Level:** '..players[msg.author.id].level..'\n**Geschlecht:** '..players[msg.author.id].gender..'\n**Rasse:** '..players[msg.author.id].race..'\n**Klasse:** '..players[msg.author.id].class)
        else
          msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart.')
        end
      elseif command.main == 'inventar' then
        if players[msg.author.id].characterCreation == 4 then
          local inventoryString = ''
          for k,v in pairs(players[msg.author.id].inventory) do
            inventoryString = inventoryString..v.amount..' '..k..'\n'
          end
          msg:reply('**'..msg.author.mentionString..'s Inventar:**\n'..inventoryString..'Um genauere Informationen zu erhalten, schreibe `'..prefix..'info <Name des Gegenstandes>`.')
        else
          msg:reply('Bitte erstelle zuerst einen Charakter mit '..prefix..'rpgstart.')
        end
      elseif command.main == 'info' then
        for key, val in pairs(players[msg.author.id].inventory) do
          if key == command.args[1] then
            msg:reply(objects[command.args[1]].info)
          end
        end
      elseif command.main == 'newitem' and permCheck(msg.member, 'administrator') then
        objects[command.args[1]] = {info = command.args[2]}
      end

    -- Character Creation
    elseif players[msg.author.id].characterCreation and players[msg.author.id].characterCreation < 4 then
      if string.find(msg.content, 'Mann') then
        characterCreation(1, 'gender', 'Mann', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne ein flinker, intelligenter Elf oder lieber ein kleiner, praktischer Halbling? Wie wäre es mit einem starken Zwerg der nicht ganz so hell in der Birne ist oder einem klassischem, ausgeglichenem Menschen?')
      elseif string.find(msg.content, 'Frau') then
        characterCreation(1, 'gender', 'Frau', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne eine flinke, intelligente Elfe oder lieber eine kleine, praktische Halblingsfrau? Wie wäre es mit einer starken Zwergenfrau die nicht ganz so hell in der Birne ist oder einer klassischen, ausgeglichenen Menschenfrau?')
      elseif string.find(msg.content, 'Zwerg') then
        characterCreation(2, 'race', 'Zwerg', 'Soso. Ein Zwerg. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Mensch') then
        characterCreation(2, 'race', 'Mensch', 'Soso. Ein Mensch. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Elfe') then
        characterCreation(2, 'race', 'Elf', 'Soso. Eine Elfe. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Elf') then
        characterCreation(2, 'race', 'Elf', 'Soso. Ein Elf. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Halbling') then
        characterCreation(2, 'race', 'Halbling', 'Soso. Ein Halbling. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Priester') then
        characterCreation(3, 'class', 'Priester', 'Ein Geistiger also. Interessante Wahl.')
      elseif string.find(msg.content, 'Assasine') then
        characterCreation(3, 'class', 'Assasine', 'Ein Assasine also. Interessante Wahl.')
      elseif string.find(msg.content, 'Krieger') then
        characterCreation(3, 'class', 'Krieger', 'Ein Kämpfer also. Interessante Wahl.')
      elseif string.find(msg.content, 'Magier') then
        characterCreation(3, 'class', 'Magier', 'Ein Magier also. Interessante Wahl.')

      end

    -- Server-only Things
    elseif not msg.channel.isPrivate then

      -- DM-Commands
      if string.find(msg.content, 'Level.*für') and permCheck(msg.member, 'administrator') then
        if string.find(msg.content, 'Abzug') then
          for user in msg.mentionedUsers do
            local lvlMod = tonumber(string.match(msg.content, '^%d*'))
            statUpdate(user, 'level', players[user.id].level - lvlMod, user.mentionString..' ist jetzt auf Level '..players[user.id].level - lvlMod..'.')
          end
        else
          for user in msg.mentionedUsers do
            local lvlMod = tonumber(string.match(msg.content, '^%d*'))
            statUpdate(user, 'level', players[user.id].level + lvlMod, user.mentionString..' ist jetzt auf Level '..players[user.id].level + lvlMod..'.')
          end
        end

      -- Spells
      elseif string.find(msg.content, 'Ein Feuerball, mit viel Geknall') and (players[msg.author.id].class == 'Magier' or players[msg.author.id].class == 'Erschaffer') then
        for user in msg.mentionedUsers do
          statUpdate(user, 'hp', players[user.id].hp - 1, user.mentionString..' wurde getroffen und hat jetzt nur noch '..tostring(players[user.id].hp - 1)..' HP.')
        end
      end
    end

    -- Random Chests
    if math.random(1,15) == 3 then
      local randval = math.random(1, objects:len()) -- get a random point
      local randentry
      local count = 0
      for k,v in pairs(objects) do
        count = count + 1
        if(count == randval) then
          randentry = {key = k, val = v}
        end
      end
      msg:reply('Du hast eine Kiste gefunden. Sie enthielt 1 '..randentry.key..'.')
      inventoryUpdate(msg.author, randentry.key, 1)
    end
  end
end)

client:run('MjU0OTUyNjQ5OTIzODg3MTA0.CyWk6Q.xzZ1t5kFtX3I05wNZxjVuhSEOJU')
