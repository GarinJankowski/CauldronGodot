extends Node2D

var CombatDeck

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

var scriptObject

var cardSprite

var Combat
var myself
var opponent

var ghost = false
var inCombat = false
var DiscardCD = 0
var handIndex = -1

var mods = {
	"Burn": false,
	"Flow": false,
	"Stay": 0,
	"Link": 0,
	"Push": false,
	"Copy": false,
	"Void": false
}
var tempStay
var justStayed
var copyOriginal = null

var textlog

var dynamicFont
var ticks = 0
var destination = position
var stepdistance = Vector2(0, 0)
var distance
var speed = 30

var cardposx = 692
var cardposy = 460
var cardspacing = 180

var indexbefore = -1

var Game

func _on_Area2D_mouse_entered():
	visible = false

func init(cname):
	Game = get_parent().get_parent().Game
	cardSprite = get_node("Top/cardSprite")
	visible = false
	
	scriptObject = Reference.new()
	scriptObject.set_script(Game.scriptgen.CardScripts[cname])
	scriptObject.init(self)
	initVariables()
	
	dynamicFont = get_node("Top/nameText").get_font("font")
	if len(cardName) > 16:
		dynamicFont = DynamicFont.new()
		dynamicFont.font_data = load("res://TIMESS__.ttf")
		dynamicFont.size = 16
		get_node("Top/nameText").add_font_override("font", dynamicFont)
	elif len(cardName) > 11:
		dynamicFont = DynamicFont.new()
		dynamicFont.font_data = load("res://TIMESS__.ttf")
		dynamicFont.size = 20
		get_node("Top/nameText").add_font_override("font", dynamicFont)
		
	dynamicFont.use_filter = true
	dynamicFont.use_mipmaps = true
	
	makeSprite()
	
func ghostInit(cname, comb, combdeck):
	Game = get_parent().get_parent().Game
	ghost = true
	visible = false
	
	scriptObject = Reference.new()
	scriptObject.set_script(Game.scriptgen.CardScripts[cname])
	scriptObject.init(self)
	initVariables()
	
	inCombat = true
	Combat = comb
	CombatDeck = weakref(combdeck)
	myself = Combat.me
	opponent = Combat.enemy
	textlog = Combat.get_parent().Game.textlog
	scriptObject.initCombat()
	
func initCombat(comb, combdeck):
	inCombat = true
	CombatDeck = weakref(combdeck)
	indexbefore = -1
	handIndex = -1
	Combat = comb
	myself = Combat.me
	opponent = Combat.enemy
	textlog = Combat.get_parent().textlog
	tempStay = mods["Stay"]
	justStayed = false
	get_node("glow").visible = false
	if myself.isPlayer():
		get_node("buttonCard").disabled = false
		enableCollisions(true)
	
	scriptObject.initCombat()
	updateDescription()
	updateSprite()

func leaveCombat():
	inCombat = false
	CombatDeck = null
	tempStay = mods["Stay"]
	DiscardCD = 0
	handIndex = -1
	get_node("buttonCard").disabled = true
	get_node("glow").visible = false
	visible = false
	modulate = "ffffffff"
	get_node("Shadow").visible = true
	enableCollisions(false)
	updateSprite()

func initVariables():
	cardName = scriptObject.cardName
	cardType = scriptObject.cardType
	cardDescription = scriptObject.cardDescription
	costDescription = scriptObject.costDescription
	logOutput = scriptObject.logOutput
	cardActions = scriptObject.cardActions
	actionValues = scriptObject.actionValues
	cardProperties = scriptObject.cardProperties
	uniqueFlags = scriptObject.uniqueFlags
	uniqueValue = scriptObject.uniqueValue
	if copyOriginal == null:
		mods = scriptObject.mods

func _process(delta):
	if ticks > 0:
		position += stepdistance
		ticks -= 1

#I want to separate the checks for the "Copy" effect (or any other effect that does this)
#so, I made another function
func cardFunction():
	if myself.hasEffect("Copy") && !has("copied"):
		var copies = int(myself.getEffect("Copy"))
		myself.removeEffect("Copy")
		cardProperties.append("copied")
		for i in copies:
			cardFunction2()
		cardProperties.erase("copied")
	cardFunction2()

func cardFunction2():
	if myself.isAlive() && opponent.isAlive():
		for key in actionValues:
			actionValues[key] = 0
		#all this garbage is for using a card on yourself from being confused/deflected
		if myself.hasEffect("Confuse") || opponent.hasEffect("Deflect") && hasOffensiveAction():
			if !myself.hasEffect("Confuse"):
				opponent.trigger("Deflect")
				if opponent.hasEffect("Charm"):
					opponent.trigger("Charm")
			var tempCombat = Combat
			var tempOpponent = opponent
			Combat = myself.selfCombat
			opponent = myself
			scriptObject.Combat = myself.selfCombat
			scriptObject.opponent = myself
			scriptObject.useCard()
			if !ghost:
				checkCardTypeEffects()
			else:
				checkOtherEffects()
			Combat = tempCombat
			opponent = tempOpponent
			scriptObject.Combat = tempCombat
			scriptObject.opponent = tempOpponent
		#actual thing that usually happens
		else:
			scriptObject.useCard()
			if !ghost:
				checkCardTypeEffects()
			else:
				checkOtherEffects()
		Combat.checkEnergy()

func checkCardTypeEffects():
	if cardType == "Attack":
		myself.trigger("Transmute")
		myself.trigger("Attack Trap")
		myself.trigger("Salamander")
	if cardType == "Defend":
		if CombatDeck.get_ref():
			CombatDeck.get_ref().fleecounter += 1
		myself.trigger("Rat")
		myself.trigger("Defend Trap")
	elif CombatDeck.get_ref():
			CombatDeck.get_ref().fleecounter = 0
	if cardType == "Spell":
		myself.trigger("Spell Shield")
		myself.trigger("Crab")
		myself.trigger("Spell Trap")
	
	checkOtherEffects()
	CombatDeck.get_ref().lastPlayed = self

func checkOtherEffects():
	#effects that occur when you play an offensive card
	if hasOffensiveAction():
		myself.trigger("Sense")
		myself.trigger("Dodge")
		myself.trigger("Wound")
	
	#effects that occur when you deal damage through a card
	var damagedealtcounter = 0
	var counter = 0
	while counter < cardProperties.size():
		if cardProperties[counter] == "Damage Dealt":
			damagedealtcounter += 1
			cardProperties.remove(counter)
		else:
			counter += 1
	for i in damagedealtcounter:
		if myself.hasEffect("Attack Heal") && cardType == "Attack":
			Combat.gainHealth(int(actionValues["dealDirectDamage"]), self)
			myself.tickEffect("Attack Heal")
			myself.removeEffect("Attack Heal")
		
		opponent.trigger("Spikes")
		opponent.trigger("Sear")
		myself.trigger("Sneak")
		myself.trigger("Stealth")
		opponent.trigger("Sleep")

func addEffect(target, effectName, value, turns):
	var operators = "+-*/d"
	
	var valueStr = ""
	if typeof(value) == 2:
		valueStr = str(value)
	elif value != "N/A":
		if !" d " in value:
			valueStr = str(calculate(value))
		else:
			value = value.split(" ")
			for k in value.size():
				if !(value[k] in operators):
					value[k] = str(myself.convertStat(value[k]))
				valueStr += value[k] + " "
			valueStr = valueStr.substr(0, len(valueStr)-1)
	turns = calculate(str(turns))
	if turns != 0:
		target.addEffect(effectName, valueStr, turns, self)
	if turns == -1 && "stackable" in Game.scriptgen.EffectScripts[effectName][0]:
		return int(valueStr)
	return turns
		
func fill():
	if "fill" in cardActions:
		return cardActions["fill"]
	return null

func discard():
	if "discard" in cardActions:
		return int(cardActions["discard"])
	return 0

func has(property):
	for p in cardProperties:
		if p == property:
			return true
	return false

func hasOffensiveAction():
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
	if "action" in cardActions && cardActions["action"] == "pierce":
		return true
	return false

func hasAction(action):
	for a in cardActions:
		if a == action:
			return true
	return false
	
func hasActions(action, amount):
	var num = 0
	for a in cardActions:
		if a == action:
			num += 1
	if num >= amount:
		return true
	return false

func hasUniqueFlag(flag):
	for f in uniqueFlags:
		if f == flag:
			return true
	return false

func isUsable():
	var usable = scriptObject.isUsable()
	#for the Taunt effect, limits the player to only using Attacks if there are no available damage dealing cards
	if myself.hasEffect("Taunt") && cardType == "Attack" && !CombatDeck.get_ref().hasAction("dealDirectDamage"):
		usable = true
	if CombatDeck != null && CombatDeck.get_ref():
		if CombatDeck.get_ref().hasForceUsable() && !has('forceUsable'):
			usable = false
	if usable:
		modulate = "ffffffff"
		get_node("Shadow").visible = true
		if handIndex != -1:
			clickableOn(true)
		else:
			clickableOn(false)
	else:
		modulate = "6effffff"
		get_node("Shadow").visible = false
		clickableOn(false)
	return usable
	
func cardLogOutput():
	var output = ""
	var i = 0
	var start = 0
	
	var colors = {
		"gainEnergy": "[y]",
		"enemyGainEnergy": "[o]",
		"dealDirectDamage": "[b]",
		"enemydealDirectDamage": "[r]",
		"takeDirectDamage": "[r]",
		"dealIndirectDamage": "[b]",
		"takeIndirectDamage": "[r]",
		"enemytakeIndirectDamage": "[b]",
		"gainHealth": "[l]",
		"enemygainHealth": "[d]",
		"gainBlock": "[l]",
		"enemygainBlock": "[d]",
		"gainShield": "[l]",
		"enemygainShield": "[d]",
		"gainMana": "[i]",
		"n": "[n]",
		"Attack": "[b]",
		"Defend": "[l]",
		"Spell": "[i]",
		"Harmful": "[r]",
		"Item": "[n]",
		"Device": "[n]"
	}
	var wholecolor = "[n]"
	
	while i < len(logOutput):
		if logOutput[i] == "[":
			var length = 0
			if logOutput[i+2] == "]":
				if myself.isPlayer() || logOutput[i+1] == "n":
					output += "[" + logOutput[i+1] + "]"
					wholecolor = "[" + logOutput[i+1] + "]"
				else:
					output += "[r]"
					wholecolor = "[r]"
				length = 1
			elif (logOutput[i+1] == "y" && myself.isPlayer()) || (logOutput[i+1] == "e" && opponent.isPlayer()):
				output += colors[cardType]
				wholecolor = colors[cardType]
			else:
				if cardType == "Harmful":
					output += "[l]"
					wholecolor = "[l]"
				output += "[r]"
				wholecolor = "[r]"
			
			if logOutput[i+1] == "y" && logOutput[i+2] == "o":
				length = 3
			elif logOutput[i+1] == "e" && logOutput[i+2] == "n":
				length = 5
			else:
				length = 1
					
			i += length + 1
			start += length + 2
		elif logOutput[i] == "{":
			var word = ""
			var j = 1
			while logOutput[j+i] != "}":
				word += logOutput[j+i]
				j += 1
			var addword = ""
			if word.capitalize() == "You" || word.capitalize() == "Your" || word == "yourself":
				if myself.isPlayer():
					if i == start:
						addword = "You"
					else:
						addword = "you"
					if word.capitalize() == "Your":
						addword += "r"
					elif word == "yourself":
						addword += "rself"
				else:
					if i == start:
						addword = "The " + myself.enemyName
					else:
						addword = "the " + myself.enemyName
					if word.capitalize() == "Your":
						if "Boss" in myself.Tier:
							addword = "their"
						else:
							addword = "its"
					elif word == "yourself":
						if "Boss" in myself.Tier:
							addword = "themselves"
						else:
							addword = "itself"
			elif word == "enemyName" || word == "their":
				if opponent.isPlayer():
					if i == start:
						addword = "You"
					else:
						addword = "you"
					if word == "their":
						addword += "r"
				else:
					if i == start:
						addword = "The " + opponent.enemyName
					else:
						addword = "the " + opponent.enemyName
					if word == "their":
						addword += "'s"
			elif word == "are":
				if !myself.isPlayer():
					addword = "is"
				else:
					addword = "are"
			elif word == "have":
				if myself.isPlayer():
					output += "have"
				else:
					output += "has"
			elif word == "them":
				if opponent.isPlayer():
					output += "you"
				else:
					output += "them"
			elif word == "you_them":
				if myself.isPlayer():
					output += "you"
				else:
					output += "them"
			elif word == "s":
				if !myself.isPlayer():
					addword = "s"
			elif word == "es":
				if !myself.isPlayer():
					addword = "es"
			elif word == "y":
				if !myself.isPlayer():
					addword = "ies"
				else:
					addword = "y"
			else:
				var colorword = word
				if opponent.isPlayer():
					colorword = "enemy" + colorword
				if colorword in colors:
					addword += colors[colorword]
				addword += str(actionValues[word]) + wholecolor
			output += addword
			i += j
		else:
			output += logOutput[i]
		i += 1
	return output

func updateDescription():
	var desc = cardDescription
	var newdesc = ""
	
	var i = 0
	while i < len(desc):
		if desc[i] == "(" && desc[i+4] == ")":
			newdesc += "("
			var stat = desc.substr(i+1, 3)
			if stat == "Str":
				newdesc += str(myself.Strength + myself.tempStrength)
			elif stat == "Dex":
				newdesc += str(myself.Dexterity + myself.tempDexterity)
			elif stat == "Int":
				newdesc += str(myself.Intelligence + myself.tempIntelligence)
			elif stat == "VAL":
				newdesc += str(uniqueValue)
			newdesc += ")"
			i += 5
		else:
			newdesc += desc[i]
			i += 1
	if cardType == "Harmful":
		newdesc = newdesc.replace("(", "").replace(")", "")
	get_node("Top/descriptionText").text = newdesc

func changeToDevice():
	cardType = "Device"
	cardDescription = cardDescription.replace("Burn this", "Destroy this")
	cardSprite.set_texture(load("res://Card/CardSprites/card_Device.png"))
	get_node("Top/descriptionText").text = cardDescription
	cardProperties.append("itemTurnedDevice")

func glowOff():
	get_node("glow").visible = false
	get_node("Top/cardIcon").modulate = "19ffffff"
	get_node("Top/nameBack").modulate = "00000000"
	get_node("Top/costBack").modulate = "00000000"
	for key in mods:
		get_node("Top/modBack/" + key + "back").modulate = "00000000"

func applyMod(modstr):
	if modstr == "Stay" || modstr == "Link":
		incrementMod(modstr, "up")
	else:
		mods[modstr] = true
		
func removeMod(modstr):
	if modstr == "Stay" || modstr == "Link":
		mods[modstr] = 0
	else:
		mods[modstr] = false

func incrementMod(modstr, updown):
	if modstr == "Link" || modstr == "Stay":
		if updown == "up":
			if modstr == "Link" || modstr == "Stay":
				mods[modstr] += 1
		if updown == "down":
			mods[modstr] -= 1

func hasMod(modstr):
	if mods[modstr]:
		return true
	return false

func getPriority():
	var priority = 0
	
	if !isUsable():
		return -1
	
	if hasUniqueFlag("topPriority"):
		priority += 1000
	
	if hasAction("dealDirectDamage"):
		var maxdamage = Combat.calculateDirectDamage(calculateMax(cardActions["dealDirectDamage"]), myself, opponent, self)
		var mindamage = Combat.calculateDirectDamage(calculateMin(cardActions["dealDirectDamage"]), myself, opponent, self)
		
		if mindamage > 0:
			priority += 1
			if mindamage >= opponent.CurrentHealth + opponent.Block():
				priority += 500
			elif maxdamage >= opponent.CurrentHealth + opponent.Block():
				priority += 100 + maxdamage
			elif "block" in cardActions["dealDirectDamage"]:
				priority += 90
			
		elif opponent.Shield() > 0:
			priority += 10
			if hasActions("dealDirectDamage", 2):
				priority += 1
			
	if hasAction("UNIQUEFUNCTION"):
		priority += 100
	
	if has("stranglehold"):
		priority += 100
	
	if cardType == "Spell":
		if hasUniqueFlag("manaCost"):
			priority += 99
		elif hasAction("gainMana") && myself.CurrentMana < myself.MaxMana:
			priority += 90
		else:
			priority += 91
	
	if hasUniqueFlag("energyCost"):
		priority += 99
	
	if hasUniqueFlag("ramping"):
		priority += 80
	
	if hasUniqueFlag("setup"):
		priority += 75
	
	if hasAction("damageOT"):
		priority += 70
		
	if hasAction("stranglehold"):
		if myself.stranglehold() <= 0:
			priority += 100
		priority += 60
	
	if hasAction("insertEnemyDeck"):
		priority += 50

	if hasAction("gainHealth") && myself.MaxHealth - myself.CurrentHealth >= Combat.calculateHealth(calculateMin(cardActions["gainHealth"]), myself, opponent, self):
		priority += 45
	if hasAction("gainShield"):
		priority += 45
	if hasAction("gainBlock"):
		priority += 40
	if hasAction("action"):
		if cardActions["action"] == "pierce" && (opponent.Block() > 0 || opponent.Shield() > 0):
			priority += 30
	
	return priority

func changeIndex(index):
	indexbefore = handIndex
	handIndex = index

func moveTo(dest):
	if CombatDeck != null && CombatDeck.get_ref().isPlayer:
		destination = dest
		move()
	
func movePlus(dest):
	if CombatDeck != null && CombatDeck.get_ref().isPlayer:
		destination = position+dest
		move()

func move():
	distance = destination-position
		
	var truedistance = sqrt(pow(distance.x, 2) + pow(distance.y, 2))
	ticks = truedistance/speed
	stepdistance = distance/ticks
	
func clickableOn(truefalse):
	get_node("buttonCard").disabled = !truefalse
	
func makeSprite():
	var costSprite = get_node("Top/cardCost")
	cardSprite.set_texture(load("res://Card/CardSprites/card_" + cardType + ".png"))
		
	#get_node("Top/cardIcon").set_texture(load("res://Card/CardIcons/cardIcon_" + cardName + ".png"))
	
	if mods["Burn"]:
		get_node("Mods/mod_Burn").visible = true
	else:
		get_node("Mods/mod_Burn").visible = false
		
	if mods["Flow"]:
		get_node("Mods/mod_Flow").visible = true
	else:
		get_node("Mods/mod_Flow").visible = false
		
	if mods["Push"]:
		get_node("Mods/mod_Push").visible = true
	else:
		get_node("Mods/mod_Push").visible = false
		
	if mods["Copy"]:
		get_node("Mods/mod_Copy").visible = true
	else:
		get_node("Mods/mod_Copy").visible = false
		
	if mods["Stay"] > 0:
		get_node("Mods/mod_Stay").visible = true
		get_node("Mods/StayText").text = str(tempStay)
		get_node("Mods/StayText").visible = true
	else:
		get_node("Mods/mod_Stay").visible = false
		get_node("Mods/StayText").visible = false
		
	if mods["Link"] > 0:
		get_node("Mods/mod_Link").visible = true
		get_node("Mods/LinkText").text = str(mods["Link"])
		get_node("Mods/LinkText").visible = true
	else:
		get_node("Mods/mod_Link").visible = false
		get_node("Mods/LinkText").visible = false
		
	if mods["Void"]:
		get_node("Mods/mod_Void").visible = true
	else:
		get_node("Mods/mod_Void").visible = false
	
	get_node("Top/nameText").text = cardName
	get_node("Top/descriptionText").text = cardDescription
	
	var cost = get_node("Top/costText")
	
	if costDescription == "":
		cost.visible = false
		costSprite.visible = false
		get_node("Top/costBack").visible = false
	else:
		cost.text = costDescription

func updateMods():
	if mods["Burn"]:
		get_node("Mods/mod_Burn").visible = true
	else:
		get_node("Mods/mod_Burn").visible = false
		
	if mods["Flow"]:
		get_node("Mods/mod_Flow").visible = true
	else:
		get_node("Mods/mod_Flow").visible = false
		
	if mods["Push"]:
		get_node("Mods/mod_Push").visible = true
	else:
		get_node("Mods/mod_Push").visible = false
		
	if mods["Copy"]:
		get_node("Mods/mod_Copy").visible = true
	else:
		get_node("Mods/mod_Copy").visible = false
		
	if mods["Stay"] > 0:
		get_node("Mods/mod_Stay").visible = true
		get_node("Mods/StayText").text = str(tempStay)
		get_node("Mods/StayText").visible = true
	else:
		get_node("Mods/mod_Stay").visible = false
		get_node("Mods/StayText").visible = false
		
	if mods["Link"] > 0:
		get_node("Mods/mod_Link").visible = true
		get_node("Mods/LinkText").text = str(mods["Link"])
		get_node("Mods/LinkText").visible = true
	else:
		get_node("Mods/mod_Link").visible = false
		get_node("Mods/LinkText").visible = false
		
	if mods["Void"]:
		get_node("Mods/mod_Void").visible = true
	else:
		get_node("Mods/mod_Void").visible = false

func updateSprite():
	get_node("Mods/StayText").text = str(tempStay)

func printValues():
	print_debug(cardName + ", " + cardType + ", " + cardDescription)

func createCopy():
	var copy = load("res://Card/Card.tscn").instance()
	get_parent().add_child(copy)
	
	copy.copyOriginal = self
	for key in mods:
		copy.mods[key] = mods[key]
	copy.init(cardName)
	if has("itemTurnedDevice"):
		copy.changeToDevice()
	copy.initCombat(Combat, CombatDeck.get_ref())
	return copy

func getRecording():
	var valarray = [
		DiscardCD,
		handIndex,
		tempStay
	]
	return valarray
	
func applyRecording(recording):
	visible = true
	DiscardCD = recording[0]
	handIndex = recording[1]
	tempStay = recording[2]

func equals(card):
	if card == self || card == copyOriginal:
		return true
	return false
	
#calculates a number using postfix notation with the values in csv format
func calculate(string):
	var finalnum = 0
	var infix = string.split(" ")
	var postfix = []
	
	var second = false
	while !infix.empty():
		if second:
			postfix.append(infix[1])
			infix.remove(1)
			second = false
		else:
			postfix.append(infix[0])
			infix.remove(0)
			second = true
	
	var stack = []
	var operators = "+-*/d"
	
	for i in range(len(postfix)):
		if postfix[i] in operators:
			var a = myself.convertStat(stack.pop_back(), self)
			var b = myself.convertStat(stack.pop_back(), self)
			var op = postfix[i]
			if op == '+':
				stack.push_back(str(a + b))
			elif op == '-':
				stack.push_back(str(b - a))
			elif op == '*':
				stack.push_back(str(a * b))
			elif op == '/':
				stack.push_back(str(b / a))
			elif op == 'd':
				stack.push_back(str(rtd(b, a)))
		else:
			stack.push_back(postfix[i])
	finalnum = int(myself.convertStat(stack.pop_back(), self))
	return finalnum

func calculateMax(string):
	var finalnum = 0
	var infix = string.split(" ")
	var postfix = []
	
	var second = false
	while !infix.empty():
		if second:
			postfix.append(infix[1])
			infix.remove(1)
			second = false
		else:
			postfix.append(infix[0])
			infix.remove(0)
			second = true
	
	var stack = []
	var operators = "+-*/d"
	
	for i in range(len(postfix)):
		if postfix[i] in operators:
			var a = myself.convertStat(stack.pop_back(), self)
			var b = myself.convertStat(stack.pop_back(), self)
			var op = postfix[i]
			if op == '+':
				stack.push_back(str(a + b))
			elif op == '-':
				stack.push_back(str(b - a))
			elif op == '*':
				stack.push_back(str(a * b))
			elif op == '/':
				stack.push_back(str(b / a))
			elif op == 'd':
				stack.push_back(str(a * b))
		else:
			stack.push_back(postfix[i])
	finalnum = int(myself.convertStat(stack.pop_back(), self))
	return finalnum

func calculateMin(string):
	var finalnum = 0
	var infix = string.split(" ")
	var postfix = []
	
	var second = false
	while !infix.empty():
		if second:
			postfix.append(infix[1])
			infix.remove(1)
			second = false
		else:
			postfix.append(infix[0])
			infix.remove(0)
			second = true
	
	var stack = []
	var operators = "+-*/d"
	
	for i in range(len(postfix)):
		if postfix[i] in operators:
			var a = myself.convertStat(stack.pop_back(), self)
			var b = myself.convertStat(stack.pop_back(), self)
			var op = postfix[i]
			if op == '+':
				stack.push_back(str(a + b))
			elif op == '-':
				stack.push_back(str(b - a))
			elif op == '*':
				stack.push_back(str(a * b))
			elif op == '/':
				stack.push_back(str(b / a))
			elif op == 'd':
				stack.push_back(str(b))
		else:
			stack.push_back(postfix[i])
	finalnum = int(myself.convertStat(stack.pop_back(), self))
	return finalnum

#roll the dice
func rtd(amount, sides):
	if sides == 0:
		return 0
	var value = 0
	for i in range(int(amount)):
		value += (randi()%int(sides))+1
	return value

func disableButton():
	get_node("buttonCard").visible = false
	
func enableButton():
	get_node("buttonCard").visible = true

func enableCollisions(truefalse):
	get_node("cardArea/cardCollision").disabled = !truefalse
