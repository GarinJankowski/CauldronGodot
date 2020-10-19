extends "res://Character/Affected.gd"

var enemyName
var Tier
var room

var mutationList = {}
var positiveList = []
var negativeList = []
var singleList = {
	"Positive": positiveList,
	"Negative": negativeList
}

var inCombat = true
var mutated = false

var healthBar
var healthBarSizeX

var node
var stepy
var posDest

var scriptgen
var textlog
var guy
var itemgen
var map

func init(ename):
	.affectedInit()
	Game.setGlobals(self)
	
	room = get_parent().room
	
	var enemyFile = File.new()
	enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
	
	Deck = preload("res://Deck/Deck.tscn").instance()
	add_child(Deck)
	Deck.init(self)
	
	while not enemyFile.eof_reached():
		var line = str(enemyFile.get_line())
		if line.begins_with(ename):
			setValuesFromString(line)
			break
	enemyFile.close()
	
	Effects = preload("res://Effects/EffectList.tscn").instance()
	get_node("Control").add_child_below_node(get_node("Control/topnode"), Effects)
	Effects.init(self)
	
	selfCombat = load("res://Events/Combat/CombatFunctions.tscn").instance()
	add_child(selfCombat)
	selfCombat.init(self, self)
	
	healthBar = get_node("Control/Health")
	healthBarSizeX = healthBar.get_node("HealthIn").rect_size.x
	
	node = get_node("Control")
	stepy = 20
	posDest = Vector2(0, node.position.y + 160)
	
	updateUI()
	
func _process(delta):
	if node.position != posDest:
		node.position.y += stepy

func mutate():
	mutated = true
	var tiers = {
		"A": 1,
		"B": 2,
		"C": 3,
		"D": 4,
		"E": 5,
		"F": 6,
	}
	if Tier == "Final Boss":
		MaxHealth *= 10
		Strength *= 10
		Dexterity *= 10
		Intelligence *= 10
		MutationLevel = 100
	elif Tier.begins_with("Boss"):
		MaxHealth *= 10
		Strength *= 10
		Dexterity *= 10
		Intelligence *= 10
		MutationLevel = 100
	else:
		MaxHealth += MaxHealth/4
		Strength += Strength/4
		Dexterity += Dexterity/4
		Intelligence += Intelligence/4
		MutationLevel = tiers[Tier]*2
		
	CurrentHealth = MaxHealth
	
	var mutations = itemgen.EnemyMutations()
	addMutation(mutations[0])
	addMutation(mutations[1])
	
	updateMutScaling()
	updateUI()
	
func addMutation(mutationName):
	if mutationName in mutationList:
		mutationList[mutationName].multiplier += 1
		mutationList[mutationName].init(self)
	else:
		var positive = scriptgen.MutationScripts[mutationName][0]["positive"]
		var scriptObject = Reference.new()
		scriptObject.set_script(scriptgen.MutationScripts[mutationName][1])
		scriptObject.init(self)
		
		singleList[positive].append(scriptObject)
		mutationList[mutationName] = scriptObject

func pushMutationText():
	var postext = scriptgen.MutationScripts[positiveList[0].mutationName][0]["enemyLog"]
	var negtext = scriptgen.MutationScripts[negativeList[0].mutationName][0]["enemyLog"]
	
	var firstchar = postext.substr(0, 1)
	postext.erase(0, 1)
	
	var output = "[P]" + firstchar.to_upper() + postext + "[h] and " + negtext + "."
	textlog.push(output)

func startMutation(positive):
	for mut in singleList[positive]:
		mut.startFunction()
	#updateUI()
	
func triggerMutation(mutationName, Card = null, amount = 0):
	if hasMutation(mutationName):
		var Combat
		if Card != null:
			Combat = Card.Combat
		else:
			Combat = currentCombat
		mutationList[mutationName].triggerFunction(Combat, amount)
		return true
	return false
	
func valueMutation(mutationName, amount = 0):
	if hasMutation(mutationName):
		return mutationList[mutationName].valueFunction(amount)
	return 0

func hasMutation(mutationName):
	if mutationName in mutationList:
		return true
	return false

func updateUI():
	updateHealth()
	updateName()
	.updateUI()

func updateName():
	get_node("Control/Name/Namee").text = enemyName

func updateHealth():
	if CurrentHealth > MaxHealth + tempMaxHealth:
		CurrentHealth = MaxHealth + tempMaxHealth
	
	if MaxHealth + tempMaxHealth != 0:
		updateBar(healthBar.get_node("HealthIn"), healthBarSizeX*float(CurrentHealth)/float(MaxHealth + tempMaxHealth))
		#healthBar.get_node("HealthIn").rect_size.x = healthBarSizeX*float(CurrentHealth)/float(MaxHealth + tempMaxHealth)
	if CurrentHealth == 0:
		healthBar.get_node("HealthIn").visible = false
	else:
		healthBar.get_node("HealthIn").visible = true
		
	healthBar.get_node("Amount").text = str(CurrentHealth) + "/" + str(MaxHealth + tempMaxHealth)

func addStat(statstr, amount):
	if statstr == "Max Health":
		MaxHealth += amount
		CurrentHealth += amount
	elif statstr == "Max Mana":
		MaxMana += amount
		CurrentMana += amount
	elif statstr == "Max Energy":
		MaxEnergy += amount
	elif statstr == "Strength":
		Strength += amount
	elif statstr == "Dexterity":
		Dexterity += amount
	elif statstr == "Intelligence":
		Intelligence += amount
	elif statstr == "Mutation Level":
		MutationLevel += amount
		updateMutScaling()
	updateUI()
	return amount
	
func addTempStat(statstr, amount):
	if statstr == "Max Health":
		tempMaxHealth += amount
	elif statstr == "Max Mana":
		tempMaxMana += amount
	elif statstr == "Strength":
		tempStrength += amount
	elif statstr == "Dexterity":
		tempDexterity += amount
	elif statstr == "Intelligence":
		tempIntelligence += amount
	elif statstr == "Mutation Level":
		tempMutationLevel += amount
		updateMutScaling()
	return amount

func setValuesFromString(enemystring):
	var values = enemystring.replace("\"", "").split("\t")
	enemyName = values[0]
	Tier = values[1]
	
	MaxHealth = int(values[2])
	CurrentHealth = MaxHealth
	
	MaxMana = 10
	if "Boss" in Tier:
		CurrentMana = 10
	else:
		CurrentMana = 0
	
	MaxEnergy = 10
	CurrentEnergy = 0
	
	Strength = int(values[3])
	Dexterity = int(values[4])
	Intelligence = int(values[5])
	MutationLevel = int(values[6])
	
	var cardstring = values[7].split(", ")
	
	if enemyName == "Elemental":
		var elements = {
			"Forest": "Water",
			"Caves": "Earth",
			"Hills": "Air",
			"Desert": "Fire",
			"Field": "Blank",
			"Wasteland": "Blank",
			"City": "Blank"
		}
		var enemyFile = File.new()
		enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
		
		while not enemyFile.eof_reached():
			var line = str(enemyFile.get_line())
			
			if line.begins_with(elements[room.map.currentTerrain.terrain] + " Elemental"):
				cardstring = line.replace("\"", "").split("\t")[7].split(", ")
				break
		enemyFile.close()
	
	for i in range(cardstring.size()):
		if cardstring[i].begins_with("StartCard"):
			startCard = true
		elif "%" in cardstring[i]:
			var cardvals = cardstring[i].split(" (")
			cardvals.set(1, cardvals[1].replace("%)", ""))
			phaseCards.append(cardvals)
		else:
			var count = cardstring[i][len(cardstring[i])-2]
			for j in range(count):
				Deck.addCard(cardstring[i].substr(0, len(cardstring[i])-4))

func isPlayer():
	return false

func enemyDeath():
	get_parent().enemyDeath()
	queue_free()

func printValues():
	print_debug(enemyName)
	print_debug(Tier)
	
	print_debug(MaxHealth)
	
	print_debug(Strength)
	print_debug(Dexterity)
	print_debug(Intelligence)
	print_debug(MutationLevel)
	
	Deck.printDeck()
