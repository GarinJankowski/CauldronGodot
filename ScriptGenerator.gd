extends Node

var CardScripts = {}
var EffectScripts = {}

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
	scriptString += "\n\tCombat = Card.Combat\n\tmyself = Card.myself\n\topponent = Card.opponent\n\topponentHealth = opponent.CurrentHealth\n\n"
	
	functionString = "func useCard():"
	
	for i in values.size():
		var action = values[i]
		if action == "UNIQUEFUNCTION":
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
			cardActions[act[0]] = act[1]
			
			if act[0] == "action":
				functionString += "\n\tCombat." + act[1] + "(myself, opponent, Card)"
			elif act[0] == "link" || act[0] == "stay":
				mods[act[0].capitalize()] = int(act[1])
			elif act[0].ends_with("ffect"):
				var target = "opponent"
				if act[0].begins_with("self"):
					target = "myself"
					
				var parts = act[1].split(", ")
				var tab = "\n\t"
				if parts[0].begins_with("(") && parts[0].ends_with(")"):
					var numtimes = parts[0].replace("(", "").replace(")", "")
					parts.remove(0)
					tab += "\t"
					functionString += "\n\tfor i in Card.calculate('" + str(numtimes) + "'):"
					
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
				var tab = "\n\t"
				if act[0].begins_with("noDefenses"):
					act[0] = act[0].replace("noDefenses", "")
					functionString += "\n\tif opponent.CurrentHealth < opponentHealth:"
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
				functionString += "\n\tactionValues['" + act[0] + "Value'] += Card.calculate('" + vals[0] + "')"
				functionString += "\n\tactionValues['" + act[0] + "Turns'] += Card.addEffect(" + target + ", '" + effname + "', '" + vals[0] + "', '" + vals[1] + "')"
				actionValues[act[0] + 'Value'] = 0
				actionValues[act[0] + 'Turns'] = 0
			elif act[0] == "stranglehold":
				functionString += "\n\topponent.addEffect('Stranglehold (Target)', '', -1, Card)"
				functionString += "\n\tmyself.addEffect('Stranglehold (Attacker)', Card.calculate('" + act[1] + "'), -1, Card)"
				cardProperties.append("stranglehold")
			elif act[0] == "gainStat":
				var parts = act[1].split(", ")
				var updown = " Up"
				if parts[1].begins_with("-"):
					updown = " Down"
				var effname = parts[0] + updown
				functionString += "\n\tCard.addEffect(myself, '" + effname + "', Card.calculate('" + parts[1] + "'), Card.calculate('" + parts[2] + "'))"
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
				
				functionString += "\n\tif Card.CombatDeck != null:"
				functionString += "\n\t\tfor i in Card.calculate('" + amount + "'):"
				functionString += "\n\t\t\tCard.CombatDeck.get_ref()" + enemyDeck + ".addTempCard('" + cardstuff[0] + "', myself.convertStat('" + uniquevalue + "'))"
			elif act[0] == "burnDeck":
				functionString += "\n\tCard.CombatDeck.get_ref().burnDeck('" + act[1] + "')"
			elif act[0] == "UNIQUEFLAG":
				uniqueFlags.append(act[1])
			elif act[0] == "ALTERNATE":
				var parts = act[1].split(", ")
				if parts[0] == "enemyDefenses":
					functionString += "\n\tif opponent.Block() > 0 || opponent.Shield() > 0 || opponent.Allies():"
					functionString += "\n\t\topponent.tickEffect('Block')"
					functionString += "\n\t\topponent.tickEffect('Shield')"
					functionString += "\n\t\topponent.tickAllies()"
				elif parts[0] == "enemyBlock":
					functionString += "\n\tif opponent.Block() > 0:"
					functionString += "\n\t\topponent.tickEffect('Block')"
				elif parts[0] == "noEnemyDefenses":
					functionString += "\n\tif opponent.Block() <= 0 && opponent.Shield() <= 0 && !opponent.Allies():"
				elif parts[0] == "selfDefenses":
					functionString += "\n\tif myself.Block() > 0 || myself.Shield() > 0 || myself.Allies():"
					functionString += "\n\t\tmyself.tickEffect('Block')"
					functionString += "\n\t\tmyself.tickEffect('Shield')"
					functionString += "\n\t\tmyself.tickAllies()"
				elif parts[0] == "selfShield":
					functionString += "\n\tif myself.Shield() > 0:"
					functionString += "\n\t\tmyself.tickEffect('Shield')"
				elif parts[0] == "selfBlock":
					functionString += "\n\tif myself.Block() > 0:"
					functionString += "\n\t\tmyself.tickEffect('Block')"
				elif parts[0] == "extraTurn":
					functionString += "\n\tif myself.onExtraTurn:"
					functionString += "\n\t\tmyself.tickEffect('Extra Turns')"
				functionString += "\n\t\tmyself.useGhostCard('" + parts[1] + "', Combat)"
				functionString += "\n\t\treturn"
			elif act[0] != "fill" && act[0] != "discard":
				var f = act[0]
				if f == "manaCost":
					f = "gainMana"
					costDescription += "Costs " + cardActions["manaCost"] + " mana. "
					cardActions["manaCost"] = str(-int(cardActions["manaCost"]))
					uniqueFlags.append("manaCost")
				elif f == "energyCost":
					f = "gainEnergy"
					costDescription += "Costs " + cardActions["energyCost"] + " energy. "
					cardActions["energyCost"] = str(-int(cardActions["energyCost"]))
					uniqueFlags.append("energyCost")
				
				actionValues[act[0]] = 0
				var line = ""
				if act[0] == "takeIndirectDamage" || act[0] == "dealIndirectDamage":
					line = "\n\tactionValues['" + act[0] + "'] += Combat." + f + "(Card.calculate(cardActions['" + act[0] + "']))"
				else:
					if act[0] == "manaCost":
						line = "\n\tif !myself.hasEffect('No Mana Cost'):"
						line += "\n\t\tactionValues['" + act[0] + "'] += Combat." + f + "(Card.calculate(cardActions['" + act[0] + "']), Card)"
					else:
						line = "\n\tactionValues['" + act[0] + "'] += Combat." + f + "(Card.calculate(cardActions['" + act[0] + "']), Card)"
				functionString += line
		elif len(action) > 0:
			cardProperties.append(action)
		
	
	functionString += "\n\tif Card.logOutput != 'N/A':"
	functionString += "\n\t\tCard.textlog.push(Card.cardLogOutput())"
	scriptString += functionString
	
	var usableString = "\n\nfunc isUsable():"
	usableString += "\n\tif Card.handIndex == -1"
	#
	if "manaCost" in cardActions:
		usableString += " || (-int(cardActions['manaCost']) > myself.CurrentMana && !myself.hasEffect('No Mana Cost'))"
	if "energyCost" in cardActions:
		usableString += " || (-int(cardActions['energyCost']) > myself.CurrentEnergy && !myself.onExtraTurn)"
	if "stranglehold" in cardActions:
		usableString += " || (opponent.hasEffect('strangleholdBad') && myself.getEffect('strangleholdGood') > 0)"
	if cardType == "Attack":
		usableString += " || myself.hasEffect('Tornado')"
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
	
	script.set_source_code(scriptString)
	script.resource_name = "Card" + cardName
	script.resource_path = "res://Card/" + script.resource_name + ".gd"
	script.reload()
	CardScripts[cardName] = script

func uniqueCardCost(cardName):
	var coststr = " || "
	var costDescription = ""
	if cardName == "Venom Bite" || cardName == "Gash" || cardName == "Venom Sac":
		coststr += "opponent.Block() > 0 || opponent.Shield() > 0 || opponent.Allies()"
		costDescription += "Enemy must have no defenses. "
	elif cardName == "Lightning":
		coststr += "myself.CurrentMana <= 0"
		costDescription += "Costs all your mana. "
	elif cardName == "Digest":
		coststr += "!(opponent.hasEffect('strangleholdBad') || (opponent.hasEffect('takeIndirectDamage') && opponent.hasEffect('loseEnergy')))"
		costDescription += "Enemy must be envenomed. "
	return [coststr, costDescription]

func uniqueCardFunction(cardName, actionValues):
	var functionstr = ""
	if cardName == "Stab" || cardName == "Lunge":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar strength = myself.Strength + myself.tempStrength"
		functionstr += "\n\tif myself.isPlayer() && myself.onExtraTurn:"
		functionstr += "\n\t\tstrength *= 2"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(strength, Card)"
	elif cardName == "Backstab":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = myself.Strength + myself.tempStrength + myself.getEffect('Extra Turns')*(myself.Strength + myself.tempStrength)"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(damage, Card)"
	elif cardName == "Stabilize":
		functionstr += "\n\tCombat.change(myself, 'Energy', -myself.CurrentEnergy)"
	elif cardName == "Punch":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tvar damage = 1"
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
		functionstr += "\n\tvar damage = int((opponent.MaxHealth-opponent.CurrentHealth)*(float(myself.Strength + myself.tempStrength)/50))"
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
	elif cardName == "Lightning":
		actionValues['dealDirectDamage'] = 0
		actionValues['dealDirectDamageTimes'] = 0
		functionstr += "\n\tvar times = myself.CurrentMana"
		functionstr += "\n\tCombat.gainMana(-times, Card)"
		functionstr += "\n\tfor i in times:"
		functionstr += "\n\t\tactionValues['dealDirectDamageTimes'] += 1"
		functionstr += "\n\t\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(Card.calculate('1 d 2'), Card)"
	elif cardName == "Freeze":
		functionstr += "\n\tvar lastplayed = Card.CombatDeck.get_ref().lastPlayed"
		functionstr += "\n\tif lastplayed != null && lastplayed.cardName == 'Freeze':"
		functionstr += "\n\t\tmyself.addEffect('Energized', '', 1, Card)"
	elif cardName == "Splinter":
		actionValues['dealDirectDamage'] = 0
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(Card.calculate('Int * ' + str(myself.getEffect('Extra Turns'))), Card)"
		functionstr += "\n\tmyself.removeEffect('Extra Turns')"
	elif cardName == "Compromise":
		functionstr += "\n\tvar compromise = Card.calculate('Int / 3')"
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
	elif cardName == "Go Back":
		functionstr += "\n\tvar breakpointeffect = myself.Effects.mostRecentCharacterRecording()"
		functionstr += "\n\tvar gobackturns = breakpointeffect.value-1"
		functionstr += "\n\tmyself.currentCombatEvent.applyRecording(breakpointeffect.specialValue[0])"
		functionstr += "\n\tvar goback = myself.newEffect('Go Back', 'Breakpoint', gobackturns, 'Good')"
		functionstr += "\n\tgoback.specialValue = breakpointeffect.specialValue[1].duplicate(false)"
		#functionstr += "\n\tprint_debug(goback.specialValue)"
		functionstr += "\n\tgoback.specialValue.pop_front()"
		functionstr += "\n\tbreakpointeffect.setBreakpoint()"
		#functionstr += "\n\tprint_debug(breakpointeffect.specialValue[1])"
	elif cardName == "Soothing Tonic":
		functionstr += "\n\tmyself.Effects.removeBadEffects()"
	elif cardName == "Zap":
		actionValues["dealDirectDamage"] = 0
		functionstr += "\n\tvar zapdamage = Card.calculate('Int')"
		functionstr += "\n\tif zapdamage > 10:"
		functionstr += "\n\t\tzapdamage = 10"
		functionstr += "\n\tactionValues['dealDirectDamage'] += Combat.dealDirectDamage(zapdamage, Card)"
	elif cardName == "Stand Firm":
		actionValues["gainShield"] = 0
		actionValues["gainEnergy"] = 0
		functionstr += "\n\tmyself.tickEffect('Bide')"
		functionstr += "\n\tvar bide = myself.getEffect('Bide')"
		functionstr += "\n\tactionValues['gainShield'] += Combat.gainShield(bide, Card)"
		functionstr += "\n\tactionValues['gainEnergy'] -= Combat.gainEnergy(-bide*10, Card)"
		functionstr += "\n\tmyself.removeEffect('Bide')"
	elif cardName == "Ossify":
		actionValues["gainBlock"] = 0
		functionstr += "\n\tvar ossifytimes = 0"
		functionstr += "\n\tfor eff in myself.Effects.effectListGood:"
		functionstr += "\n\t\tif eff.effectName == 'Arise':"
		functionstr += "\n\t\t\tossifytimes += 1"
		functionstr += "\n\tactionValues['gainBlock'] += Combat.gainBlock(Card.calculate('Int * ' + str(ossifytimes)), Card)"
		
	return functionstr


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
	
	var scriptString = "\nvar Effect\nvar Card\nvar Combat\nvar myself\nvar opponent\n\n"
	scriptString += "func init(e):\n\tEffect = e\n\tCard = e.Card\n\tCombat = e.Combat\n\tmyself = Combat.me\n\topponent = Combat.enemy"
	
	var initString = ""
	var turnString = ""
	var triggerString = ""
	var endString = ""
	
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
				elif act[1] == "UNIQUEFUNCTION":
					actionstring += uniqueEffectFunction(effectName, whichstring)
			elif act[0] == "fill":
				actionstring += tab + "myself.currentCombatDeck.fillHand('" + act[1] + "')"
				actionstring += tab + "myself.currentCombatDeck.printHand()"
			elif act[0] == "action":
				actionstring += tab + "Combat." + act[1] + "(myself, opponent, Card)"
			elif act[0] == "trigger":
				actionstring += tab + "opponent.trigger('" + act[1] + "')"
			elif act[0] == "useCard":
				var cardname = act[1]
				if " (" in act[1]:
					cardname = act[1].split(" (")[0]
					actionstring += tab + "var times" + str(i) + " = Effect.calculate('" + act[1].split(" (")[1].replace(")", "") + "')"
					actionstring += tab + "for i in times" + str(i) + ":"
					tab += "\t"
				actionstring += tab + "myself.useGhostCard('" + cardname + "', Combat)"
			elif act[0] == "manaCost":
				actionstring += tab + "if Effect.calculate('" + act[1] + "') > myself.CurrentMana:"
				actionstring += tab + "\treturn"
				actionstring += tab + "Combat.gainMana(-Effect.calculate('" + act[1] + "'), Card)"
			else:
				actionstring += tab + "Combat." + act[0] + "(Effect.calculate('" + act[1] + "'), Card)"
				if act[0] == "gainEnergy":
					actionstring += tab + "Combat.checkEnergy()"
			
			if whichstring == "turnString":
				turnString += actionstring
			elif whichstring == "triggerString":
				triggerString += actionstring
			elif whichstring == "endString":
				endString += actionstring
	
	var replaceable = true
	if "stackable" in effectProperties || "ally" in effectProperties || "replaceable" in effectProperties:
		replaceable = false
	if turnString == "":
		turnString = "\n\tpass"
	else:
		replaceable = false
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
	
	scriptString += initString + "\n\nfunc turnFunction():" + turnString + "\n\nfunc triggerFunction():" + triggerString + "\n\nfunc endFunction():" + endString
	var varString = "\nvar effectName = '" + effectName + "'"

	if actives > 0:
		effectProperties.append("active")
	var liststring = "\nvar effectProperties = ["
	for prop in effectProperties:
		liststring += "'" + prop + "',"
	liststring += "]"
	varString += liststring
	scriptString = varString + scriptString
	
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
	return functionstr
