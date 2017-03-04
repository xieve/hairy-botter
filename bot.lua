local spawn = require('coro-spawn')
local split = require('coro-split') -- lit install creationix/coro-split
local parse = require('url').parse
local http = require('http')
local discordia = require('discordia')
local json = require('json')

local client = discordia.Client()
local players = {}
local msg = {}
local objects = {}
local connection
local msg = ''
local channel
local playingURL = ''
local playingTrack = 0

--functions
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

local function getStream(url)

  local child = spawn('youtube-dl', {
    args = {'-g', url},
    stdio = {nil, true, true}
  })

  local stream
  local function readstdout()
    local stdout = child.stdout
    for chunk in stdout.read do
      local mime = parse(chunk, true).query.mime
      if mime and mime:find('audio') then
        stream = chunk
      end
    end
    return pcall(stdout.handle.close, stdout.handle)
  end

  local function readstderr()
    local stderr = child.stderr
    for chunk in stderr.read do
      print(chunk)
    end
    return pcall(stderr.handle.close, stderr.handle)
  end

  split(readstdout, readstderr, child.waitExit)

  return stream and stream:gsub('%c', '')
end

local function getPlaylistStream(url, number)
  local child = spawn('youtube-dl', {
    args = {'-g', '--playlist-items', number, url},
    stdio = {nil, true, true}
  })

  local stream
  local function readstdout()
    local stdout = child.stdout
    for chunk in stdout.read do
      local mime = parse(chunk, true).query.mime
      if mime and mime:find('audio') then
        stream = chunk
      end
    end
    return pcall(stdout.handle.close, stdout.handle)
  end

  local function readstderr()
    local stderr = child.stderr
    for chunk in stderr.read do
      print(chunk)
    end
    return pcall(stderr.handle.close, stderr.handle)
  end

  split(readstdout, readstderr, child.waitExit)

  return stream and stream:gsub('%c', '')
end

local function len(tbl)
  local count = 0
  for k,v in pairs(tbl) do
    count = count + 1
  end
  return count
end

local function roleCheck(member, rolePos)
  for role in member.roles do
    if role.position >= rolePos then
      return true
    end
  end
end

local function ifMatch(trigger, out)
  if string.match(msg.content, trigger) then
    msg.channel:sendMessage(out)
  end
end

local function rpgUpdate(player, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == 4 then
      players[player.id][stat] = statValue
      if verificationMsg then
        msg.channel:sendMessage(verificationMsg)
      end
    else
      msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart')
    end
  else
    msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart')
  end
end

local function characterCreationF(step, stat, statValue, verificationMsg)
  if players[msg.author.id].characterCreation then
    if players[msg.author.id].characterCreation == step then
      players[msg.author.id][stat] = statValue
      players[msg.author.id].characterCreation = players[msg.author.id].characterCreation + 1
      if verificationMsg then
        msg.channel:sendMessage(verificationMsg)
      end
    else
      msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart')
    end
  else
    msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart')
  end
end

local streamPlaylist = coroutine.wrap(function(url, beginWith)
  local child = spawn('youtube-dl', {
    args = {'-J', url},
  })
  stdio = {nil, true, true}
  local playlist = json.decode(child.stdout:read())
  connection = vChannel:join()
  if connection then
    p('Connected')
    for playingTrack = beginWith or 1, len(playlist.entries) do
      local stream = getPlaylistStream(url, playingTrack) -- URL goes here
      print('Playing track '..playingTrack..' of '..len(playlist.entries))
      connection:playFile(stream)
    end
  end
end)

client.voice:loadOpus('libopus-x86')
client.voice:loadSodium('libsodium-x86')

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
  vChannel = client:getVoiceChannel('251093576639971329') -- vChannel ID goes here
  client:getChannel('251369598203592704'):sendMessage('Guten Morgen oder so! Ich bin jetzt wach!')
end)

client:on('messageCreate', function(message)
  print(message.timestamp.. ' <'.. message.author.name.. '> '.. message.content) --Screen output
  if message.author.id ~= client.user.id then --If not himself
    msg = message
    --Metatable Setup
    if not players[msg.author.id] then
      players[msg.author.id] = {}
    end
    setmetatable(players[msg.author.id], players.mt)

    --User Interface
    ifMatch('Sag mal', string.gsub(msg.content, 'Sag mal', ''))
    ifMatch('9001', string.gsub(msg.content, '9001', '')..'over ninethousand!')
    ifMatch('Angel', 'Eine Angel ist ein Ding, welches meist aus einem langem Stab besteht. Nils trägt es meist mit sich und hält es gerne in der Hand.')
    ifMatch(' ist explodiert', 'Du baust '..string.gsub(msg.content, ' ist explodiert', '', 10)..' wieder auf!')
    ifMatch('dumme Kinder', 'Is halt schon so.')
    ifMatch('Zustimmung', 'Seh ich auch so.')
    ifMatch('ija', 'Nein, Nils.')
    ifMatch('fap', msg.author.mentionString..' hat sich kurz zurückgezogen.')
    ifMatch('+help', '**RPG**: Mit `+rpgstart` kommt man in die Charaktererstellung, mit `+stats` ruft man seine Statistiken ab und mit `+inventar` sein Inventar.\n**Musik**:`audio.play URL` um einzelne YouTube-Videos abzuspielen, `audio.playlist URL` um YouTube-Playlists abzuspielen, `audio.skip` um zum nächsten Video in der Playlist zu skippen, `audio.pause` und `audio.resume` sind selbsterklärend.')

    --Bot Control
    if msg.content == 'bot.stop' then
      if msg.author.id == '250368514408448013' then
        print('Saving...')
        writeTable('players.json', players)
        writeTable('objects.json', objects)
        print('Saved.')
        os.exit()
      end
    elseif msg.content == 'bot.restart' then
      if msg.author.id == '250368514408448013' then
        print('Saving...')
        writeTable('players.json', players)
        writeTable('objects.json', objects)
        print('Saved.')
        os.execute[[E:\DEV\Discordia_AtomCMD\luvit betabot.lua]]
        os.exit()
      end
    elseif msg.content == 'bot.save' then
      if msg.author.id == '250368514408448013' then
        print('Saving...')
        writeTable('players.json', players)
        writeTable('objects.json', objects)
        print('Saved.')
      end

    --Basic Commands
    elseif msg.content == '+rpgstart' then
      if players[msg.author.id].characterCreation == 0 then
        players[msg.author.id].characterCreation = 1
        msg.author:sendMessage('Willkommen zur Charaktererstellung. Als erstes muss ich dich fragen, welches Geschlecht du gerne wärst. (Mann oder Frau, tut mir echt leid Andere.)')
      elseif players[msg.author.id].characterCreation == 1 then
        msg.author:sendMessage('Wähle dein Geschlecht: Mann oder Frau?')
      elseif players[msg.author.id].characterCreation == 2 then
        msg.author:sendMessage('Wähle deine Rasse: Elf, Zwerg, Halbling oder Mensch?')
      elseif players[msg.author.id].characterCreation == 3 then
        msg.author:sendMessage('Wähle deine Klasse: Priester, Assasine, Krieger oder Magier?')
      end
    elseif msg.content == '+stats' then
      if players[msg.author.id].characterCreation == 4 then
        msg.channel:sendMessage('**'..msg.author.mentionString..'s Stats:**\n**HP:** '..players[msg.author.id].hp..'\n**Level:** '..players[msg.author.id].level..'\n**Geschlecht:** '..players[msg.author.id].gender..'\n**Rasse:** '..players[msg.author.id].race..'\n**Klasse:** '..players[msg.author.id].class)
      else
        msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart.')
      end
    elseif msg.content == '+inventar' then
      if players[msg.author.id].characterCreation == 4 then
        local inventoryString = ''
        for k,v in pairs(players[msg.author.id].inventory) do
          inventoryString = inventoryString..v.amount..' '..k..'\n'
        end
        msg.channel:sendMessage('**'..msg.author.mentionString..'s Inventar:**\n'..inventoryString..'Um genauere Informationen zu erhalten, schreibe `+info <Name des Gegenstandes>`.')
      else
        msg.channel:sendMessage('Bitte erstelle zuerst einen Charakter mit +rpgstart.')
      end
    elseif string.match(msg.content, '+info ') then
      for k,v in pairs(players[msg.author.id].inventory) do
        if string.gsub(msg.content, '+info ', '') == k then
          msg.channel:sendMessage(objects[string.gsub(msg.content, '+info ', '')].info)
        end
      end

    --Character Creation
    elseif players[msg.author.id].characterCreation and players[msg.author.id].characterCreation < 4 then
      if string.match(msg.content, 'Mann') then
        characterCreationF(1, 'gender', 'Mann', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne ein flinker, intelligenter Elf oder lieber ein kleiner, praktischer Halbling? Wie wäre es mit einem starken Zwerg der nicht ganz so hell in der Birne ist oder einem klassischem, ausgeglichenem Menschen?')
      elseif string.match(msg.content, 'Frau') then
        characterCreationF(1, 'gender', 'Frau', 'Schöne Sache, '..msg.author.mentionString..', schöne Sache. Nun zu deiner Rasse: Wärst du gerne eine flinke, intelligente Elfe oder lieber eine kleine, praktische Halblingsfrau? Wie wäre es mit einer starken Zwergenfrau die nicht ganz so hell in der Birne ist oder einer klassischen, ausgeglichenen Menschenfrau?')
      elseif string.match(msg.content, 'Zwerg') then
        characterCreationF(2, 'race', 'Zwerg', 'Soso. Ein Zwerg. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.match(msg.content, 'Mensch') then
        characterCreationF(2, 'race', 'Mensch', 'Soso. Ein Mensch. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.match(msg.content, 'Elfe') then
        characterCreationF(2, 'race', 'Elf', 'Soso. Eine Elfe. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.match(msg.content, 'Elf') then
        characterCreationF(2, 'race', 'Elf', 'Soso. Ein Elf. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.match(msg.content, 'Halbling') then
        characterCreationF(2, 'race', 'Halbling', 'Soso. Ein Halbling. Als letztes suche dir bitte eine Klasse aus: Möchtest du ein von Gott getriebener Priester sein? Oder ein hinterhältiger Assasine? Möchtest du mit der Kraft eines Kriegers zuschlagen können oder bist du ein Magier mit voller Trickkiste?')
      elseif string.match(msg.content, 'Priester') then
        characterCreationF(3, 'class', 'Priester', 'Ein Geistiger also. Interessante Wahl.')
      elseif string.match(msg.content, 'Assasine') then
        characterCreationF(3, 'class', 'Assasine', 'Ein Assasine also. Interessante Wahl.')
      elseif string.match(msg.content, 'Krieger') then
        characterCreationF(3, 'class', 'Krieger', 'Ein Kämpfer also. Interessante Wahl.')
      elseif string.match(msg.content, 'Magier') then
        characterCreationF(3, 'class', 'Magier', 'Ein Magier also. Interessante Wahl.')

      end

    --Server-only Things
    elseif not msg.channel.isPrivate then

      --Music control
      if string.match(msg.content, 'audio.play ') then
        connection = vChannel:join()
        if connection then
          print('connected')
          playingURL = string.gsub(msg.content, 'audio.play ', '')
          local stream = getStream(playingURL) -- URL goes here
          print('playing')
          connection:playFile(stream)
        end
      elseif string.match(msg.content, 'audio.playlist ') then
        playingURL = string.gsub(msg.content, 'audio.playlist ', '')
        streamPlaylist(playingURL)
      elseif msg.content == 'audio.pause' then
        connection:pauseStream(playingURL)
      elseif msg.content == 'audio.resume' then
        connection:resumeStream()
      elseif msg.content == 'audio.skip' then
        print('stopping')
        connection:stopStream()

      --DM-Commands
      elseif string.match(msg.content, 'Level') then
        if string.match(msg.content, 'für') and roleCheck(msg.member, 6) then
          if string.match(msg.content, 'Abzug') then
            for user in msg.mentionedUsers do
              local lvlMod = tonumber(string.match(msg.content, '%d*'))
              rpgUpdate(user, 'level', players[user.id].level - tonumber(string.match(msg.content, '%d*')), user.mentionString..' ist jetzt auf Level '..players[user.id].level - lvlMod..'.')
            end
          else
            for user in msg.mentionedUsers do
              local lvlMod = tonumber(string.match(msg.content, '%d*'))
              rpgUpdate(user, 'level', players[user.id].level + tonumber(string.match(msg.content, '%d*')), user.mentionString..' ist jetzt auf Level '..players[user.id].level + lvlMod..'.')
            end
          end
        end
      elseif msg.content == 'rpg.newitem' and roleCheck(msg.member, 6) then
        rpgUpdate(msg.author, 'itemCreation', 1, 'Name?')

      --Spells
      elseif string.match(msg.content, 'Ein Feuerball, mit viel Geknall') and (players[msg.author.id].class == 'Magier' or players[msg.author.id].class == 'Erschaffer') then
        for user in msg.mentionedUsers do
          rpgUpdate(user, 'hp', players[user.id].hp - 1, user.mentionString..' wurde getroffen und hat jetzt nur noch '..tostring(players[user.id].hp - 1)..' HP.')
        end

      --Basic Commands
      elseif string.match(msg.content, '~lua ') and roleCheck(msg.member, 3) then
        local output = io.output(loadstring(string.gsub(msg.content, '~lua ', ''))())
        msg.channel:sendMessage(output)

      --Item Creation
      elseif players[msg.author.id].itemCreation ~= 0 and roleCheck(msg.member, 6) then
        if players[msg.author.id].itemCreation == 1 then
          objects[msg.content] = {}
          players[msg.author.id].creating = msg.content
          players[msg.author.id].itemCreation = 2
          msg.channel:sendMessage('Info?')
        elseif players[msg.author.id].itemCreation == 2 then
          objects[players[msg.author.id].creating].info = msg.content
          players[msg.author.id].itemCreation = nil
          players[msg.author.id].creating = nil
        end
      end
    end
    --Random Chests
    if math.random(1,15) == 3 or msg.content == 'ranChest' then
      local randval = math.random(1, len(objects)) -- get a random point
      local randentry
      local count = 0
      for k,v in pairs(objects) do
        count = count + 1
        if(count == randval) then
          randentry = {key = k, val = v}
        end
      end
      msg.channel:sendMessage('Du hast eine Kiste gefunden. Sie enthielt ein '..randentry.key..'.')
      if not players[msg.author.id].inventory[randentry.key] then
        players[msg.author.id].inventory[randentry.key] = {}
      end
      setmetatable(players[msg.author.id].inventory[randentry.key], players.mt)
      players[msg.author.id].inventory[randentry.key].amount = players[msg.author.id].inventory[randentry.key].amount + 1
    end
  end
end)

client:run('MjU0OTUyNjQ5OTIzODg3MTA0.CyWk6Q.xzZ1t5kFtX3I05wNZxjVuhSEOJU')
