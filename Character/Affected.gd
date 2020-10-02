extends Node

var MaxHealth
var CurrentHealth

var MaxEnergy
var CurrentEnergy

var MaxMana
var CurrentMana

var Strength
var Dexterity
var Intelligence
var MutationLevel

var tempMaxHealth = 0
var tempMaxMana = 0

var tempStrength = 0
var tempDexterity = 0
var tempIntelligence = 0
var tempMutationLevel = 0

var mutationScaling = {
	"Max Health": 0.0,
	"Max Mana": 0.0,
	"Max Energy": 0.0,
	"Strength": 0.0,
	"Dexterity": 0.0,
	"Intelligence": 0.0,
}
var mutationStats = {
	"Max Health": 0,
	"Max Mana": 0,
	"Max Energy": 0,
	"Strength": 0,
	"Dexterity": 0,
	"Intelligence": 0,
}

var onExtraTurn = false

#these are only used for enemies for now
var startCard = false
var phaseCards = []

var currentCombatEvent
var currentCombat
var currentCombatDeck
var Effects
#selfCombat currently exists solely for the purposes of Confusion and Deflect
var selfCombat

var Deck
var ghostCards = []

var Game

func affectedInit():
	Game = get_parent().Game

func updateUI():
	pass

func trigger(effectName):
	return Effects.trigger(effectName)
	
func hasActive(goodbad):
	return Effects.hasActive(goodbad)

func addEffect(effectName, value, turns, Card):
	Effects.addEffect(effectName, value, turns, Card)
	
func increaseEffect(effectName, value):
	Effects.increaseEffect(effectName, value)

func tickEffect(effectName):
	Effects.tick(effectName)
	
func tickAllies():
	Effects.tickAllies()

func hasEffect(effectName):
	return Effects.has(effectName)

func getEffect(effectName):
	return int(Effects.getValue(effectName))
	
func countEffectInstances(effectName):
	var amount = 0
	if Effects.has(effectName):
		amount = Effects.effectList[effectName].size()
	return amount
	
func removeEffect(effectName):
	Effects.removeEffect(effectName)

func checkPhases():
	for cardinfo in phaseCards:
		var percent = int(cardinfo[1])
		if 100*CurrentHealth/(MaxHealth+tempMaxHealth) <= percent:
			useGhostCard(cardinfo[0], currentCombat)
			phaseCards.erase(cardinfo)

func Block():
	return Effects.getValue("Block")
func addBlock(value, Card, turns = 1):
	addEffect("Block", value, turns, Card)
	
func Shield():
	return Effects.getValue("Shield")
func addShield(value, Card, turns = 1):
	addEffect("Shield", value, turns, Card)

func Allies():
	return Effects.hasAlly()
	
func Distance():
	return getEffect("Distance") + currentCombat.enemy.getEffect("Distance")

func hasDefenses():
	if Block() > 0 || Shield() > 0 || Allies():
		tickEffect("Block")
		tickEffect("Shield")
		tickAllies()
		return true
	return false
	
func ExtraTurns():
	return Effects.getValue("Extra Turns")
func addExtraTurns(value, Card = null):
	addEffect("Extra Turns", value, -1, Card)
	
func stranglehold():
	return Effects.getValue("Stranglehold (Attacker)")
func addStranglehold(value, Card = null):
	if hasEffect("Stranglehold (Attacker)"):
		var val = -getEffect("Stranglehold (Attacker)")
		if value < val:
			value = val
		Effects.getEffect("Stranglehold (Attacker)").add(value)
		if getEffect("Stranglehold (Attacker)") <= 0:
			Effects.getEffect("Stranglehold (Attacker)").Combat.enemy.trigger("Stranglehold (Target)")

#attached is to check if this ghost card was used because of another card with a special case, like Hack or Pierce
#if attached is false, this means the ghost card was used by other means, like from effects like Stranglehold
func useGhostCard(cardName, Combat, times = 0):
	if !getGhostCard(cardName, Combat):
		addGhostCard(cardName, Combat)
	
	var card = getGhostCard(cardName, Combat)
	if times > 0:
		card.cardProperties.append("isAlternate")
		card.cardFunction(times)
		card.cardProperties.erase("isAlternate")
	else:
		card.cardFunction()
	currentCombatDeck.checkOtherActions(card)
	return card

func getGhostCard(cardName, Combat):
	for ghost in ghostCards:
		if ghost[0] == cardName && ghost[1] == Combat:
			return ghost[2]
	return false
	
func addGhostCard(cardName, Combat):
	var card = load("res://Card/Card.tscn").instance()
	add_child(card)
	card.ghostInit(cardName, Combat, currentCombatDeck)
	ghostCards.append([cardName, Combat, card])

func clearGhostCards():
	for ghost in ghostCards:
		ghost[2].queue_free()
	ghostCards.clear()

func addMutScaling(stat, amount):
	mutationScaling[stat] += amount
	updateMutScaling()

func updateMutScaling():
	for key in mutationScaling:
		mutationStats[key] = int(mutationScaling[key]*(MutationLevel + tempMutationLevel))
	
func getRecording():
	var topstats = [MaxHealth, CurrentHealth, MaxEnergy, CurrentEnergy, MaxMana, CurrentMana]
	var bottomstats = [Strength, Dexterity, Intelligence, MutationLevel]
	var tempstats = [tempMaxHealth, tempMaxMana, tempStrength, tempDexterity, tempIntelligence, tempMutationLevel]
	var recording = {
		"Stats": [topstats, bottomstats, tempstats],
		"Effects": Effects.getRecording(),
		"Combat Deck": currentCombatDeck.getRecording()
	}
	return recording
	
func applyRecording(recording):
	var topstats = recording["Stats"][0]
	var bottomstats = recording["Stats"][1]
	var tempstats = recording["Stats"][2]
	
	MaxHealth = topstats[0]
	CurrentHealth = topstats[1]
	MaxEnergy = topstats[2]
	CurrentEnergy = topstats[3]
	MaxMana = topstats[4]
	CurrentMana = topstats[5]
	
	Strength = bottomstats[0]
	Dexterity = bottomstats[1]
	Intelligence = bottomstats[2]
	MutationLevel = bottomstats[3]
	
	tempMaxHealth = tempstats[0]
	tempMaxMana = tempstats[1]
	tempStrength = tempstats[2]
	tempDexterity = tempstats[3]
	tempIntelligence = tempstats[4]
	tempMutationLevel = tempstats[5]
	
	Effects.applyRecording(recording["Effects"])
	currentCombatDeck.applyRecording(recording["Combat Deck"])
	updateUI()
	
func updateBar(bar, newwidth):
	var currentwidth = bar.rect_size.x
	if newwidth > currentwidth:
		bar.rect_size.x = currentwidth + (newwidth-currentwidth)/5
		yield(get_tree().create_timer(.01), "timeout")
		bar.rect_size.x = currentwidth + (newwidth-currentwidth)*2/5
		yield(get_tree().create_timer(.01), "timeout")
		bar.rect_size.x = currentwidth + (newwidth-currentwidth)*3/5
		yield(get_tree().create_timer(.01), "timeout")
		bar.rect_size.x = currentwidth + (newwidth-currentwidth)*4/5
		yield(get_tree().create_timer(.01), "timeout")
	elif newwidth < currentwidth && bar.name != "ExperienceIn":
		var i = 1
		if newwidth <= currentwidth/4:
			i = 2
		if newwidth <= currentwidth/2:
			i = 3
		bar.rect_position += Vector2(-1, 3)*i
		yield(get_tree().create_timer(.03), "timeout")
		bar.rect_position += Vector2(2, -4)*i
		yield(get_tree().create_timer(.04), "timeout")
		bar.rect_position += Vector2(-1, 1)*i
	bar.rect_size.x = newwidth
	
#takes a string and returns the corresponding stat of "myself"
#otherwise, return the string converted to a float
func convertStat(string, Card = null, Effect = null):
	var num
	if string == "UNIQUEVALUE":
		num = Card.uniqueValue
	elif Card != null && string in Card.actionValues:
		num = Card.actionValues[string]
	elif string == "Str":
		num = Strength + tempStrength + mutationStats["Strength"]
	elif string == "Dex":
		num = Dexterity + tempDexterity + mutationStats["Dexterity"]
	elif string == "Int":
		num = Intelligence + tempIntelligence + mutationStats["Intelligence"]
	elif string == "Mut":
		num = MutationLevel + tempMutationLevel
	elif string == "MHP":
		num = MaxHealth + tempMaxHealth + mutationStats["Max Health"]
	elif string == "MMP":
		num = MaxMana + tempMaxMana + mutationStats["Max Mana"]
	elif string == "block":
		num = Block()
	elif string == "Val" && Effect != null:
		num = Effect.calculate(str(Effect.value))
	elif string.begins_with("effect("):
		num = getEffect(string.replace("effect(", "").replace(")", "").replace("_", " "))
	elif string.begins_with("missingHealth"):
		num = MaxHealth + tempMaxHealth + mutationStats["Max Health"] - CurrentHealth
	else:
		num = float(string)
		
	return float(num)
	
#you really gotta put these all in one place (there's one in Effect and THREE in Card)
func calculate(string):
	var finalnum = 0
	var negative = false
	if string.begins_with("-"):
		string.erase(0, 1)
		negative = true
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
			var a = convertStat(stack.pop_back(), self)
			var b = convertStat(stack.pop_back(), self)
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
				stack.push_back(str(Game.rtd(b, a)))
		else:
			stack.push_back(postfix[i])
	finalnum = int(convertStat(stack.pop_back()))
	if negative:
		finalnum *= -1
	return finalnum
