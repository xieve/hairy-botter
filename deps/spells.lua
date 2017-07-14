local spells = {
	["Accio"] = {
		name = "Accio",
		replyWithObj = "Hier ist %s.",
		replyWithoutObj = "Was willst du haben?",
	  init = function (player, args)
			if objects[args] then
	    	inventoryUpdate(player, args, 1)
			end
	  end
	},

	["Amnesia"] = {
		name = "Amnesia",
		replyWithObj = "%s  weiß jetzt nichts mehr.",
		replyWithoutObj = "Du hast alles vergessen."
	},

	["Anapneo"] = {
		name = "Anapneo",
		replyWithObj = "%s  atmet tief durch",
		replyWithoutObj = "*atmet*"
	},

	["Avis"] = {
		name = "Avis",
		replyWithObj = "%s ist jetzt voller Vögel.",
		replyWithoutObj = ":bird: :bird: :bird:"
	},

	["Aguamenti"] = {
		name = "Aguamenti",
		replyWithObj = "Jetzt ist %s voll mit Wasser. :sweat_drops:",
		replyWithoutObj = "Platsch! :sweat_drops:"
	},

	["Alohomora"] = {
		name = "Alohomora",
		replyWithObj = "%s ist jetzt geöffnet.",
		replyWithoutObj = "Die Tür ist geöffnet."
	},

	["Avada Kedavra"] = {
		name = "Avada Kedavra",
		replyWithObj = "%s ist soeben verstorben.",
		replyWithoutObj = "Du hast deinen Gegenüber soeben umgebracht."
	},

	["Confringo"] = {
		name = "Confringo",
		replyWithObj = "%s ist explodiert. :boom:", -- has to be false when init works
		replyWithoutObj = "Boom! :boom:",
		init = function (player, args, msg)
			for user in msg.mentionedUsers do
				statUpdate(user, "hp", {
						value = players[user.id].hp.value - 25,
						max = players[user.id].hp.max
					},
					"HP",
					":boom: "..player.mentionString.." wurde getroffen und hat jetzt nur noch "..tostring(players[user.id].hp.value - 5).." HP."
				)
			end
		end
	},

	["Confundo"] = {
		name = "Confundo",
		replyWithObj = "Verwirrtes %s.",
		replyWithoutObj = "Du verwirrst mich..."
	},

	["Crucio"] = {
		name = "Crucio",
		replyWithObj = "%s hat jetzt ganz großes Aua.",
		replyWithoutObj = "Aua"
	},

	["Expelliarmus"] = {
		name = "Expelliarmus",
		replyWithObj = "Whooosch! %ss Zauberstab fliegt auf dich zu.",
		replyWithoutObj = "Whoop. Und ein weiterer Zauberstab gehört dir."
	},

	["Expulso"] = {
		name = "Expulso",
		replyWithObj = "%s ist explodiert. :boom:",
		replyWithoutObj = "Boom! :boom:"
	},

	["Finite"] = {
		name = "Finite",
		replyWithObj = "Die Zauber von %s sind jetzt unwirksam.",
		replyWithoutObj = "Die Zauber haben aufgehört zu wirken."
	},

	["Furunkulus"] = {
		name = "Furunkulus",
		replyWithObj = "%s ist nun voll mit Furunkeln.",
		replyWithoutObj = "Igitt!"
	},

	["Incendio"] = {
		name = "Incendio",
		replyWithObj = "Du hast %s angezündet.",
		replyWithoutObj = ":fire:"
	},

	["Langlock"] = {
		name = "Langlock",
		replyWithObj = "Halt die Klappe %s.",
		replyWithoutObj = "Wen?"
	},

	["Levicorpus"] = {
		name = "Levicorpus",
		replyWithObj = "%s hängt an den Beinen in der Luft.",
		replyWithoutObj = ":skate_falschrum:"
	},

	["Liberacorpus"] = {
		name = "Liberacorpus",
		replyWithObj = "Beendet das in der Luft hängen von %s.",
		replyWithoutObj = "Plumps."
	},

	["Lumos"] = {
		name = "Lumos",
		replyWithObj = "%s hat eine Erleuchtung.",
		replyWithoutObj = "Es werde Licht!"
	},

	["Muffliato"] = {
		name = "Muffliato",
		replyWithObj = "%s und du können jetzt ungestört miteinander sprechen.",
		replyWithoutObj = "*Quiiiiiieck*"
	},

	["Nox"] = {
		name = "Nox",
		replyWithObj = "Ich glaube, so funktioniert das nicht. Dunkel ist es aber jetzt trotzdem.",
		replyWithoutObj = "Es werde Dunkelheit!"
	},

	["Oppugno"] = {
		name = "Oppugno",
		replyWithObj = "%s darf jetzt in dieser Szene die Hauptrolle spielen: https://www.youtube.com/watch?v=Lw0FP9putKM",
		replyWithoutObj = "https://www.youtube.com/watch?v=Lw0FP9putKM"
	},

	["Orchideus"] = {
		name = "Orchideus",
		replyWithObj = "Aus deinem Zauberstab sprießen ein paar Blumen für %s.",
		replyWithoutObj = ":bouquet: :bouquet:"
	},

	["Quietus"] = {
		name = "Quietus",
		replyWithObj = "%s ist jetzt wieder leiser.",
		replyWithoutObj = "Du bist jetzt wieder leiser."
	},

	["Reparo"] = {
		name = "Reparo",
		replyWithObj = "%s wurde repariert.",
		replyWithoutObj = "Es wurde repariert."
	},

	["Rictusempra"] = {
		name = "Rictusempra",
		replyWithObj = "Kitzelt %s.",
		replyWithoutObj = "Hihihihi"
	},

	["Scourgify"] = {
		name = "Scourgify",
		replyWithObj = "Jetzt ist %s wieder trocken. Oder feucht, je nachdem wie gut du bist.",
		replyWithoutObj = "Alles wieder trocken!"
	},

	["Sectumsempra"] = {
		name = "Sectumsempra",
		replyWithObj = "%s hat jetzt großes Aua.",
		replyWithoutObj = "Du wagst es den Spruch des Halbblutprinzen zu verwenden??!?"
	},

	["Sonorus"] = {
		name = "Sonorus",
		replyWithObj = "**%s**",
		replyWithoutObj = "**Hallo**"
	},

	["Spuck Schnecken"] = {
		name = "Spuck Schnecken",
		replyWithObj = "%s spuckt jetzt Schnecken: :thermometer_face: :snail:",
		replyWithoutObj = ":thermometer_face: :snail:"
	},

	["Tarantallegra"] = {
		name = "Tarantallegra",
		replyWithObj = "%s: :dancer:",
		replyWithoutObj = ":dancer:"
	},

	["Vulnera Sanentur"] = {
		name = "Vulnera Sanentur",
		replyWithObj = "%s wird geheilt.",
		replyWithoutObj = "*heil*"
	},

	["Wingardium Leviosa"] = {
		name = "Wingardium Leviosa",
		replyWithObj = "%s nimmt jetzt Flugstunden",
		replyWithoutObj = "Hui!"
	}
}

local list = ""
local firstRun = true
for k,v in pairs(spells) do
	if firstRun then list = k
	else list = list..", "..k end
	firstRun = false
end
spells.list = list

return spells
