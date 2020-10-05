extends "res://Events/Event.gd"

var turn

var enemy

var guyCombat
var enemyCombat

var guyDeck
var enemyDeck

var waiting
var timertime = 0.1

func init2(r):
	init(r)
	guy.Bag.buttondesty = guy.Bag.buttondesty-110
	guy.Bag.buttonstepy = -22
	
	waiting = false
	
	enemy = preload("res://Enemy/Enemy.tscn").instance()
	add_child(enemy)
	enemy.init(r.enemyName)
	
	if map.currentTerrainEquals("Wasteland"):
		enemy.mutate()
	
	var a = "a"
	if r.enemyName[0] in "AEIOU":
		a = "an"
	textlog.push("[r]You encounter " + a + " " + r.enemyName + ".")
	pushMutationText()
	
	guy.currentCombatEvent = self
	enemy.currentCombatEvent = self
	
	guyCombat = load("res://Events/Combat/CombatFunctions.tscn").instance()
	add_child(guyCombat);
	guyCombat.init(guy, enemy)
	guy.inCombat = true
	guy.currentCombat = guyCombat
	guy.statsRestored = false
	
	enemyCombat = load("res://Events/Combat/CombatFunctions.tscn").instance()
	add_child(enemyCombat);
	enemyCombat.init(enemy, guy)
	enemy.currentCombat = enemyCombat
	
	guyDeck = load("res://Deck/CombatDeck.tscn").instance()
	add_child(guyDeck)
	guyDeck.isPlayer = true
	guyDeck.initCombat(guy.Deck, guyCombat)
	guy.currentCombatDeck = guyDeck
	
	enemyDeck = load("res://Deck/CombatDeck.tscn").instance()
	add_child(enemyDeck)
	enemyDeck.initCombat(enemy.Deck, enemyCombat)
	enemy.currentCombatDeck = enemyDeck
	
	guyDeck.enemyCombatDeck = enemyDeck
	enemyDeck.enemyCombatDeck = guyDeck
	
	guyCombat.setCombatEvent(self)
	guy.selfCombat.setCombatEvent(self)
	enemyCombat.setCombatEvent(self)
	enemy.selfCombat.setCombatEvent(self)
	
	if map.currentTerrainEquals("Desert"):
		guy.Effects.fixRetainedEffects()

	guy.startMutation("Positive")
	enemy.startMutation("Positive")
	if enemy.startCard:
		enemy.useGhostCard(enemy.enemyName + "Start", enemyCombat)
	guy.startMutation("Negative")
	enemy.startMutation("Negative")
	
	guy.Effects.turn("Good")
	guy.Effects.turn("Bad")
		
	guyDeck.printHand()
	guyDeck.checkAllUsable()
	
	checkDeath()
	turn = "guy"
	
func _process(delta):
	if !waiting:
		turn()

func timer():
	waiting = true
	yield(get_tree().create_timer(timertime), "timeout")
	waiting = false

func turn():
	if checkTurn("guy") && !guy.inMenu && !close:
		if (Input.is_action_just_pressed("number_1") || Input.is_action_just_pressed("ui_left")) && guyDeck.cardAt(0) && guyDeck.Hand[0].isUsable():
			guyDeck.updateDeck1()
			guyDeck.useCard(0)
			guyDeck.shuffleAddPrint()
			if nextTurn():
				return
		elif (Input.is_action_just_pressed("number_2") || Input.is_action_just_pressed("ui_up")) && guyDeck.cardAt(1) && guyDeck.Hand[1].isUsable():
			guyDeck.updateDeck1()
			guyDeck.useCard(1)
			guyDeck.shuffleAddPrint()
			if nextTurn():
				return
		elif (Input.is_action_just_pressed("number_3") || Input.is_action_just_pressed("ui_right")) && guyDeck.cardAt(2) && guyDeck.Hand[2].isUsable():
			guyDeck.updateDeck1()
			guyDeck.useCard(2)
			guyDeck.shuffleAddPrint()
			if nextTurn():
				return
		elif Input.is_action_just_pressed("reshuffle") && !guyDeck.handUsable():
			guyDeck.updateDeck1()
			guyDeck.shuffleDeck(null)
			guyDeck.lastPlayed = guyDeck.reshuffleCard
			guyDeck.lastClicked = guyDeck.reshuffleCard
			guyDeck.shuffleAddPrint()
			if nextTurn():
				return
		elif Input.is_action_just_pressed("flee") && guyDeck.fleeOn:
			fleeCombat()
		#if the enemy could put you to sleep this would be uncommented
#		elif guy.hasEffect("Sleep"):
#			guyDeck.updateDeck1()
#			guyDeck.shuffleAddPrint()
#			if nextTurn():
#				return
	#lets the AI play for you
#	if checkTurn("guy") && !guy.inMenu && !close:
#		guyDeck.updateDeck1()
#		var ai = guyDeck.enemyAI()
#		if ai > -1 && !guy.hasEffect("Sleep"):
#			guyDeck.useCard(ai)
#		guyDeck.shuffleAddPrint()
#		if nextTurn():
#			return
	elif checkTurn("enemy") && !close:
		enemyDeck.updateDeck1()
		var ai = enemyDeck.enemyAI()
		if !enemy.hasEffect("Sleep"):
			if ai > -1:
				enemyDeck.useCard(ai)
			else:
				enemyDeck.shuffleDeck()
				textlog.push("[B]The " + enemy.enemyName + " fails to take an action.")
		enemyDeck.shuffleAddPrint()
		if nextTurn():
			return

#when the enemy dies:
#queue_free() the enemy and combat functions and decks
#restore the player's stats
func enemyDeath():
	textlog.push("The " + enemy.enemyName + " dies.")
	guy.triggerMutation("Gorger")
	textlog.push("[g]You gain " + str(room.experience) + " experience.")
	var lvls = guy.gainExperience(room.experience)
	for i in lvls:
		textlog.push("[g]Your level has increased.")
		room.events.insert(1, "LevelUp")
	guy.Effects.removeEffects("Good")
	guy.Effects.removeEffects("Bad", "counterpart")
	
	guy.Bag.buttonstepy *= -1
	guy.Bag.buttondesty = guy.Bag.buttonstarty
	
	enemy.queue_free()
	guy.clearGhostCards()
	guyCombat.queue_free()
	enemyCombat.queue_free()
	guyDeck.removeDeck()
	enemyDeck.removeDeck()
	guy.inCombat = false
	
	guy.restoreVariables()
	
	room.events.append("Stat")
	if !map.currentTerrainEquals("Desert"):
		guy.restoreStats()
	else:
		room.events.append("Stat")
	
	if enemy.Tier.begins_with("Boss"):
		room.events.append("Item")
		room.events.append("getGear")
		if room.scrollName != null:
			room.events.append("Scroll")
		if room.cardName != null:
			room.events.append("getCard")
	
	end()

func fleeCombat():
	textlog.push("[l]You flee from the fight.")
	guy.Effects.removeEffects("Good")
	guy.Effects.removeEffects("Bad", "counterpart")
	
	guy.Bag.buttonstepy *= -1
	guy.Bag.buttondesty = guy.Bag.buttonstarty
	
	enemy.queue_free()
	guy.clearGhostCards()
	guyCombat.queue_free()
	enemyCombat.queue_free()
	guyDeck.removeDeck()
	enemyDeck.removeDeck()
	guy.inCombat = false
	
	guy.restoreVariables()
	if !map.currentTerrainEquals("Desert"):
		guy.restoreStats()
	
	end()

func checkDeath():
	if !guy.isAlive():
		if !(guy.convertStat("MHP") > 5 && guy.triggerMutation("Reconstruction")):
			waiting = true
			enemy.triggerMutation("Gorger")
			guy.DEAD()
			return true
	elif !enemy.isAlive():
		if !(enemy.convertStat("MHP") > 5 && enemy.triggerMutation("Reconstruction")):
			waiting = true
			enemy.enemyDeath()
			return true
	return false

#check whos turn
func checkTurn(who):
	var isTurn = true
	isTurn = who == turn
	if !guy.isAlive():
		isTurn = false
	return isTurn

#effects that happen at the end of someone's turn
func endTurnEffects():
	var me = guy
	var opponent = enemy
	if turn == "enemy":
		me = enemy
		opponent = guy
	
	for i in me.currentCombatDeck.countCard("Ring of Mending"):
		me.currentCombat.gainHealth(3, null)
	for i in me.currentCombatDeck.countCard("Quick Bracelet"):
		me.currentCombat.gainEnergy(3, null)
	for i in me.currentCombatDeck.countCard("Runed Amulet"):
		me.currentCombat.gainMana(3, null)
	
	#me.currentCombat.checkEnergy()
		

#set the turn to someone
func nextTurn():
	if checkDeath():
		return true
		
	endTurnEffects()
		
	waiting = true
	yield(get_tree().create_timer(timertime), "timeout")
	waiting = false
	
	if turn == "guy":
		enemy.onExtraTurn = false
		if guy.ExtraTurns() > 0:
			guy.addExtraTurns(-1)
			guy.onExtraTurn = true
		else:
			guy.onExtraTurn = false
			turn = "enemy"
	elif turn == "enemy":
		guy.onExtraTurn = false
		if enemy.ExtraTurns() > 0:
			enemy.addExtraTurns(-1)
			enemy.onExtraTurn = true
		else:
			enemy.onExtraTurn = false
			turn = "guy"
			
	waiting = true
	var affected
	var affectedCombat
	if turn == "guy":
		affected = guy
		affectedCombat = guyCombat
	elif turn == "enemy":
		affected = enemy
		affectedCombat = enemyCombat
	
	#guyCombat.checkEnergy()
	var hasactive = false
	if affected.hasActive("Good"):
		hasactive = true
	affected.Effects.turn("Good")
	var sensitive = affected.valueMutation("Sensitive")
	for i in sensitive:
		affected.Effects.turn("Good")
	guyDeck.updateDeck1()
	guyDeck.updateDeck2()
	guyDeck.printHand()
	if checkDeath():
		return true
	#guyCombat.checkEnergy()
	if hasactive:
		yield(get_tree().create_timer(timertime), "timeout")
	
	hasactive = false
	if affected.hasActive("Bad"):
		hasactive = true
	affected.Effects.turn("Bad")
	for i in sensitive:
		affected.Effects.turn("Bad")
	guyDeck.printHand()
	if checkDeath():
		return true
	#guyCombat.checkEnergy()
	if hasactive:
		yield(get_tree().create_timer(timertime), "timeout")
	affected.checkPhases()
	waiting = false
	
	return false

func pushMutationText():
	if !enemy.positiveList.empty() && !enemy.negativeList.empty():
		var posmut = enemy.positiveList[0].mutationName
		var negmut = enemy.negativeList[0].mutationName
		textlog.push("[r]It seems to have [P]" + posmut + " [r]and [h]" + negmut + "[r]")

func getRecording():
	return [guy.getRecording(), enemy.getRecording()]
	
func applyRecording(recording):
	guy.applyRecording(recording[0])
	enemy.applyRecording(recording[1])

func disableButtons():
	for card in guyDeck.Hand:
		if card != null:
			card.disableButton()
	for card in guyDeck.Draw:
		card.disableButton()
	for card in guyDeck.Discard:
		card.disableButton()
		
func enableButtons():
	for card in guyDeck.Hand:
		if card != null:
			card.enableButton()
	for card in guyDeck.Draw:
		card.enableButton()
	for card in guyDeck.Discard:
		card.enableButton()
