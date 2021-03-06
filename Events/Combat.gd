extends "res://Events/Event.gd"

var turn
var firstDead = ""

var enemy

var guyCombat
var enemyCombat

var guyDeck
var enemyDeck

var waiting
#var timertime = 0.1
var timertime = 0.3

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
	if enemy.mutated:
		enemy.pushMutationText()
	
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
	guyCombat.setReverse(enemyCombat)
	
	guy.Effects.fixRetainedEffects()

	guy.startMutation("Positive")
	enemy.startMutation("Positive")
	if enemy.startCard:
		enemy.useGhostCard(enemy.enemyName + " Start", enemyCombat)
	guy.startMutation("Negative")
	enemy.startMutation("Negative")
	
	guy.Effects.turn("Good")
	guy.Effects.turn("Bad")
	
	guyDeck.drawCards()
	enemyDeck.drawCards()
	guyDeck.printHand()
	guyDeck.checkAllUsable()
	
	checkDeath()
	checkEndCombat()
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
			if !nextTurn():
				return
		elif (Input.is_action_just_pressed("number_2") || Input.is_action_just_pressed("ui_up")) && guyDeck.cardAt(1) && guyDeck.Hand[1].isUsable():
			guyDeck.updateDeck1()
			guyDeck.useCard(1)
			guyDeck.shuffleAddPrint()
			if !nextTurn():
				return
		elif (Input.is_action_just_pressed("number_3") || Input.is_action_just_pressed("ui_right")) && guyDeck.cardAt(2) && guyDeck.Hand[2].isUsable():
			guyDeck.updateDeck1()
			guyDeck.useCard(2)
			guyDeck.shuffleAddPrint()
			if !nextTurn():
				return
		elif Input.is_action_just_pressed("reshuffle") && !guyDeck.handUsable():
			guyDeck.updateDeck1()
			guyDeck.shuffleDeck(null)
			guyDeck.lastPlayed = guyDeck.reshuffleCard
			guyDeck.lastClicked = guyDeck.reshuffleCard
			guyDeck.shuffleAddPrint()
			if !nextTurn():
				return
		elif Input.is_action_just_pressed("flee") && guyDeck.fleeOn:
			fleeCombat()
		#if the enemy could put you to sleep or stun you this would be uncommented
#		elif guy.hasEffect("Sleep") || guy.hasEffect("Stun"):
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
		if !enemy.hasEffect("Sleep") && !enemy.hasEffect("Stun"):
			if ai > -1:
				enemyDeck.useCard(ai)
			else:
				enemyDeck.shuffleDeck()
				textlog.push("[B]The " + enemy.enemyName + " fails to take an action.")
		enemyDeck.shuffleAddPrint()
		if !nextTurn():
			return

#when the enemy dies:
#queue_free() the enemy and combat functions and decks
#restore the player's stats
func enemyDeath():
	#delete this when you're confident reservations work properly
	if !textlog.textQueue.empty() && textlog.textQueue[0].begins_with("RESERVED"):
		print(textlog.textQueue)
		
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
	guy.currentCombat = null
	
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

#checks for the first death of the combat
#if one of the combatants would die but has Reconstruction, it triggers the reconstruction and checks for the death again incase Reconstruction kills them
#if one of the combatants dies, the firstDead is set, which prepares to end combat/end the game after the next turn
func checkDeath():
	if firstDead == "":
		if !guy.isAlive():
			if !(guy.convertStat("MHP") > 0 && guy.triggerMutation("Reconstruction")):
				firstDead = "guy"
			else:
				checkDeath()
		elif !enemy.isAlive():
			if !(enemy.convertStat("MHP") > 0 && enemy.triggerMutation("Reconstruction")):
				firstDead = "enemy"
			else:
				checkDeath()
	
func checkEndCombat():
	var ended = false
	if firstDead != "":
		waiting = true
		ended = true
		if firstDead == "guy":
			enemy.triggerMutation("Gorger")
			guy.DEAD()
		elif firstDead == "enemy":
			enemy.enemyDeath()
	return ended

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
	# if the card just used was instant, this whole method will be skipped
	if turn == "guy" && guy.onInstantTurn:
		guy.onInstantTurn = false
		return
	elif turn == "enemy" && enemy.onInstantTurn:
		enemy.onInstantTurn = false
		return
			
	endTurnEffects()
	
	if checkEndCombat():
		return false
	
	if turn == "guy" and guy.Effects.hasTimedOut():
		waiting = true
		yield(get_tree().create_timer(timertime), "timeout")
		waiting = false
		guy.Effects.endTurn()
	elif turn == "enemy" and enemy.Effects.hasTimedOut():
		waiting = true
		yield(get_tree().create_timer(timertime), "timeout")
		waiting = false
		enemy.Effects.endTurn()
	
	if checkEndCombat():
		return false
		
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
	if checkEndCombat():
		return false
	
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
	#checkDeath()
	if checkEndCombat():
		return false
	
	#guyCombat.checkEnergy()
	if hasactive:
		yield(get_tree().create_timer(timertime), "timeout")
	affected.checkPhases()
	waiting = false
	
	return true

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
