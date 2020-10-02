extends "res://Character/Affected.gd"

var enemyName
var Tier
var room

var positiveMutationList = []
var negativeMutationList = []

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
	if Tier == "Final Boss":
		MaxHealth *= 10
		Strength *= 10
		Dexterity *= 10
		Intelligence *= 10
		MutationLevel = 100
	elif Tier == "Boss":
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
		MutationLevel = int(Tier)*2
		
	CurrentHealth = MaxHealth
	
	var positiveMutationGeneration = []
	var negativeMutationGeneration = []
	
	var posmutfile = File.new()
	posmutfile.open("res://Body/Positive Mutation Sheet.txt", posmutfile.READ)
	while not posmutfile.eof_reached():
		var values = str(posmutfile.get_line()).replace("\"", "").split("\t")
		if values[2] == "enemyMutation":
			positiveMutationGeneration.append(values[0])
	posmutfile.close()
	
	var negmutfile = File.new()
	negmutfile.open("res://Body/Negative Mutation Sheet.txt", negmutfile.READ)
	while not negmutfile.eof_reached():
		var values = str(negmutfile.get_line()).replace("\"", "").split("\t")
		if values[2] == "enemyMutation":
			negativeMutationGeneration.append(values[0])
	negmutfile.close()
	
	positiveMutationList.append(positiveMutationGeneration[randi()%positiveMutationGeneration.size()])
	negativeMutationList.append(negativeMutationGeneration[randi()%negativeMutationGeneration.size()])
	
	updateMutScaling()
	updateUI()

func getMutation(mutationName):
	for mut in positiveMutationList:
		if mut == mutationName:
			return 1
	for mut in negativeMutationList:
		if mut == mutationName:
			return 1
	return 0

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

func isAlive():
	return CurrentHealth > 0
	
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
