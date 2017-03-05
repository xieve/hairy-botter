local discordia = require('discordia')
local json = require('json')
local cmd = require('command.lua')

local client = discordia.Client()

local players = {}
local msg = {}
local objects = {}

local msg = ''
local prefix = '+'

--functions
local function count(tbl)
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

local function rpgUpdate(player, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == 4 then
      players[player.id][stat] = statValue
      if verificationMsg then
        msg:reply(verificationMsg)
      end
    else
      msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart')
    end
  else
    msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart')
  end
end

local function characterCreationF(step, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == step then
      players[msg.author.id][stat] = statValue
      players[msg.author.id].characterCreation = players[msg.author.id].characterCreation + 1
      if verificationMsg then
        msg:reply(verificationMsg)
      end
    else
      msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart')
    end
  else
    msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart')
  end
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
  --client:getChannel('251369598203592704'):sendMessage('Guten Morgen oder so! Ich bin jetzt wach!')
end)

client:on('messageCreate', function(message)
  print(message.timestamp..' <'..message.author.name..'> '..message.content) --Screen output
  if message.author.id ~= client.user.id then --If not himself
    msg = message
    local command = cmd.separate(prefix, msg.content)

    --Metatable Setup
    if not players[msg.author.id] then
      players[msg.author.id] = {}
    end
    setmetatable(players[msg.author.id], players.mt)

    if command then
      --User Interface
      if command.main == 'help' then
        msg:reply('**RPG**: Mit `+rpgstart` kommt man in die Charaktererstellung, mit `+stats` ruft man seine Statistiken ab und mit `+inventar` sein Inventar.')
      end

      --Bot Control
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

        --Basic Commands
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
        elseif players[msg.author.id].characterCreation == 3 then
          msg.author:sendMessage('Du hast bereits einen Charakter. Um ihn dir anzusehen, schreibe `+stats`')
        end
      elseif command.main == 'stats' then
        if players[msg.author.id].characterCreation == 4 then
          msg:reply('**'..msg.author.mentionString..'s Stats:**\n**HP:** '..players[msg.author.id].hp..'\n**Level:** '..players[msg.author.id].level..'\n**Geschlecht:** '..players[msg.author.id].gender..'\n**Rasse:** '..players[msg.author.id].race..'\n**Klasse:** '..players[msg.author.id].class)
        else
          msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart.')
        end
      elseif command.main == 'inventar' then
        if players[msg.author.id].characterCreation == 4 then
          local inventoryString = ''
          for k,v in pairs(players[msg.author.id].inventory) do
            inventoryString = inventoryString..v.amount..' '..k..'\n'
          end
          msg:reply('**'..msg.author.mentionString..'s Inventar:**\n'..inventoryString..'Um genauere Informationen zu erhalten, schreibe `+info <Name des Gegenstandes>`.')
        else
          msg:reply('Bitte erstelle zuerst einen Charakter mit +rpgstart.')
        end
      elseif command.main == 'info' then
        for k,v in pairs(players[msg.author.id].inventory) do
          if string.gsub(msg.content, '+info ', '') == k then
            msg:reply(objects[string.gsub(msg.content, '+info ', '')].info)
          end
        end
      elseif command.main == 'newitem' and permCheck(msg.member, 'administrator') then
        rpgUpdate(msg.author, 'itemCreation', 1, 'Name?')
      end

    --Character Creation
    elseif players[msg.author.id].characterCreation and players[msg.author.id].characterCreation < 4 then
      if string.find(msg.content, 'Mann') then
        characterCreationF(1, 'gender', 'Mann', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne ein flinker, intelligenter Elf oder lieber ein kleiner, praktischer Halbling? Wie wäre es mit einem starken Zwerg der nicht ganz so hell in der Birne ist oder einem klassischem, ausgeglichenem Menschen?')
      elseif string.find(msg.content, 'Frau') then
        characterCreationF(1, 'gender', 'Frau', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne eine flinke, intelligente Elfe oder lieber eine kleine, praktische Halblingsfrau? Wie wäre es mit einer starken Zwergenfrau die nicht ganz so hell in der Birne ist oder einer klassischen, ausgeglichenen Menschenfrau?')
      elseif string.find(msg.content, 'Zwerg') then
        characterCreationF(2, 'race', 'Zwerg', 'Soso. Ein Zwerg. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Mensch') then
        characterCreationF(2, 'race', 'Mensch', 'Soso. Ein Mensch. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Elfe') then
        characterCreationF(2, 'race', 'Elf', 'Soso. Eine Elfe. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Elf') then
        characterCreationF(2, 'race', 'Elf', 'Soso. Ein Elf. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Halbling') then
        characterCreationF(2, 'race', 'Halbling', 'Soso. Ein Halbling. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.find(msg.content, 'Priester') then
        characterCreationF(3, 'class', 'Priester', 'Ein Geistiger also. Interessante Wahl.')
      elseif string.find(msg.content, 'Assasine') then
        characterCreationF(3, 'class', 'Assasine', 'Ein Assasine also. Interessante Wahl.')
      elseif string.find(msg.content, 'Krieger') then
        characterCreationF(3, 'class', 'Krieger', 'Ein Kämpfer also. Interessante Wahl.')
      elseif string.find(msg.content, 'Magier') then
        characterCreationF(3, 'class', 'Magier', 'Ein Magier also. Interessante Wahl.')

      end

    --Server-only Things
    elseif not msg.channel.isPrivate then

      --DM-Commands
      if string.find(msg.content, 'Level') then
        if string.find(msg.content, 'für') and permCheck(msg.member, 'administrator') then
          if string.find(msg.content, 'Abzug') then
            for user in msg.mentionedUsers do
              local lvlMod = tonumber(string.find(msg.content, '%d*'))
              rpgUpdate(user, 'level', players[user.id].level - tonumber(string.find(msg.content, '%d*')), user.mentionString..' ist jetzt auf Level '..players[user.id].level - lvlMod..'.')
            end
          else
            for user in msg.mentionedUsers do
              local lvlMod = tonumber(string.find(msg.content, '%d*'))
              rpgUpdate(user, 'level', players[user.id].level + tonumber(string.find(msg.content, '%d*')), user.mentionString..' ist jetzt auf Level '..players[user.id].level + lvlMod..'.')
            end
          end
        end

      --Spells
      elseif string.find(msg.content, 'Ein Feuerball, mit viel Geknall') and (players[msg.author.id].class == 'Magier' or players[msg.author.id].class == 'Erschaffer') then
        for user in msg.mentionedUsers do
          rpgUpdate(user, 'hp', players[user.id].hp - 1, user.mentionString..' wurde getroffen und hat jetzt nur noch '..tostring(players[user.id].hp - 1)..' HP.')
        end

      --Item Creation
    elseif players[msg.author.id].itemCreation ~= 0 and permCheck(msg.member, 'administrator') then
        if players[msg.author.id].itemCreation == 1 then
          objects[msg.content] = {}
          players[msg.author.id].creating = msg.content
          players[msg.author.id].itemCreation = 2
          msg:reply('Info?')
        elseif players[msg.author.id].itemCreation == 2 then
          objects[players[msg.author.id].creating].info = msg.content
          players[msg.author.id].itemCreation = nil
          players[msg.author.id].creating = nil
        end
      end
    end

    --Random Chests
    if math.random(1,15) == 3 or msg.content == 'ranChest' then
      local randval = math.random(1, count(objects)) -- get a random point
      local randentry
      local count = 0
      for k,v in pairs(objects) do
        count = count + 1
        if(count == randval) then
          randentry = {key = k, val = v}
        end
      end
      msg:reply('Du hast eine Kiste gefunden. Sie enthielt ein '..randentry.key..'.')
      if not players[msg.author.id].inventory[randentry.key] then
        players[msg.author.id].inventory[randentry.key] = {}
      end
      setmetatable(players[msg.author.id].inventory[randentry.key], players.mt)
      players[msg.author.id].inventory[randentry.key].amount = players[msg.author.id].inventory[randentry.key].amount + 1
    end
  end
end)

client:run('MjU0OTUyNjQ5OTIzODg3MTA0.CyWk6Q.xzZ1t5kFtX3I05wNZxjVuhSEOJU')
