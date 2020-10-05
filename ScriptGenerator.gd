extends Node

var CardScripts = {}
var EffectScripts = {}
var MutationScripts = {}

func init():
	var effectfile = File.new()
	effectfile.open("res://Effects/Effect Sheet.txt", effectfile.READ)
	while not effectfile.eof_reached():
		var line = str(effectfile.get_line())
		if line != "" && !line.begins_with("\t") && !line.begins_with("Name"):
			createEffectFunctions(line)
	effectfile.close()
	
	var cardfile = File.new()
	cardfile.open("res://Card/Card Sheet.txt", cardfile.READ)
	while not cardfile.eof_reached():
		var line = str(cardfile.get_line())
		if line != "" && !line.begins_with("\t") && !line.begins_with("Name"):
			createCardFunctions(line)
	cardfile.close()
	
	var posmutfile = File.new()
	posmutfile.open("res://Body/Positive Mutation Sheet.txt", posmutfile.READ)
	while not posmutfile.eof_reached():
		var line = str(posmutfile.get_line())
		if line != "" && !line.begins_with("\t") && !line.begins_with("Name"):
			createMutationFunctions(line, "Positive")
	posmutfile.close()

	var negmutfile = File.new()
	negmutfile.open("res://Body/Negative Mutation Sheet.txt", negmutfile.READ)
	while not negmutfile.eof_reached():
		var line = str(negmutfile.get_line())
		if line != "" && !line.begins_with("\t") && !line.begins_with("Name"):
			createMutationFunctions(line, "Negative")
	negmutfile.close()

#builds the card script from a line of the spreadsheet
func createCardFunctions(cardstring):
	var script = GDScript.new()
	
	var cardName = ""
	var cardType = ""
	var cardDescription = ""
	var costDescription = ""
	var logOutput = ""
	var cardActions = {}
	var actionValues = {}
	var cardProperties = []
	var uniqueFlags = []
	var uniqueValue = 0
	
	var functionString
	
	var mods = {
		"Burn": false,
		"Flow": false,
		"Stay": 0,
		"Link": 0,
		"Push": false,
		"Copy": false,
		"Void": false,}
	
	var values = cardstring.replace("\"", "").split("\t")
	cardName = values[0]
	values.remove(0)
	cardType = values[0]
	if cardType.begins_with("Device"):
		cardType = "Device"
	values.remove(0)
	cardDescription = values[0]
	if cardType == "Device":
		cardDescription += " Destroy this card."
	elif cardType == "Item":
		cardDescription += " Burn this card."
	values.remove(0)
	logOutput = values[0]
	values.remove(0)
	
	var scriptString = "\nvar Card\nvar Combat\nvar myself\nvar opponent\nvar opponentHealth\n\n"
	scriptString += "func init(c):\n\tCard = c"
	
	scriptString += "\n\nfunc initCombat():"
	scriptString += "\n\tCombat = Card.Combat\n\tmyself = Card.myself\n\topponent = Card.opponent\n\topponentHealth = opponent.CurrentHealth\n"
	
	functionString = "\nfunc useCard(copytimes = 0):"
	var costString = ""
	
	for i in values.size():
		var action = values[i]
		if action == "CUSTOMCOPYFUNCTION":
			scriptString += uniqueCopyFunction(cardName, actionValues)
			cardProperties.append(action)
		elif action == "UNIQUEFUNCTION":
			functionString += uniqueCardFunction(cardName, actionValues)
		elif action == "release":
			var sname = "strangleCombat" + str(i)
			functionString += "\n\tvar " + sname + " = myself.Effects.getEffect('Stranglehold (Attacker)').Combat"
			functionString += "\n\t" + sname + ".enemy.removeEffect('Stranglehold (Target)')"
			functionString += "\n\t" + sname + ".me.removeEffect('Stranglehold (Attacker)')"
			functionString += "\n\tCard.CombatDeck.get_ref().addTempCard('" + cardName.replace(" (Release)", "") + "')"
			cardProperties.append("burn")
			cardProperties.append("forceUsable")
		elif action == "priority":
			uniqueFlags.append("topPriority")
		elif action == "flow" || action == "push":
			mods[action.capitalize()] = true
		elif ": " in action:
			var act = action.split(": ")
			var tab = "\n\t"
			
			if act[0].begins_with("(times("):
				actionValues["times"] = 0
				var timesarr = act[0].split("))")
				act[0] = timesarr[1]
				var times = timesarr[0].replace("(times(", "")
				functionString += tab + "var actualtimes" + str(i) + " = Card.calculate('" + times + "')"
				functionString += tab + "actionValues['times'] = actualtimes" + str(i)
				functionString += tab + "for times" + str(i) + " in actualtimes" + str(i) + ":"
				tab += "\t"
			
			cardActions[act[0]] = act[1]
			
			if act[0] == "action":
				functionString += tab + "Combat." + act[1] + "(myself, opponent, Card)"
			elif act[0] == "link" || act[0] == "stay":
				mods[act[0].capitalize()] = int(act[1])
			elif act[0] == "removeEffect":
				functionString += tab + "myself.removeEffect('" + act[1] + "')"
			elif act[0].ends_with("ffect"):
				var target = "opponent"
				if act[0].begins_with("self"):
					target = "myself"
				
				var parts = act[1].split(", ")
				if parts[0].begins_with("(") && parts[0].ends_with(")"):
					var numtimes = parts[0].replace("(", "").replace(")", "")
					parts.remove(0)
					functionString += tab + "for i in Card.calculate('" + str(numtimes) + "'):"
					tab += "\t"
					
				actionValues[act[0] + "Value"] = 0
				actionValues[act[0] + "Turns"] = 0
				#var valname = "_" + act[0] + "val" + str(i)
				var effectName = parts[0]
				parts.remove(0)
				if parts.size() == 0:
					functionString += tab + "Card.addEffect(" + target + ", '" + effectName + "', 'N/A', '-1')"
				elif parts.size() == 2:
					functionString += tab + "Card.addEffect(" + target + ", '" + effectName + "', '" + parts[0] + "', '" + parts[1] + "')"
				else:
					var effectProperties = EffectScripts[effectName][0]
					if "permanent" in effectProperties:
						functionString += tab + "actionValues['" + act[0] + "Value'] += Card.addEffect(" + target + ", '" + effectName + "', '" + parts[0] + "', '-1')"
					else:
						functionString += tab + "actionValues['" + act[0] + "Turns'] += Card.addEffect(" + target + ", '" + effectName + "', 'N/A', '" + parts[0] + "')"
			elif act[0].ends_with("amageOT"):
				var target = "opponent"
				if act[0].begins_with("noDefenses"):
					act[0] = act[0].replace("noDefenses", "")
					functionString += tab + "if opponent.CurrentHealth < opponentHealth:"
					tab += "\t"
				if act[0].begins_with("self"):
					target = "myself"
				var direct = "indirect"
				if "irect" in act[0]:
					direct = "direct"
				var val = act[1].split(", ")[0]
				functionString += tab + "var damageVal" + str(i) + " = Card.calculate('" + val + "')"
				functionString += tab + "var damageTurns" + str(i) + " = Card.calculate('" + act[1].split(", ")[1] + "')"
				functionString += tab + "actionValues['" + act[0] + "Value'] += damageVal" + str(i)
				functionString += tab + "actionValues['" + act[0] + "Turns'] += Combat." + direct + "DamageOverTime('" + val + "', damageTurns" + str(i) + ", " + target + ", Card)"
				actionValues[act[0] + 'Value'] = 0
				actionValues[act[0] + 'Turns'] = 0
			elif act[0].ends_with("OT"):
				var lose = "Gain "
				var target = "myself"
				var effstring = act[0]
				if effstring.begins_with("enemy"):
					target = "opponent"
					effstring = effstring.replace("enemy", "")
				if effstring.begins_with("lose") || effstring.begins_with("Lose"):
					lose = "Lose "
					effstring = effstring.substr(4)
				
				var effname = lose + effstring.replace("OT", "").capitalize()
				var vals = act[1].split(", ")
				functionString += tab + "actionValues['" + act[0] + "Value'] += Card.calculate('" + vals[0] + "')"
				functionString += tab + "actionValues['" + act[0] + "Turns'] += Card.addEffect(" + target + ", '" + effname + "', '" + vals[0] + "', '" + vals[1] + "')"
				actionValues[act[0] + 'Value'] = 0
				actionValues[act[0] + 'Turns'] = 0
			elif act[0].ends_with("rigger"):
				var target = "opponent"
				if act[0].begins_with("self"):
					target = "myself"
				functionString += tab + target + ".trigger('" + act[1] + "')"
			elif act[0] == "stranglehold":
				functionString += tab + "Card.addEffect(opponent, 'Stranglehold (Target)', '', -1)"
				functionString += tab + "Card.addEffect(myself, 'Stranglehold (Attacker)', Card.calculate('" + act[1] + "'), -1)"
				cardProperties.append("stranglehold")
			elif act[0].ends_with("gainStat"):
				actionValues[act[0] + "Value"] = 0
				actionValues[act[0] + "Turns"] = 0
				
				var target = "myself"
				if act[0].begins_with("enemy"):
					target = "opponent"
				var parts = act[1].split(", ")
				var updown = " Up"
				if parts[1].begins_with("-"):
					updown = " Down"
				var effname = parts[0] + updown
				var valuename = act[0] + "val" + str(i)
				var turnsname = act[0] + "turns" + str(i)
				functionString += tab + "var " + valuename + " = Card.calculate('" + parts[1] + "')"
				functionString += tab + "var " + turnsname + " = Card.calculate('" + parts[2] + "')"
				functionString += tab + "actionValues['" + act[0] + "Value'] += " + valuename
				functionString += tab + "actionValues['" + act[0] + "Turns'] += " + turnsname
				functionString += tab + "Card.addEffect(" + target + ", '" + effname + "', " + valuename + ", " + turnsname + ")"
			elif act[0] == "statUp":
				var vals = act[1].split(", ")
				actionValues[act[0]] = 0
				functionString += tab + "actionValues['" + act[0] + "'] += myself.addStat('" + vals[0] + "', myself.calculate('" + vals[1] + "'))"
			elif act[0] == "insertEnemyDeck" || act[0] == "insertSelfDeck":
				var parts = act[1].split(", ")
				var cardstuff = parts[0].split(" (")
				var amount = cardstuff[1].replace(")", "")
				
				var enemyDeck = ""
				if act[0] == "insertEnemyDeck":
					enemyDeck += ".enemyCombatDeck"
				
				var uniquevalue = "0"
				if parts.size() > 1:
					uniquevalue = parts[1]
				
				functionString += tab + "if Card.CombatDeck != null:"
				functionString += tab + "\tfor i in Card.calculate('" + amount + "'):"
				functionString += tab + "\t\tCard.CombatDeck.get_ref()" + enemyDeck + ".addTempCard('" + cardstuff[0] + "', myself.convertStat('" + uniquevalue + "'))"
			elif act[0] == "burnDeck":
				functionString += tab + "Card.CombatDeck.get_ref().burnDeck('" + act[1] + "')"
			elif act[0] == "UNIQUEFLAG":
				uniqueFlags.append(act[1])
			elif act[0] == "ALTERNATE":
				#cardProperties.append("hasAlternate")
				var parts = act[1].split(", ")
				functionString += tab + "if !Card.has('noAlternate'):"
				tab += "\t"
				if parts[0] == "enemyDefenses":
					functionString += tab + "if opponent.Block() > 0 || opponent.Shield() > 0 || opponent.Allies():"
					functionString += tab + "\topponent.tickEffect('Block')"
					functionString += tab + "\topponent.tickEffect('Shield')"
					functionString += tab + "\topponent.tickAllies()"
				elif parts[0] == "enemyBlockOrShield":
					functionString += tab + "if opponent.Block() > 0 || opponent.Shield() > 0:"
					functionString += tab + "\topponent.tickEffect('Block')"
					functionString += tab + "\topponent.tickEffect('Shield')"
				elif parts[0] == "enemyBlock":
					functionString += tab + "if opponent.Block() > 0:"
					functionString += tab + "\topponent.tickEffect('Block')"
				elif parts[0] == "noEnemyDefenses":
					functionString += tab + "if opponent.Block() <= 0 && opponent.Shield() <= 0 && !opponent.Allies():"
				elif parts[0] == "selfDefenses":
					functionString += tab + "if myself.Block() > 0 || myself.Shield() > 0 || myself.Allies():"
					functionString += tab + "\tmyself.tickEffect('Block')"
					functionString += tab + "\tmyself.tickEffect('Shield')"
					functionString += tab + "\tmyself.tickAllies()"
				elif parts[0] == "selfShield":
					functionString += tab + "if myself.Shield() > 0:"
					functionString += tab + "\tmyself.tickEffect('Shield')"
				elif parts[0] == "selfBlock":
					functionString += tab + "if myself.Block() > 0:"
					functionString += tab + "\tmyself.tickEffect('Block')"
				elif parts[0] == "extraTurn":
					functionString += tab + "if myself.onExtraTurn:"
					functionString += tab + "\tmyself.tickEffect('Extra Turns')"
				elif parts[0] == "selfDistance":
					functionString += tab + "if myself.hasEffect('Distance'):"
					functionString += tab + "\tmyself.tickEffect('Distance')"
				functionString += tab + "\tCard.cardProperties.append('usedAlternate')"
				functionString += tab + "\tmyself.useGhostCard('" + cardName + "Ghost" + "', Combat, copytimes)"
				functionString += tab + "\treturn"
				functionString += tab + "elif copytimes > 0:"
				functionString += tab + "\tCard.cardProperties.append('noAlternate')"
			elif act[0].ends_with("Cost"):
				var thing = act[0].replace("Cost", "")
				var f = "gain" + thing.capitalize()
				var mult = 1
				if "Health" in f:
					f = "takeIndirectDamage"
					mult = -1
				costDescription += "Costs " + cardActions[act[0]] + " " + thing + ". "
				cardActions[act[0]] = str(-mult*int(cardActions[act[0]]))
				uniqueFlags.append(act[0])
				actionValues[act[0]] = 0
				var line = ""
				if act[0] == "manaCost" && cardType == "Spell":
					line += tab + "if !myself.hasEffect('No Mana Cost'):"
					tab += "\t"
					line += tab + "if myself.hasMutation('Brainless'):"
					line += tab + "\tactionValues['" + act[0] + "'] += Combat.takeDirectDamage(-Card.calculate(cardActions['" + act[0] + "']), Card)"
					line += tab + "else:"
					tab += "\t"
				line += tab + "actionValues['" + act[0] + "'] += Combat." + f + "(Card.calculate(cardActions['" + act[0] + "']), Card)"
				costString += line
			elif act[0] != "fill" && act[0] != "discard":
				var f = act[0]
				var target = ""
				if act[0].begins_with("enemy"):
					target = "opponent.current"
					f = f.replace("enemy", "")
				actionValues[act[0]] = 0
				if f == "gainBlock" || f == "gainShield":
					actionValues[act[0] + "Turns"] = 0
					var varname = "turns" + str(i)
					var vals = act[1].split(", ")
					if vals.size() > 1:
						functionString += tab + "var " + varname + " = Card.calculate('" + vals[1] + "')"
					else:
						functionString += tab + "var " + varname + " = 1"
					functionString += tab + "actionValues['" + act[0] + "Turns'] += " + varname
					functionString += tab + "actionValues['" + act[0] + "'] += " + target + "Combat." + f + "(Card.calculate('" + vals[0] + "'), Card, " + varname + ")"
				else:
					functionString += tab + "actionValues['" + act[0] + "'] += " + target + "Combat." + f + "(Card.calculate(cardActions['" + act[0] + "']), Card)"
		elif len(action) > 0:
			cardProperties.append(action)
	
	if "dealDirectDamage" in actionValues:
		var aimString = "\n\tmyself.trigger('Aim')"
		functionString = functionString.replace("func useCard():", "func useCard():" + aimString)
	
	var logString = ""
	if logOutput != 'N/A':
		logString += "\n\tCard.textlog.push(Card.cardLogOutput())"
	if "logFirst" in cardProperties:
		functionString = functionString.replace("func useCard():", "func useCard():" + logString)
	else:
		functionString +=  logString
	
	if costString == "":
		costString = "\n\tpass"
	if functionString == "\nfunc useCard(copytimes = 0):":
		functionString += "\n\tpass"
	costString = "\nfunc useCost():" + costString
	scriptString += costString
	scriptString += functionString
	
	var usableString = "\n\nfunc isUsable():"
	usableString += "\n\tif Card.handIndex == -1"
	#
	if "manaCost" in cardActions:
		usableString += " || (-int(cardActions['manaCost']) > myself.CurrentMana && !myself.hasEffect('No Mana Cost'))"
	if "energyCost" in cardActions:
		usableString += " || (-int(cardActions['energyCost']) > myself.CurrentEnergy && !myself.onExtraTurn && myself.ExtraTurns() <= 0)"
	if "distanceCost" in cardActions:
		usableString += " || -int(cardActions['distanceCost']) > myself.Distance()"
	if "defensesCost" in cardProperties:
		usableString += "|| opponent.Block() > 0 || opponent.Shield() > 0 || opponent.Allies()"
		costDescription += "Opponent must have no defenses. "
	if "forceUsable" in cardProperties:
		costDescription += "This card must be played. "
	if "stranglehold" in cardActions:
		usableString += " || (opponent.hasEffect('strangleholdBad') && myself.getEffect('strangleholdGood') > 0)"
	if cardType == "Attack":
		usableString += " || myself.hasEffect('Tornado')"
	if hasOffensiveAction(cardActions, actionValues):
		usableString += "|| myself.hasEffect('Frozen')"
	if !"dealDirectDamage" in cardActions:
		usableString += " || myself.hasEffect('Taunt') && Card.CombatDeck.get_ref().hasAction('dealDirectDamage')"
	if "UNIQUECOST" in cardProperties:
		var uniquecostlist = uniqueCardCost(cardName)
		usableString += uniquecostlist[0]
		costDescription += uniquecostlist[1]
	usableString += ":\n\t\treturn false\n\treturn true"
	scriptString += usableString
	
	var varString = "var cardName = \"" + cardName + "\""
	varString += "\nvar cardType = \"" + cardType + "\""
	varString += "\nvar cardDescription = \"" + cardDescription + "\""
	varString += "\nvar costDescription = \"" + costDescription + "\""
	varString += "\nvar logOutput = \"" + logOutput + "\""
	
	var liststring = "\nvar cardActions = {"
	for key in cardActions:
		liststring += "'" + key + "':'" + cardActions[key] + "',"
	liststring += "}"
	varString += liststring
	
	liststring = "\nvar actionValues = {"
	for key in actionValues:
		liststring += "'" + key + "':" + str(actionValues[key]) + ","
	liststring += "}"
	varString += liststring
	
	liststring = "\nvar cardProperties = ["
	for value in cardProperties:
		liststring += "'" + value + "',"
	liststring += "]"
	varString += liststring
	
	liststring = "\nvar uniqueFlags = ["
	for value in uniqueFlags:
		liststring += "'" + value + "',"
	liststring += "]"
	varString += liststring
	
	varString += "\nvar uniqueValue = " + str(uniqueValue)
	
	liststring = "\nvar mods = {"
	for key in mods:
		liststring += "'" + key + "':" + str(mods[key]).to_lower() + ","
	liststring += "}"
	varString += liststring
	
	scriptString = varString + scriptString

#	if cardName == "Gorger":
#		print_debug(scriptString)
	script.set_source_code(scriptString)
	script.resource_name = "Card" + cardName
	script.resource_path = "res://Card/" + script.resource_name + ".gd"
	script.reload()
	CardScripts[cardName] = script

func hasOffensiveAction(cardActions, actionValues):
	var list = [
		"dealDirectDamage",
		"dealIndirectDamage",
		"damageOT",
		"directDamageOT",
		"stranglehold",
		"effectValue",
	]
	for thing in list:
		if thing in cardActions || thing in actionValues:
			return true
	for act in cardActions:
		if act.begins_with("enemyLose"):
			return true
	if "action" in cardActions && cardActions["action"] == "pierce":
		return true
	return false

func uniqueCardCost(cardName):
	var coststr = " || "
	var costDescription = ""
	if cardName == "Lightning":
		coststr += "myself.CurrentMana <= 0"
		costDescription += "Costs all your mana. "
	elif cardName == "Digest":
		coststr += "!(opponent.hasEffect('strangleholdBad') || (opponent.hasEffect('takeIndirectDamage') && opponent.hasEffect('loseEnergy')))"
		costDescription += "Opponent must be envenomed. "
	return [coststr, costDescription]

func uniqueCardFunction(cardName, actionValues):
	var functionstr = ""
	var tab = "\n\t"
	if cardName == "Stab":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar stabdamage = Card.calculate('1 d Str')"
		functionstr += "\n\tif myself.isPlayer() && myself.onExtraTurn:"
		functionstr += "\n\t\tstabdamage += Card.calculate('Str')"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(stabdamage, Card)"
	elif cardName == "Backstab" || cardName == "Transpierce":
		actionValues['dealDirectDamage'] = 0
		functionstr += tab + "var damage = Card.calculate('effect(Extra_Turns) * Str')"
		functionstr += tab + "actionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
		functionstr += tab + "myself.removeEffect('Extra Turns')"
	elif cardName == "Punch":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = Card.calculate('1 d 3')"
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Attack':"
		functionstr += "\n\t\tdamage += Card.calculate('1 d Str')"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Counter":
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Defend':"
		functionstr += "\n\t\tactionValues['gainEnergy'] += Combat.gainEnergy(10, Card)"
	elif cardName == "Rend":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = int(opponent.CurrentHealth*(float(myself.Strength + myself.tempStrength)/50))"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Execute":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = int((opponent.MaxHealth-opponent.CurrentHealth)*(float(myself.Strength + myself.tempStrength)*3/100))"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Pummel":
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Defend':"
		functionstr += "\n\t\tmyself.useGhostCard('Second Pummel', Combat)"
	elif cardName == "Knock Out":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = 0"
		functionstr += "\n\tfor i in myself.getEffect('Pummel'):"
		functionstr += "\n\t\tdamage += Card.calculate('1 d Str')"
		functionstr += "\n\tmyself.tickEffect('Pummel')"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Sweep":
		actionValues['gainEnergy'] = 0
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Defend':"
		functionstr += "\n\t\tactionValues['gainEnergy'] += Combat.gainEnergy(6, Card)"
	elif cardName == "Surge":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = myself.Strength + myself.tempStrength"
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Spell':"
		functionstr += "\n\t\tdamage *= 2"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Siphon":
		actionValues['gainHealth'] = 0
		actionValues['gainEnergy'] = 0
		actionValues['gainMana'] = 0
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardType == 'Spell':"
		functionstr += "\n\t\tactionValues['gainHealth'] += Combat.gainHealth(Card.calculate('dealDirectDamage'), Card)"
		functionstr += "\n\t\tactionValues['gainEnergy'] += Combat.gainEnergy(Card.calculate('dealDirectDamage'), Card)"
		functionstr += "\n\t\tactionValues['gainMana'] += Combat.gainMana(Card.calculate('dealDirectDamage'), Card)"
		functionstr += "\n\t\tCard.logOutput = '{You} siphon{s} {enemyName}, dealing {dealDirectDamage} damage and gaining {gainHealth} health, {gainEnergy} energy, and {gainMana} mana.'"
		functionstr += "\n\telse:"
		functionstr += "\n\t\tCard.logOutput = '{You} stab{s} {enemyName} for {dealDirectDamage} damage.'"
	elif cardName == "Hook":
		actionValues['dealDirectDamage'] = 0
		actionValues['gainEnergy'] = 0
		functionstr += tab + "actionValues['dealDirectDamage'] += Combat.dealDirectDamage(1, Card)"
		functionstr += tab + "if opponent.hasDefenses():"
		functionstr += tab + "\tCard.logOutput = '{You} hook{s} {enemyName}, dealing {dealDirectDamage} damage.'"
		functionstr += tab + "else:"
		functionstr += tab + "\tactionValues['gainEnergy'] += Combat.gainEnergy(6, Card)"
		functionstr += tab + "\tCard.addEffect(myself, 'Strength Up', 5, 2)"
		functionstr += tab + "\tCard.logOutput = '{You} hook{s} {enemyName}, dealing {dealDirectDamage} damage and pulling {them} down.'"
	elif cardName == "Fortify":
		actionValues['gainBlock'] = 0
		functionstr += tab + "var effectList = myself.Effects.effectList"
		functionstr += tab + "var fortifyblock = Card.calculate('Dex / 2')"
		functionstr += tab + "if myself.hasEffect('Permablock'):"
		functionstr += tab + "\teffectList['Permablock'][0].add(fortifyblock)"
		functionstr += tab + "\tactionValues['gainBlock'] += fortifyblock"
		functionstr += tab + "if myself.hasEffect('Block'):"
		functionstr += tab + "\tfor eff in effectList['Block']:"
		functionstr += tab + "\t\teff.add(fortifyblock)"
		functionstr += tab + "\t\teff.turns += 1"
		functionstr += tab + "\t\tactionValues['gainBlock'] += fortifyblock"
	elif cardName == "Lightning":
		#custom Brainless interaction
		actionValues['dealDirectDamage'] = 0
		actionValues['dealDirectDamageTimes'] = 0
		functionstr += tab + "var times"
		functionstr += tab + "if myself.hasMutation('Brainless'):"
		functionstr += tab + "\ttimes = myself.CurrentHealth"
		functionstr += tab + "\tCombat.takeDirectDamage(times, Card)"
		functionstr += tab + "else:"
		functionstr += tab + "\ttimes = myself.CurrentMana"
		functionstr += tab + "\tCombat.gainMana(-times, Card)"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['dealDirectDamageTimes'] += 1"
		functionstr += tab + "\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(Card.calculate('1 d 2'), Card)"
	elif cardName == "Splinter":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(Card.calculate('Int * ' + str(myself.getEffect('Extra Turns'))), Card)"
		functionstr += "\n\tmyself.removeEffect('Extra Turns')"
	elif cardName == "Compromise":
		functionstr += "\n\tvar compromise = Card.calculate('Int / 3')"
		functionstr += "\n\tfor effect in opponent.Effects.badList:"
		functionstr += "\n\t\teffect.addTurns(compromise * 2)"
		functionstr += "\n\tfor i in compromise:"
		functionstr += "\n\t\topponent.Effects.turn('Bad')"
	elif cardName == "Sunbeam":
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardName == 'Sunbeam':"
		functionstr += "\n\t\tmyself.addEffect('Intelligence Up', Card.calculate('Int'), Card.calculate('4'), Card)"
		functionstr += "\n\t\tCard.logOutput = '{You} double {your} power and sear{s} {enemyName} for {dealDirectDamage} damage.'"
		functionstr += "\n\telse:"
		functionstr += "\n\t\tCard.logOutput = '{You} sear{s} {enemyName} for {dealDirectDamage} damage.'"
	elif cardName == "Mirror":
		functionstr += "\n\tvar enemylastplayed = opponent.currentCombatDeck.lastPlayed"
		functionstr += "\n\tif enemylastplayed != null:"
		functionstr += "\n\t\tCard.logOutput = 'N/A'"
		functionstr += "\n\t\tmyself.useGhostCard(enemylastplayed.cardName, Combat)"
		functionstr += "\n\telse:"
		functionstr += "\n\t\tCard.logOutput = '[enemy]There was nothing for {you} to mirror.'"
	elif cardName == "Soothing Tonic":
		functionstr += "\n\tmyself.Effects.removeEffects('Bad')"
	elif cardName == "Zap":
		actionValues["dealDirectDamage"] = 0
		functionstr += "\n\tvar zapdamage = Card.calculate('Int')"
		functionstr += "\n\tif zapdamage > 10:"
		functionstr += "\n\t\tzapdamage = 10"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(zapdamage, Card)"
	elif cardName == "Stand Firm":
		actionValues["gainShield"] = 0
		actionValues["gainEnergy"] = 0
		actionValues["times"] = 0
		functionstr += tab + "myself.tickEffect('Bide')"
		functionstr += tab + "var bide = myself.getEffect('Bide')"
		functionstr += tab + "actionValues['times'] += bide"
		functionstr += tab + "for b in bide:"
		functionstr += tab + "\tactionValues['gainShield'] += Combat.gainShield(1, Card, 5)"
		functionstr += tab + "\tactionValues['gainEnergy'] -= Combat.gainEnergy(-10, Card)"
		functionstr += tab + "myself.removeEffect('Bide')"
	elif cardName == "Phase":
		actionValues['gainHealth'] = 0
		functionstr += tab + "actionValues['gainHealth'] += Combat.gainHealth(1-myself.CurrentHealth, Card)"
	elif cardName == "Ossify":
		actionValues["gainBlock"] = 0
		functionstr += "\n\tvar ossifytimes = 0"
		functionstr += "\n\tfor eff in myself.Effects.goodList:"
		functionstr += "\n\t\tif eff.has('ally'):"
		functionstr += "\n\t\t\tossifytimes += 1"
		functionstr += "\n\tactionValues['gainBlock'] += Combat.gainBlock(Card.calculate('Int * ' + str(ossifytimes)), Card, 3)"
	elif cardName == "Give Flesh":
		functionstr += tab + "for eff in myself.Effects.goodList:"
		functionstr += tab + "\tif eff.has('ally'):"
		functionstr += tab + "\t\teff.turns += 2"
		functionstr += tab + "\t\teff.tick()"
	elif cardName == "Return":
		functionstr += tab + "var breakpointeffect = myself.Effects.mostRecentCharacterRecording()"
		functionstr += tab + "myself.currentCombatEvent.applyRecording(breakpointeffect.specialValue[0])"
		functionstr += tab + "Combat.takeIndirectDamage(myself.CurrentHealth*66/100, Card)"
		functionstr += tab + "if breakpointeffect.value > 0:"
		functionstr += tab + "\tCard.addEffect(myself, 'You', myself.CurrentHealth, -1)"
		functionstr += tab + "\tvar goback = myself.Effects.effectList['You'][myself.Effects.effectList['You'].size()-1]"
		functionstr += tab + "\tgoback.specialValue = breakpointeffect.specialValue[1].duplicate(false)"
		functionstr += tab + "\tgoback.displayTurns = 'Next: ' + goback.specialValue[0][0]"
		functionstr += tab + "\tgoback.get_node('tick/effectSprite').set_texture(load('res://Effects/effectSprites/effect_You ' + goback.specialValue[0][1] + '.png'))"
		#functionstr += tab + "goback.setText(str(goback.value) + ' ' + goback.specialValue[0][0])"
		#functionstr += "\n\tgoback.specialValue.pop_front()"
	elif cardName == "Record":
		functionstr += tab + "Card.CombatDeck.get_ref().forceBurn(Card)"
		functionstr += tab + "myself.addEffect('Record', 0, -1, Card)"
	elif cardName == "Skip":
		actionValues["times"] = 0
		functionstr += tab + "var skiptimes = Card.calculate('Int / 4')"
		functionstr += tab + "actionValues['times'] += skiptimes"
		functionstr += tab + "for j in skiptimes:"
		functionstr += tab + "\tmyself.Effects.turn('Good')"
		functionstr += tab + "\tmyself.Effects.turn('Bad')"
	elif cardName == "Adjust":
		actionValues["gainHealth"] = 0
		actionValues["gainEnergy"] = 0
		actionValues["gainMana"] = 0
		functionstr += tab + "var lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += tab + "if lastplayed == null:"
		functionstr += tab + "\tCard.logOutput = '{You} fail{s} to adjust {your} vitals.'"
		#lose mana
		functionstr += tab + "elif lastplayed.cardType == 'Attack':"
		functionstr += tab + "\tactionValues['gainHealth'] += Combat.gainHealth(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainEnergy'] += Combat.gainEnergy(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainMana'] += Combat.gainMana(-10, Card)"
		functionstr += tab + "\tCard.logOutput = '{You} adjust{s} {your} vitals, gaining {gainHealth} health, {gainEnergy} energy, and losing {gainMana} mana.'"
		#lose energy
		functionstr += tab + "elif lastplayed.cardType == 'Defend':"
		functionstr += tab + "\tactionValues['gainHealth'] += Combat.gainHealth(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainMana'] += Combat.gainMana(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainEnergy'] += Combat.gainEnergy(-10, Card)"
		functionstr += tab + "\tCard.logOutput = '{You} adjust{s} {your} vitals, gaining {gainHealth} health, {gainMana} mana, and losing {gainEnergy} energy.'"
		#lose health
		functionstr += tab + "elif lastplayed.cardType == 'Spell':"
		functionstr += tab + "\tactionValues['gainEnergy'] += Combat.gainEnergy(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainMana'] += Combat.gainMana(Card.calculate('Int * 2'), Card)"
		functionstr += tab + "\tactionValues['gainHealth'] += Combat.gainHealth(-10, Card)"
		functionstr += tab + "\tCard.logOutput = '{You} adjust{s} {your} vitals, gaining {gainEnergy} energy, {gainMana} mana, and losing {gainHealth} health.'"
		functionstr += tab + "else:"
		functionstr += tab + "\tCard.logOutput = '{You} fail{s} to adjust {your} vitals.'"
	if cardName == "Reconstruction":
		functionstr += tab + "myself.CurrentHealth = myself.convertStat('MHP')"
		functionstr += tab + "myself.updateUI()"
		
	return functionstr

#functions for cards that have a unique interaction with the Copy effect
#usually, the case is that the original card function uses a resource to gain somehting, and that next copy has no resources to gain off of
#so, things need to be done simultaneously
func uniqueCopyFunction(cardName, actionValues):
	var functionstr = "\nfunc useCustomCopy(times):"
	var tab = "\n\t"
	#lines of code for printing out the log and setting all the recorded back to zero so they don't add up to the next card play
	var logString = tab + "\tif Card.logOutput != 'N/A':"
	logString += tab + "\t\tCard.textlog.push(Card.cardLogOutput())"
	logString += tab + "\tfor key in Card.actionValues:"
	logString += tab + "\t\tCard.actionValues[key] = 0"
	
	if cardName == "Backstab":
		functionstr += tab + "var damage = Card.calculate('effect(Extra_Turns) * Str')"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
		functionstr += logString
		functionstr += tab + "myself.removeEffect('Extra Turns')"
	elif cardName == "Transpierce":
		actionValues['gainEnergy'] = 0
		functionstr += tab + "var piercing = false"
		functionstr += tab + "var damage = Card.calculate('effect(Extra_Turns) * Str')"
		functionstr += tab + "if opponent.Block() > 0 || opponent.Shield() > 0:"
		functionstr += tab + "\topponent.tickEffect('Block')"
		functionstr += tab + "\topponent.tickEffect('Shield')"
		functionstr += tab + "\tpiercing = true"
		functionstr += tab + "\tdamage = Card.calculate('Str')"
		functionstr += tab + "\tCard.logOutput = '{You} [you]pierce[n] {enemyName} and gain {gainEnergy} energy.'"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tif piercing:"
		functionstr += tab + "\t\tCombat.pierce(myself, opponent, Card)"
		functionstr += tab + "\t\tactionValues['gainEnergy'] += Combat.gainEnergy(damage, Card)"
		functionstr += tab + "\telse:"
		functionstr += tab + "\t\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
		functionstr += logString
		functionstr += tab + "if !piercing:"
		functionstr += tab + "\tmyself.removeEffect('Extra Turns')"
		functionstr += tab + "Card.logOutput = '{You} stab{s} {enemyName} for {dealDirectDamage} damage.'"
	elif cardName == "Hook":
		functionstr += tab + "var extra = true"
		functionstr += tab + "actionValues['dealDirectDamage'] += Combat.dealDirectDamage(1, Card)"
		functionstr += tab + "if opponent.hasDefenses():"
		functionstr += tab + "\topponent.tickEffect('Block')"
		functionstr += tab + "\topponent.tickEffect('Shield')"
		functionstr += tab + "\topponent.tickAllies()"
		functionstr += tab + "\textra = false"
		functionstr += tab + "\tCard.logOutput = '{You} hook{s} {enemyName}, dealing {dealDirectDamage} damage.'"
		functionstr += tab + "else:"
		functionstr += tab + "\tCard.logOutput = '{You} hook{s} {enemyName}, dealing {dealDirectDamage} damage and pulling {them} down.'"
		functionstr += tab + "\tactionValues['gainEnergy'] += Combat.gainEnergy(6, Card)"
		functionstr += tab + "\tCard.addEffect(myself, 'Strength Up', 5, 2)"
		functionstr += tab + "Card.textlog.push(Card.cardLogOutput())"
		functionstr += tab + "for key in Card.actionValues:"
		functionstr += tab + "\tCard.actionValues[key] = 0"
		functionstr += tab + "for i in times-1:"
		functionstr += tab + "\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(1, Card)"
		functionstr += tab + "\tif extra:"
		functionstr += tab + "\t\tactionValues['gainEnergy'] += Combat.gainEnergy(6, Card)"
		functionstr += tab + "\t\tCard.addEffect(myself, 'Strength Up', 5, 2)"
		functionstr += logString
	elif cardName == "Stand Firm":
		functionstr += tab + "myself.tickEffect('Bide')"
		functionstr += tab + "var bide = myself.getEffect('Bide')"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['times'] += bide"
		functionstr += tab + "\tfor b in bide:"
		functionstr += tab + "\t\tactionValues['gainShield'] += Combat.gainShield(1, Card, 5)"
		functionstr += tab + "\t\tactionValues['gainEnergy'] -= Combat.gainEnergy(-10, Card)"
		functionstr += logString
		functionstr += tab + "myself.removeEffect('Bide')"
	elif cardName == "Lightning":
		functionstr += tab + "var manatimes = myself.CurrentMana"
		functionstr += tab + "for  i in times:"
		functionstr += tab + "\tfor j in manatimes:"
		functionstr += tab + "\t\tactionValues['dealDirectDamageTimes'] += 1"
		functionstr += tab + "\t\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(Card.calculate('1 d 2'), Card)"
		functionstr += logString
		functionstr += tab + "Combat.gainMana(-manatimes, Card)"
	elif cardName == "Demolish":
		functionstr += tab + "var currentBlock = Card.calculate('block')"
		functionstr += tab + "var currentInt = Card.calculate('Int')"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(currentBlock, Card)"
		functionstr += tab + "\tCombat.selfPierce(myself, opponent, Card)"
		functionstr += tab + "\tactionValues['gainMana'] += Combat.gainMana(currentInt, Card)"
		functionstr += logString
	elif cardName == "Sunbeam":
		functionstr += tab + "var lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += tab + "var currentInt = Card.calculate('Int')"
		functionstr += tab + "if lastplayed != null && lastplayed.cardName == 'Sunbeam':"
		functionstr += tab + "\tfor i in times:"
		functionstr += tab + "\t\tmyself.addEffect('Intelligence Up', currentInt, Card.calculate('4'), Card)"
		functionstr += tab + "\tCard.logOutput = '{You} double {your} power and sear{s} {enemyName} for {dealDirectDamage} damage.'"
		functionstr += tab + "else:"
		functionstr += tab + "\tCard.logOutput = '{You} sear{s} {enemyName} for {dealDirectDamage} damage.'"
		functionstr += tab + "var newInt = Card.calculate('Int')"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(newInt, Card)"
		functionstr += logString
	elif cardName == "Nova":
		functionstr += tab + "var numstars = 0"
		functionstr += tab + "for proto in myself.Effects.effectList['Protostar']:"
		#really dumb way of doing this, essentially removing the end function so that I can call it manually through here instead so the star doesn't get removed
		functionstr += tab + "\tproto.effectProperties.erase('end function')"
		functionstr += tab + "\tnumstars += 1"
		functionstr += tab + "for i in times:"
		functionstr += logString
		functionstr += tab + "\tfor j in numstars:"
		functionstr += tab + "\t\tmyself.useGhostCard('Protostar Nova', Combat)"
		functionstr += tab + "myself.removeEffect('Protostar')"
	elif cardName == "Coagulate":
		functionstr += tab + "var missinghp = Card.calculate('MHP') - myself.CurrentHealth"
		functionstr += tab + "var currentInt = Card.calculate('Int')"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tactionValues['gainBlock'] += Combat.gainBlock(missinghp, Card, 3)"
		functionstr += tab + "\tactionValues['gainHealth'] += Combat.gainHealth(Card.calculate(str(currentInt) + ' d 2'), Card)"
		functionstr += tab + "\tactionValues['gainMana'] += Combat.gainMana(Card.calculate(str(currentInt) + ' d 2'), Card)"
		functionstr += logString
	elif cardName == "Return":
		functionstr += tab + "var breakpointeffect = myself.Effects.mostRecentCharacterRecording()"
		functionstr += tab + "myself.currentCombatEvent.applyRecording(breakpointeffect.specialValue[0])"
		functionstr += tab + "Combat.takeIndirectDamage(myself.CurrentHealth*66/100, Card)"
		functionstr += tab + "for i in times:"
		functionstr += tab + "\tif breakpointeffect.value > 0:"
		functionstr += tab + "\t\tCard.addEffect(myself, 'You', myself.CurrentHealth, -1)"
		functionstr += tab + "\t\tvar goback = myself.Effects.effectList['You'][myself.Effects.effectList['You'].size()-1]"
		functionstr += tab + "\t\tgoback.specialValue = breakpointeffect.specialValue[1].duplicate(false)"
		functionstr += tab + "\t\tgoback.displayTurns = 'Next: ' + goback.specialValue[0][0]"
		functionstr += tab + "\t\tgoback.get_node('tick/effectSprite').set_texture(load('res://Effects/effectSprites/effect_You ' + goback.specialValue[0][1] + '.png'))"
		functionstr += logString

	#functionstr += tab + ""
	return functionstr


#builds the effect script from a line of the spreadsheet
func createEffectFunctions(effectstring):
	var script = GDScript.new()
	
	var effectName
	var effectProperties = []
	
	var values = effectstring.replace("\"", "").split("\t")
	effectName = values[0]
	values.remove(0)
	if int(values[0]) == -1:
		effectProperties.append("permanent")
		effectProperties.append("stackable")
	values.remove(0)
	effectProperties.append(values[0])
	values.remove(0)
	
	var scriptString = "\nvar Effect\nvar Card\nvar Combat\nvar myself\nvar opponent\nvar cycle = 0\nvar cycleCounter = 1\n\n"
	if effectName == "You":
		scriptString += "var iterator = 0\n"
	scriptString += "\nfunc init(e):\n\tEffect = e\n\tCard = e.Card\n\tCombat = e.Combat\n\tmyself = Combat.me\n\topponent = Combat.enemy"
	
	var initString = ""
	var turnString = ""
	var triggerString = ""
	var endString = ""
	
	if effectName == "Record":
		initString += "\n\tEffect.setBreakpoint()"
	
	var actives = 0
	for i in values.size():
		var action = values[i]
		if !":" in action:
			if action == "N/A" || action == "":
				break
			elif action == "unstackable":
				effectProperties.erase("stackable")
			else:
				effectProperties.append(action)
				if action == "ally":
					effectProperties.erase("stackable")
		elif action.begins_with("gainStat"):
			var things = action.split(": ")[1].split(", ")
			initString += "\n\tmyself.addTempStat('" + things[0] + "', Effect.calculate('" + things[1] + "'))"
			endString += "\n\tmyself.addTempStat('" + things[0] + "', -Effect.calculate('" + things[1] + "'))"
			effectProperties.append("stat")
		elif action.begins_with("cycle"):
			if "permanent" in effectProperties:
				effectProperties.erase("stackable")
			var tab = "\n\t"
			effectProperties.append("cycle")
			initString += tab + "cycle = Effect.calculate('" + str(action.split(": ")[1]) + "')"
			initString += tab + "if cycle < 1:"
			initString += tab + "\tcycle = 1"
			
			turnString += tab + "if cycleCounter == cycle:"
			turnString += tab + "\tcycleCounter = 1"
			turnString += tab + "\tEffect.tick()"
			turnString += tab + "else:"
			turnString += tab + "\tcycleCounter += 1"
			turnString += tab + "\treturn"
		else:
			actives += 1
			var whichstring = "turnString"
			var actionstring = ""
			if action.begins_with("(trigger)"):
				action = action.replace("(trigger)", "")
				whichstring = "triggerString"
				actives -= 1
			elif action.begins_with("(end)"):
				action = action.replace("(end)", "")
				whichstring = "endString"
				actives -= 1
			
			var act = action.split(": ")
			var tab = "\n\t"
			
			if act[0] == "self":
				if act[1] == "remove":
					actionstring += tab + "Effect.get_parent().removeEffect('" + effectName + "', Effect)"
				elif act[1] == "decrement":
					actionstring += tab + "Effect.add(-1)"
				elif act[1] == "zero":
					actionstring += tab + "Effect.add(-int(Effect.value))"
				elif act[1] == "UNIQUEFUNCTION":
					actionstring += uniqueEffectFunction(effectName, whichstring)
			elif act[0] == "fill":
				actionstring += tab + "myself.currentCombatDeck.fillHand('" + act[1] + "')"
				actionstring += tab + "myself.currentCombatDeck.printHand()"
			elif act[0] == "action":
				actionstring += tab + "Combat." + act[1] + "(myself, opponent, Card)"
			elif act[0] == "addTurns":
				actionstring += tab + "Effect.turns += Effect.calculate('" + act[1] + "')"
			elif act[0] == "trigger":
				actionstring += tab + "opponent.trigger('" + act[1] + "')"
				if !"counterpart" in effectProperties:
					effectProperties.append("counterpart")
			elif act[0] == "useCard":
				var cardname = act[1]
				if " (" in act[1]:
					cardname = act[1].split(" (")[0]
					actionstring += tab + "var times" + str(i) + " = Effect.calculate('" + act[1].split(" (")[1].replace(")", "") + "')"
					actionstring += tab + "for i in times" + str(i) + ":"
					tab += "\t"
				actionstring += tab + "myself.useGhostCard('" + cardname + "', Combat)"
			elif act[0] == "manaCost":
				actionstring += tab + "if Effect.calculate('" + act[1] + "') > myself.CurrentMana && !myself.hasMutation('Brainless'):"
				actionstring += tab + "\treturn"
				actionstring += tab + "if myself.hasMutation('Brainless'):"
				actionstring += tab + "\tCombat.takeDirectDamage(Effect.calculate('" + act[1] + "'), Card)"
				actionstring += tab + "else:"
				actionstring += tab + "\tCombat.gainMana(-Effect.calculate('" + act[1] + "'), Card)"
			else:
				actionstring += tab + "Combat." + act[0] + "(Effect.calculate('" + act[1] + "'), Card)"
				#if act[0] == "gainEnergy":
					#actionstring += tab + "Combat.checkEnergy()"
			
			if whichstring == "turnString":
				turnString += actionstring
			elif whichstring == "triggerString":
				triggerString += actionstring
			elif whichstring == "endString":
				endString += actionstring
	
	var replaceable = true
	if "stackable" in effectProperties || "ally" in effectProperties || "replaceable" in effectProperties || "unreplaceable" in effectProperties:
		replaceable = false
	if turnString == "":
		turnString = "\n\tpass"
	else:
		replaceable = false
		if !"cycle" in effectProperties:
			turnString = "\n\tEffect.tick()" + turnString
	if triggerString == "":
		triggerString = "\n\tpass"
	else:
		replaceable = false
	if endString == "":
		endString = "\n\tpass"
	else:
		replaceable = false
		effectProperties.append("end function")
	
	#if the effect has all empty methods, is unstackable, and is not an ally, then it will be replaced if reapplied to the Affected
	if replaceable:
		effectProperties.append("replaceable")
	
	scriptString += initString + "\n\nfunc turnFunction():" + turnString + "\n\nfunc triggerFunction():" + triggerString + "\n\nfunc endFunction():\n\tif (!myself.isAlive() || !opponent.isAlive()) && !'stat' in effectProperties:\n\t\treturn" + endString
	var varString = "\nvar effectName = '" + effectName + "'"

	if actives > 0:
		effectProperties.append("active")
	var liststring = "\nvar effectProperties = ["
	for prop in effectProperties:
		liststring += "'" + prop + "',"
	liststring += "]"
	varString += liststring
	scriptString = varString + scriptString
	
#	if effectName == "Muscle Mass":
#		print_debug(scriptString)
	script.set_source_code(scriptString)
	script.resource_name = "Effect" + effectName
	script.resource_path = "res://Effect/" + script.resource_name + ".gd"
	script.reload()
	EffectScripts[effectName] = [effectProperties, script]

func uniqueEffectFunction(effectName, whichstring):
	var functionstr = ""
	var tab = "\n\t"
	if effectName == "Stranglehold (Target)":
		if whichstring == "turnString":
			functionstr += tab + "opponent.trigger('Stranglehold (Attacker)')"
		elif whichstring == "triggerString":
			functionstr += tab + "if !'released' in effectProperties:"
			tab += "\t"
			functionstr += tab + "opponent.currentCombatDeck.addTempCard(Card.cardName + ' (Release)')"
			functionstr += tab + "opponent.currentCombatDeck.fillHand(Card.cardName + ' (Release)')"
			functionstr += tab + "opponent.currentCombatDeck.printHand()"
			functionstr += tab + "effectProperties.append('released')"
	elif effectName == "Stranglehold (Attacker)":
		functionstr += tab + "myself.useGhostCard(Card.cardName + ' (Attack)', Combat)"
	elif effectName == "Protostar":
		if whichstring == "endString":
			functionstr += tab + "if Effect.specialValue:"
			functionstr += tab + "\tmyself.useGhostCard('Protostar Nova', Combat)"
			functionstr += tab + "else:"
			functionstr += tab + "\tmyself.useGhostCard('Protostar Hit', Combat)"
		elif whichstring == "triggerString":
			functionstr += tab + "Effect.specialValue = true"
	elif effectName == "Record":
		functionstr += tab + "var lastcard = Card.CombatDeck.get_ref().lastClicked"
		functionstr += tab + "if lastcard != null:"
		functionstr += tab + "\tEffect.add(1)"
		functionstr += tab + "\tEffect.specialValue[1].append([lastcard.cardName, lastcard.cardType])"
		#functionstr += tab + "print_debug(specialValue[1])"
	elif effectName == "You":
		functionstr += tab + "myself.useGhostCard(Effect.specialValue[iterator][0], Combat)"
		functionstr += tab + "iterator += 1"
		functionstr += tab + "if iterator >= Effect.specialValue.size():"
		functionstr += tab + "\titerator = 0"
		functionstr += tab + "Effect.get_node('tick/effectSprite').set_texture(load('res://Effects/effectSprites/effect_You ' + Effect.specialValue[iterator][1] + '.png'))"
		functionstr += tab + "Effect.displayTurns = 'Next: ' + Effect.specialValue[iterator][0]"
		#functionstr += tab + "Effect.setText(str(Effect.value) + ' ' + Effect.specialValue[iterator][0])"
	return functionstr


#builds the mutation script from a line of the spreadsheet
func createMutationFunctions(mutstring, positive):
	var script = GDScript.new()
	
	var mutationName
	var mutationDescription
	var mutationLog
	var enemyAvailable
	var enemyLog
	
	var values = mutstring.replace("\"", "").split("\t")
	mutationName = values[0]
	values.remove(0)
	mutationDescription = values[0]
	values.remove(0)
	mutationLog = values[0]
	values.remove(0)
	enemyAvailable = values[0]
	values.remove(0)
	enemyLog = values[0]
	values.remove(0)
	
	var scriptString = "\nvar mutationName = '" + mutationName + "'\nvar mutationDescription = '" + mutationDescription + "'\nvar multiplier = 1" + "\nvar myself\nvar Combat\nvar opponent"
	
	var initString = "\nfunc init(m):\n\tmyself = m\n\tCombat = myself.currentCombat"
	var valueString = ""
	var triggerString = "\n\tif CardCombat != null:"
	triggerString += "\n\t\tCombat = CardCombat"
	triggerString += "\n\t\topponent = Combat.enemy"
	var startString = "\n\tCombat = myself.currentCombat"
	startString += "\n\topponent = Combat.enemy"
	
	for i in values.size():
		if values[i] == "\t" || values[i] == "":
			continue
		var act = values[i].split(": ")
		var tab = "\n\t"
		if act[0] == "value" || act[0] == "UNIQUECHECKvalue":
			if act[0].begins_with("UNIQUECHECK"):
				valueString += uniqueMutationCheck(mutationName, tab)
				tab += "\t"
			#by default the variable is named 'value' and starts at 0
			var num = act[1]
			if num != "multiplier":
				num = "myself.calculate('" + num + "')"
			else:
				num = "1"
			valueString += tab + "value += " + num
		elif act[0] == "scale":
			var vals = act[1].split(", ")
			initString += tab + "myself.addMutScaling('" + vals[0] + "', " + vals[1] + ")"
		elif act[0] == "addCard":
			initString += tab + "if myself.isPlayer():"
			initString += tab + "\tmyself.Bag.addCard('" + act[1] + "')"
			initString += tab + "else:"
			initString += tab + "\tmyself.Deck.addCard('" + act[1] + "')"
		else:
			var actionString = ""
			
			if act[0].begins_with("UNIQUECHECK"):
				act[0] = act[0].replace("UNIQUECHECK", "")
				actionString += uniqueMutationCheck(mutationName, tab)
				tab += "\t"
			
			var whichstring = ""
			if act[0].begins_with("(start)"):
				act[0] = act[0].replace("(start)", "")
				whichstring = "startString"
			elif act[0].begins_with("(trigger)"):
				act[0] = act[0].replace("(trigger)", "")
				whichstring = "triggerString"
			
			if whichstring != "":
				actionString += tab + "for i in multiplier:"
				tab += "\t"
			
			if act[0] == "UNIQUEFUNCTION":
				actionString += uniqueMutationFunction(mutationName, tab)
			elif act[0] == "statUp":
				var vals = act[1].split(", ")
				actionString += tab + "myself.addStat('" + vals[0] + "', myself.calculate('" + vals[1] + "'))"
			elif act[0] == "gainStat":
				var target = "myself"
				if act[0].begins_with("enemy"):
					target = "opponent"
				var parts = act[1].split(", ")
				var updown = " Up"
				if parts[1].begins_with("-"):
					updown = " Down"
				var effname = parts[0] + updown
				actionString += tab + "Combat.addEffect(" + target + ", '" + effname + "', myself.calculate('" + parts[1] + "'), myself.calculate('" + parts[2] + "'))"
			elif act[0].ends_with("ffect"):
				var target = "opponent"
				if act[0].begins_with("self"):
					target = "myself"
					
				var parts = act[1].split(", ")
				if parts[0].begins_with("(") && parts[0].ends_with(")"):
					var numtimes = parts[0].replace("(", "").replace(")", "")
					parts.remove(0)
					actionString += tab + "for i in myself.calculate('" + str(numtimes) + "'):"
					tab += "\t"
					
				var effectName = parts[0]
				parts.remove(0)
				if parts.size() == 0:
					actionString += tab + "Combat.addEffect(" + target + ", '" + effectName + "', 'N/A', '-1')"
				elif parts.size() == 2:
					actionString += tab + "Combat.addEffect(" + target + ", '" + effectName + "', '" + parts[0] + "', '" + parts[1] + "')"
				else:
					var effectProperties = EffectScripts[effectName][0]
					if "permanent" in effectProperties:
						actionString += tab + "Combat.addEffect(" + target + ", '" + effectName + "', '" + parts[0] + "', '-1')"
					else:
						actionString += tab + "Combat.addEffect(" + target + ", '" + effectName + "', 'N/A', '" + parts[0] + "')"
			elif act[0] == "useCard":
				var cardname = act[1]
				if " (" in act[1]:
					cardname = act[1].split(" (")[0]
					actionString += tab + "var times" + str(i) + " = myself.calculate('" + act[1].split(" (")[1].replace(")", "") + "')"
					actionString += tab + "for i in times" + str(i) + ":"
					tab += "\t"
				actionString += tab + "myself.useGhostCard('" + cardname + "', Combat)"
			elif act[0] == "action":
				actionString += tab + "Combat." + act[1] + "(myself, opponent, null)"
			elif act[0] != "N/A":
				var f = act[0]
				var target = ""
				if act[0].begins_with("enemy"):
					target = "opponent.current"
					f = f.replace("enemy", "")
				if f == "gainBlock" || f == "gainShield":
					var varname = "turns" + str(i)
					var vals = act[1].split(", ")
					if vals.size() > 1:
						actionString += tab + "var " + varname + " = myself.calculate('" + vals[1] + "')"
					else:
						actionString += tab + "var " + varname + " = 1"
					actionString += tab + target + "Combat." + f + "(myself.calculate('" + vals[0] + "'), null, " + varname + ")"
				else:
					actionString += tab + target + "Combat." + f + "(myself.calculate('" + act[1] + "'), null)"
			
			if whichstring == "triggerString":
				triggerString += actionString
			elif whichstring == "startString":
				startString += actionString
			else:
				initString += actionString
	
	valueString += "\n\treturn value*multiplier"
	if triggerString == "":
		triggerString = "\n\tpass"
		
	scriptString += initString + "\n\nfunc startFunction():" + startString + "\n\nfunc valueFunction(amount = 0):\n\tvar value = 0" + valueString + "\n\nfunc triggerFunction(CardCombat = null, amount = 0):" + triggerString

#	if mutationName == "Berserk":
#		print_debug(scriptString)
	script.set_source_code(scriptString)
	script.resource_name = "Mutation" + mutationName
	script.resource_path = "res://Body/" + script.resource_name + ".gd"
	script.reload()
	var mutationVariables = {
		"positive": positive,
		"mutationDescription": mutationDescription,
		"mutationLog": mutationLog,
		"enemyAvailable": enemyAvailable,
		"enemyLog": enemyLog
	}
	MutationScripts[mutationName] = [mutationVariables, script]

func uniqueMutationCheck(mutName, tab):
	# the variable to compare to is called 'amount'
	var checkString = tab + "if "
	if mutName == "Focused Rage":
		checkString += "amount >= myself.calculate('Mut * 5')"
	elif mutName == "Knockback":
		checkString += "amount >= myself.calculate('Mut * 6')"
	checkString += ":"
	return checkString
	
func uniqueMutationFunction(mutName, tab):
	var actionString = ""
	if mutName == "":
		actionString += tab + ""
	return actionString
