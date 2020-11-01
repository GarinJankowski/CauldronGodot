extends "res://Character/Affected.gd"

var posx = 0
var posy = 0
var previousX = posx
var previousY = posy

var Bag
var Body

var gear = {
		"Weapon": null,
		"Armor": null,
		"Headgear": null
	}
var noWeapon
var noArmor
var noHeadgear

var CurrentExperience
var MaxExperience
var Gold

var inCombat
var statsRestored

var xpBar
var xpBarSizeX
var healthBar
var healthBarSizeX
var manaBar
var manaBarSizeX
var blockAmount
var negateAmount
var energyBar
var energyBarRight
var energyBarRightSizeX
var energyBarLeft
var energyBarLeftSizeX

var strBar
var dexBar
var intBar
var mutBar

var inMenu = false
var nodePosStart
var nodePosDest
var step = Vector2(0, 0)
var stepy = 19

var map
var textlog
var scriptgen

func init():
	.affectedInit()
	
	textlog = Game.textlog
	map = Game.map
	scriptgen = Game.scriptgen
	
	MaxHealth = 10
	CurrentHealth = MaxHealth
	
	MaxEnergy = 10
	CurrentEnergy = 0
	
	MaxMana = 10
	CurrentMana = MaxMana
	
	Strength = 3
	Dexterity = 3
	Intelligence = 3
	MutationLevel = 0
	
	CurrentExperience = 0
	MaxExperience = 10
	Gold = 0
	
	inCombat = false
	statsRestored = true
	
	xpBar = get_node("Control/Experience")
	xpBarSizeX = xpBar.get_node("ExperienceIn").rect_size.x
	healthBar = get_node("Control/Health")
	healthBarSizeX = healthBar.get_node("HealthIn").rect_size.x
	manaBar = get_node("Control/Mana")
	manaBarSizeX = manaBar.get_node("ManaIn").rect_size.x
	blockAmount = get_node("Control/Block/Amount")
	negateAmount = get_node("Control/Negate/Amount")
	energyBar = get_node("Control/Energy")
	energyBarRight = get_node("Control/Energy/EnergyInRight")
	energyBarRightSizeX = energyBarRight.rect_size.x
	energyBarLeft = get_node("Control/Energy/EnergyInLeft")
	energyBarLeftSizeX = energyBarLeft.rect_size.x
	
	strBar = get_node("Control/Strength")
	dexBar = get_node("Control/Dexterity")
	intBar = get_node("Control/Intelligence")
	mutBar = get_node("Control/Mutation Level")
	
	updateUI()
	
	nodePosStart = get_node("Control").position
	nodePosDest = nodePosStart
	step = 19
	
	Deck = preload("res://Deck/Deck.tscn").instance()
	add_child(Deck)
	Deck.init(self)
	
	Bag = preload("res://Bag/Bag.tscn").instance()
	add_child(Bag)
	Bag.init()
	
	Body = preload("res://Body/Body.tscn").instance()
	add_child(Body)
	Body.init()
	
	Effects = preload("res://Effects/EffectList.tscn").instance()
	get_node("Control").add_child_below_node(get_node("Control/topnode"), Effects)
	Effects.init(self)
	
	selfCombat = load("res://Events/Combat/CombatFunctions.tscn").instance()
	add_child(selfCombat)
	selfCombat.init(self, self)
	
	#Bag.addGear("Dev Sword")
	#Bag.addGear("Impenetrable Mail")
	#Bag.addGear("")
	#Bag.addCard("")
	#Bag.addMod("", 0)
	#Body.addMutation("")
	#addStat("", 0)


func gainExperience(value):
	CurrentExperience += value
	var lvlup = 0
	while CurrentExperience >= MaxExperience:
		CurrentExperience -= MaxExperience
		MaxExperience += 10
		lvlup += 1
	updateExperience()
	return lvlup


func getMutation(mutationName):
	return Body.getMutation(mutationName)


func updateUI():
	updateExperience()
	updateHealth()
	updateMana()
	updateEnergy()
	updateMaxEnergy()
	updateStats()


func updateStats():
	var text = "[center]"
	if tempStrength > 0:
		text += "[g]"
	elif tempStrength < 0:
		text += "[r]"
	else:
		text += "[w]"
	text += str(Strength + tempStrength + mutationStats["Strength"])
	strBar.get_node("Amount").bbcode_text = textlog.translate(text)
	
	text = "[center]"
	if tempDexterity > 0:
		text += "[g]"
	elif tempDexterity < 0:
		text += "[r]"
	else:
		text += "[w]"
	text += str(Dexterity + tempDexterity + mutationStats["Dexterity"])
	dexBar.get_node("Amount").bbcode_text = textlog.translate(text)
	
	text = "[center]"
	if tempIntelligence > 0:
		text += "[g]"
	elif tempIntelligence < 0:
		text += "[r]"
	else:
		text += "[w]"
	text += str(Intelligence + tempIntelligence + mutationStats["Intelligence"])
	intBar.get_node("Amount").bbcode_text = textlog.translate(text)
	
	text = "[center]"
	if tempMutationLevel > 0:
		text += "[g]"
	elif tempMutationLevel < 0:
		text += "[r]"
	else:
		text += "[w]"
	text += str(MutationLevel + tempMutationLevel)
	mutBar.get_node("Amount").bbcode_text = textlog.translate(text)
	
	if inCombat:
		currentCombatDeck.updateDescriptions()


func updateExperience():
	#xpBar.get_node("ExperienceIn").rect_size.x = xpBarSizeX*float(CurrentExperience)/float(MaxExperience)
	updateBar(xpBar.get_node("ExperienceIn"), xpBarSizeX*float(CurrentExperience)/float(MaxExperience))
	if CurrentExperience == 0:
		xpBar.get_node("ExperienceIn").visible = false
	else:
		xpBar.get_node("ExperienceIn").visible = true
		
	xpBar.get_node("Amount").text = str(CurrentExperience) + "/" + str(MaxExperience)


func updateHealth():
	if CurrentHealth > MaxHealth + tempMaxHealth + mutationStats["Max Health"]:
		CurrentHealth = MaxHealth + tempMaxHealth + mutationStats["Max Health"]

	if MaxHealth + tempMaxHealth + mutationStats["Max Health"] != 0:
		updateBar(healthBar.get_node("HealthIn"), healthBarSizeX*float(CurrentHealth)/float(MaxHealth + tempMaxHealth + mutationStats["Max Health"]))
		#healthBar.get_node("HealthIn").rect_size.x = healthBarSizeX*float(CurrentHealth)/float(MaxHealth + tempMaxHealth)
	if CurrentHealth == 0:
		healthBar.get_node("HealthIn").visible = false
	else:
		healthBar.get_node("HealthIn").visible = true
		
	healthBar.get_node("Amount").text = str(CurrentHealth) + "/" + str(MaxHealth + tempMaxHealth + mutationStats["Max Health"])


func updateMana():
	if CurrentMana > MaxMana + tempMaxMana + mutationStats["Max Mana"]:
		CurrentMana = MaxMana + tempMaxMana + mutationStats["Max Mana"]
	
	if MaxMana + tempMaxMana + mutationStats["Max Mana"]!= 0:
		updateBar(manaBar.get_node("ManaIn"), manaBarSizeX*float(CurrentMana)/float(MaxMana + tempMaxMana + mutationStats["Max Mana"]))
		#manaBar.get_node("ManaIn").rect_size.x = manaBarSizeX*float(CurrentMana)/float(MaxMana + tempMaxMana)
	if CurrentMana == 0:
		manaBar.get_node("ManaIn").visible = false
	else:
		manaBar.get_node("ManaIn").visible = true
		
	manaBar.get_node("Amount").text = str(CurrentMana) + "/" + str(MaxMana + tempMaxMana + mutationStats["Max Mana"])


func updateEnergy():
	if CurrentEnergy > 0:
		energyBarRight.visible = true
		updateBarEnergy(energyBarRight, energyBarRightSizeX*float(CurrentEnergy)/float(10))
		#energyBarRight.rect_size.x = energyBarRightSizeX*float(CurrentEnergy)/float(10)
		energyBarLeft.visible = false
	elif CurrentEnergy < 0:
		energyBarLeft.visible = true
		#energyBarLeft.rect_size.x = energyBarLeftSizeX*float(-CurrentEnergy)/float(10)
		updateBarEnergy(energyBarLeft, energyBarLeftSizeX*float(-CurrentEnergy)/float(10))
		energyBarRight.visible = false
	else:
		energyBarRight.visible = false
		energyBarLeft.visible = false
	
	if CurrentEnergy < 0:
		energyBar.get_node("Amount").text = str(-CurrentEnergy) + "/" + str(20-MaxEnergy)
	else:
		energyBar.get_node("Amount").text = str(CurrentEnergy) + "/" + str(MaxEnergy)
	#updateMaxEnergy()


func updateBarEnergy(bar, newwidth):
	var currentwidth = bar.rect_size.x
	bar.rect_size.x = currentwidth + (newwidth-currentwidth)/4
	yield(get_tree().create_timer(.01), "timeout")
	bar.rect_size.x = currentwidth + (newwidth-currentwidth)/2
	yield(get_tree().create_timer(.01), "timeout")
	bar.rect_size.x = currentwidth + (newwidth-currentwidth)*3/4
	yield(get_tree().create_timer(.01), "timeout")
	bar.rect_size.x = newwidth


func updateMaxEnergy():
	var bar = get_node("Control/Energy/EnergyFront")
	bar.patch_margin_left = 122
	bar.patch_margin_right = 122
	var right = get_node("Control/Energy/EnergyInRight")
	right.rect_position.x = -1306
	if MaxEnergy > 10:
		bar.patch_margin_left += (MaxEnergy-10)*58
		right.rect_position.x -= (MaxEnergy-10)*8
	elif MaxEnergy < 10:
		bar.patch_margin_right += (10-MaxEnergy)*58
		right.rect_position.x += (10-MaxEnergy)*8
	
	get_node("Control/Energy/EnergyInLeft").rect_position.x = right.rect_position.x


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
	if !inCombat && !isAlive():
		DEAD()
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
	updateUI()
	if !inCombat && !isAlive():
		DEAD()
	return amount


func gainGold(amount):
	Gold += amount
	Bag.updateGold()
	get_node("Control/Gold/Amount").text = str(Gold)


func restoreVariables():
	onExtraTurn = false


func restoreStats():
	Effects.fixRetainedEffects()
	Effects.removeEffects("Bad")
	
	tempMaxHealth = 0
	tempStrength = 0
	tempDexterity = 0
	tempIntelligence = 0
	tempMutationLevel = 0
	updateMutScaling()
	
	CurrentHealth = convertStat("MHP")
	CurrentMana = convertStat("MMP")
	CurrentEnergy = 0
	
	statsRestored = true
	updateUI()


func startMutation(positive):
	Body.start(positive)
	#updateUI()


func triggerMutation(mutationName, Card = null, amount = 0):
	return Body.trigger(mutationName, Card, amount)


func valueMutation(mutationName, amount = 0):
	return Body.value(mutationName, amount)


func hasMutation(mutationName):
	return Body.has(mutationName)


func isPlayer():
	return true

func checkDeath():
	if !isAlive():
		DEAD()

func DEAD():
		updateStats()
		updateUI()
		textlog.push("[r]You die.")
		var DEAD = preload("res://DEAD.tscn").instance();
		add_child(DEAD)
