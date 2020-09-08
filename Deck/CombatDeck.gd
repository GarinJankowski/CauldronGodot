extends "res://Deck/Deck.gd"

var Deck

var me
var enemy
var handSize = 3

var Hand = []
var Draw = []
var Discard = []

var pastHand1 = []
var pastHand2 = []

var lastPlayed
var lastClicked

var Combat
var enemyCombatDeck

var isPlayer = false
var reshuffleOn = false
var fleecounter = 0
var fleeOn = false
var listOfCopies = []

var draw
var discard
var reshuffle
var flee
var reshuffleCard

var textlog

var cardposx = 692
var cardposy = 460
var cardspacing = 180

var reshuffleDesty
var reshuffleStepy
var fleeDesty
var fleeStepy

func initCombat(outsideDeck, combatFunctions):
	Deck = outsideDeck
	textlog = get_parent().textlog
	draw = get_node("Draw")
	discard = get_node("Discard")
	reshuffle = get_node("Reshuffle")
	flee = get_node("Flee")
	
	reshuffleCard = load("res://Card/Card.tscn").instance()
	add_child(reshuffleCard)
	reshuffleCard.visible = false
	reshuffleCard.init("Reshuffle")
	
	reshuffleDesty = reshuffle.position.y
	reshuffleStepy = 0
	fleeDesty = flee.position.y
	fleeStepy = 0
	
	for i in 3:
		pastHand1.append(null)
		pastHand2.append(null)
		Hand.append(null)
	
	Combat = combatFunctions
	me = Combat.me
	enemy = Combat.enemy
	init(outsideDeck.holder)
	for i in range(Deck.size()):
		#Void modifier
		if !Deck.at(i).mods["Void"]:
			Deck.at(i).initCombat(Combat, self)
			Deck.at(i).position = draw.position
			Draw.append(Deck.at(i))
			#Copy modifier
			if Deck.at(i).mods["Copy"]:
				var copy = Deck.at(i).createCopy()
				copy.position = draw.position
				listOfCopies.append(copy)
				Draw.append(copy)
	Draw.shuffle()
	shuffleAddPrint()
	
func _process(delta):
	if reshuffle.position.y != reshuffleDesty:
		reshuffle.position.y += reshuffleStepy
		if reshuffle.position.y == 757:
			reshuffle.visible = false
	if flee.position.y != fleeDesty:
		flee.position.y += fleeStepy
		if flee.position.y == 757:
			flee.visible = false
		
func useCard(index):
	var card = Hand[index]
	lastClicked = card
	card.glowOff()
	
	if card.hasOffensiveAction():
		me.trigger("Trick (Target)")
		
	card.cardFunction()
	
	checkProperties(index)
	
	
	restoreJustStayed()
	card.updateSprite()

func forceUseCard(cardName):
	lastPlayed = me.useGhostCard(cardName, me.currentCombat)

func shuffleAddPrint():
	updateDeck2()
	checkDiscard()
	drawCards()
	printHand()
	clickableOn()

func updateDeck1():
#	if handUsable():
#		reshuffleOn(false)
#	else:
#		reshuffleOn(true)
			
	for i in pastHand1.size():
		pastHand1[i] = Hand[i]

func updateDeck2():
	for i in pastHand2.size():
		pastHand2[i] = Hand[i]

func useRandomAttack():
	updateDeck1()
	var attacklist = []
	for i in Hand.size():
		if Hand[i] != null && Hand[i].cardType == "Attack" && Hand[i].isUsable():
			attacklist.append(i)
	if attacklist.size() > 0:
		useCard(attacklist[randi()%attacklist.size()])
		shuffleAddPrint()

func checkDiscard():
	var i = 0
	while i < len(Discard):
		if Discard[i].DiscardCD == 0:
			Discard[i].moveTo(draw.position)
			discardToDraw(i)
		else:
			Discard[i].DiscardCD -= 1
			i += 1

func addTempCard(cardName, uniqueval = 0):
	var card = load("res://Card/Card.tscn").instance()
	add_child(card)
	card.init(cardName)
	card.uniqueValue = uniqueval
	card.initCombat(Combat, self)
	card.position = draw.position
	card.updateDescription()
	Draw.insert(randi()%(Draw.size()+1), card)

func drawCards():
		for i in len(Hand):
			draw(i)
	
func printHand():
	for i in range(len(Hand)):
		if Hand[i] != null:
			if isPlayer:
				if enemy.isAlive():
					Hand[i].visible = true
				else:
					Hand[i].visible = false
				if pastHand1[i] != Hand[i] || pastHand2[i] != Hand[i]:
					Hand[i].moveTo(Vector2(cardposx-((handSize-i-1)*cardspacing), cardposy))
				Hand[i].isUsable()
					
	if isPlayer:
		if len(Draw) == 0:
			draw.visible = false
		else:
			draw.visible = true
			
		if len(Discard) == 0:
			discard.visible = false
		else:
			discard.visible = true
			
		if handUsable():
			reshuffleOn(false)
		else:
			reshuffleOn(true)
			
		if fleecounter >= 3:
			fleeOn(true)
		else:
			fleeOn(false)
			
	handUsable()

func checkProperties(index):
	var card = Hand[index]
	if !cardAt(index):
		card = lastClicked
	var cardnull = false
	
	#destroy the card if it is a Device
	if card.cardType == "Device":
		if card.copyOriginal != null:
			Deck.destroy(card.copyOriginal)
		else:
			Deck.destroy(card)
		Hand[index].visible = false
		Hand[index] = null
		cardnull = true
	
	#burn the entire hand
	if card.has("burnHand"):
		for i in Hand.size():
			if Hand[i] != null && !checkStay(Hand[i]):
				burn(i)
				if i == index:
					cardnull = true
	
	#burn/Burn modifier
	if card.has("burn") || card.mods["Burn"] || card.cardType == "Item" || card.has("ignite") || me.hasEffect("Forget"):
		me.trigger("Forget")
		card.cardProperties.erase("ignite")
		#Stay modifier
		if !cardnull && !checkStay(card):
			burn(index)
			cardnull = true

	#Push modifier
	if card.mods["Push"]:
		for i in len(Hand):
			if cardAt(i):
				#Stay modifier
				if !checkStay(Hand[i]):
					if i == index:
						cardnull = true
					discard(i, 3)
	#discard card
	elif !cardnull && card.discard() > 0:
		#Stay modifier
		if !checkStay(card):
			discard(index, card.discard())
			cardnull = true
			
	if !cardnull:
		handToDraw(index)
		cardnull = true
	
	#Flow modifier
	for i in len(Hand):
		if cardAt(i) && Hand[i].mods["Flow"]:
			#Stay modifier
			if !checkStay(Hand[i]):
				discard(i, 1)
	
	#Link modifier
	if cardnull && card.mods["Link"] > 0:
		var linked = false
		for i in len(Draw):
			if Draw[i].mods["Link"] == card.mods["Link"]+1:
				drawFrom(i, index)
				linked = true
				break
		if !linked:
			for i in len(Discard):
				if Discard[i].mods["Link"] == card.mods["Link"]+1:
					var card2 = Discard[i]
					Discard.remove(i)
					Hand[index] = card2
					card2.indexbefore = -1
					card2.handIndex = index
					card2.rotation_degrees = rand_range(-1.5, 1.5)
					linked = true
					break
		if !linked:
			for i in len(Hand):
				if cardAt(i) && Hand[i].mods["Link"] == card.mods["Link"]+1:
					handToHand(i, index)
					break
					
	checkOtherActions(card)
		
func checkOtherActions(card):
	#shuffle deck
	if card.has("shuffle"):
		shuffleDeck(card)
	
	#fill hand
	if card.fill() != null:
		fillHand(card.fill(), card)

func checkStay(card):
	#Stay modifier
	if card.tempStay > 0 || card.justStayed:
		if !card.justStayed:
			card.tempStay -= 1
			card.justStayed = true
			card.updateSprite()
		return true
	return false

func restoreJustStayed():
	for card in Hand:
		if card != null:
			card.justStayed = false
	for card in Draw:
		card.justStayed = false

func shuffleDraw(cardused = null):
	for i in len(Hand):
		if cardAt(i) && (cardused == null || Hand[i] != cardused || !cardused.justStayed):
			handToDraw(i)
	Draw.shuffle()
	drawCards()
	printHand()
	clickableOn()
	
func shuffleDeck(cardused = null):
	for i in len(Hand):
		if cardAt(i) && (cardused == null || Hand[i] != cardused || !cardused.justStayed):
			handToDraw(i)
	while len(Discard) > 0:
		Discard[0].DiscardCD = 0
		discardToDraw(0)
	updateDeck2()
	Draw.shuffle()
	drawCards()
	printHand()

func fillHand(cardType, cardused = null):
	var drawlist = []
	var discardlist = []
	var emptyIndices = []
	#loop that sees which indices in hand need to be filled, adds them to a list
	for i in Hand.size():
		if Hand[i] == null:
			emptyIndices.append(i)
		elif Hand[i].cardType != cardType && Hand[i].cardName != cardType:
			emptyIndices.append(i)
	#as long as you don't have enough cards to fill the indices, search through the draw and discard piles for cards
	for card in Draw:
		if drawlist.size() >= emptyIndices.size():
			break
		if card.cardType == cardType || card.cardName == cardType:
			drawlist.append(card)
	for card in Discard:
		if drawlist.size() + discardlist.size() > emptyIndices.size():
			break
		if card.cardType == cardType || card.cardName == cardType:
			discardlist.append(card)
	#takes all the empty indices and puts cards from drawlist and discardlist in them
	while drawlist.size() > 0 && emptyIndices.size() > 0:
		var i = emptyIndices.pop_back()
		if cardAt(i):
			handToDraw(i)
		drawFrom(Draw.find(drawlist.pop_back()), i)
	while discardlist.size() > 0 && emptyIndices.size() > 0:
		var i = emptyIndices.pop_back()
		if cardAt(i):
			handToDraw(i)
		var dcard = discardlist.pop_back()
		discardToDraw(Discard.find(dcard))
		drawFrom(Draw.find(dcard), i)

#burn any card in your hand with the same name as the argument
func burnDeck(cardName):
	for i in Hand.size():
		if cardAt(i) && Hand[i].cardName == cardName:
			burn(i)
	var i = 0
	while Draw.size() > i:
		if Draw[i].cardName == cardName:
			burnOutside(Draw, i)
		else:
			i += 1
	i = 0
	while Discard.size() > i:
		if Discard[i].cardName == cardName:
			burnOutside(Discard, i)
		else:
			i += 1
	drawCards()

func handFull():
	for i in len(Hand):
		if Hand[i] == null:
			return i
	return -1

func discard(index, turns):
	if !cardAt(index):
		return
	var card = Hand[index]
	Hand[index] = null
	card.changeIndex(-1)
	card.moveTo(discard.position)
	card.DiscardCD += turns
	Discard.append(card)

func draw(index):
	if !cardAt(index) && Draw.size() > 0:
		var card = Draw[Draw.size()-1]
		Draw.remove(Draw.size()-1)
		Hand[index] = card
		card.changeIndex(index)
		card.rotation_degrees = rand_range(-1.5, 1.5)

func drawFrom(start, dest):
	if !cardAt(dest) && start < Draw.size():
		var card = Draw[start]
		Draw.remove(start)
		Hand[dest] = card
		card.changeIndex(dest)
		card.rotation_degrees = rand_range(-1.5, 1.5)

func handToDraw(index):
	if cardAt(index):
		Hand[index].moveTo(draw.position)
		Hand[index].rotation_degrees = rand_range(-1.5, 1.5)
		Hand[index].changeIndex(-1)
		Draw.insert(randi()%(Draw.size()+1), Hand[index])
		Hand[index] = null

func discardToDraw(index):
	Discard[index].moveTo(draw.position)
	Discard[index].rotation_degrees = rand_range(-1.5, 1.5)
	
	var place = randi()%(Draw.size()+1)
	Discard[index].changeIndex(place)
	Draw.insert(place, Discard[index])
	Discard.remove(index)

func handToHand(start, dest):
	if cardAt(start) && !cardAt(dest):
		Hand[start].changeIndex(dest)
		Hand[dest] = Hand[start]
		Hand[start] = null

func burn(index):
	if cardAt(index):
		Hand[index].visible = false
		Hand[index] = null
	
func burnOutside(pile, index):
	pile.remove(index)
	
func forceBurn(Card):
	if !checkStay(Card):
		Card.visible = false
		for i in Hand.size():
			if cardAt(i) && Hand[i] == Card:
				Hand[i] = null
				return
		Draw.erase(Card)
		Discard.erase(Card)

func handUsable():
	var usable = false
	for i in range(len(Hand)):
		if cardAt(i) && Hand[i].isUsable():
			usable = true
	return usable

func hasForceUsable():
	for card in Hand:
		if card != null && card.has("forceUsable") && card.scriptObject.isUsable():
			return true
	return false
	
func hasOffensiveAction():
	for card in Hand:
		if card != null && card.hasOffensiveAction() && card.scriptObject.isUsable():
			return true
	return false

func hasAction(action):
	for card in Hand:
		if card != null && card.hasAction(action) && card.scriptObject.isUsable():
			return true
	return false
	
#returns the amount of cards in hand that have the same name as the parameter
func countCard(cardName):
	var amount = 0
	for card in Hand:
		if card != null && card.cardName == cardName:
			amount += 1
	return amount

func cardAt(index):
	if Hand[index] == null:
		return false
	return true

func clickableOn():
	for card in Discard:
		card.clickableOn(false)
	for card in Draw:
		card.clickableOn(false)
	for i in len(Hand):
		if cardAt(i):
			Hand[i].clickableOn(true)

func reshuffleOn(truefalse):
	if !(truefalse && reshuffleOn):
		reshuffleOn = truefalse
		if truefalse:
			reshuffle.visible = true
		get_node("Reshuffle/shuffleButton").visible = truefalse
		get_node("Reshuffle/shuffleCardArea/cardCollision").disabled = !truefalse
		if truefalse:
			reshuffleDesty = 457
			reshuffleStepy = -30
		else:
			reshuffleDesty = 757
			reshuffleStepy = 30
		reshuffle.rotation_degrees = rand_range(-1.5, 1.5)

func fleeOn(truefalse):
	if !(truefalse && fleeOn):
		fleeOn = truefalse
		if truefalse:
			flee.visible = true
		get_node("Flee/fleeButton").visible = truefalse
		get_node("Flee/fleeCardArea/cardCollision").disabled = !truefalse
		if truefalse:
			fleeDesty = 457
			fleeStepy = -30
		else:
			fleeDesty = 757
			fleeStepy = 30
		flee.rotation_degrees = rand_range(-1.5, 1.5)

func enemyAI():
	var priorityList = []
	for i in Hand.size():
		if cardAt(i):
			var p = Hand[i].getPriority()
			if p != -1:
				priorityList.append(Vector2(i, p))
	if priorityList.empty():
		return -1
	elif priorityList.size() == 1:
		return priorityList[0].x
	
	var highestIndex = []
	highestIndex.append(priorityList.pop_front())
	
	while !priorityList.empty():
		var currentP = priorityList.pop_front()
		if currentP.y > highestIndex[0].y:
			highestIndex.clear()
			highestIndex.append(currentP)
		elif currentP.y == highestIndex[0].y:
			highestIndex.append(currentP)
			
	return highestIndex[randi()%highestIndex.size()].x
	
func removeDeck():
	while listOfCopies.size() > 0:
		listOfCopies.pop_back().queue_free()
	Deck.leaveCombat()
	queue_free()

func updateDescriptions():
	for card in Hand:
		if card != null:
			card.updateDescription()
	for card in Draw:
		card.updateDescription()
	for card in Discard:
		card.updateDescription()

func getRecording():
	var handcopy = []
	for card in Hand:
		if card == null:
			handcopy.append(null)
		else:
			handcopy.append([card, card.getRecording()])
			
	var drawcopy = []
	for card in Draw:
		drawcopy.append([card, card.getRecording()])
		
	var discardcopy = []
	for card in Discard:
		discardcopy.append([card, card.getRecording()])
	
	return [handcopy, drawcopy, discardcopy]

func applyRecording(recording):
	for card in Hand:
		if card != null:
			card.visible = false
	for card in Draw:
		card.visible = false
	for card in Discard:
		card.visible = false
	
	var handcopy = recording[0]
	var drawcopy = recording[1]
	var discardcopy = recording[2]
	
	for i in handcopy.size():
		if handcopy[i] == null:
			Hand[i] = null
		else:
			Hand[i] = handcopy[i][0]
			Hand[i].applyRecording(handcopy[i][1])
			
	Draw.clear()
	for record in drawcopy:
		Draw.append(record[0])
		record[0].applyRecording(record[1])
		
	Discard.clear()
	for record in discardcopy:
		Discard.append(record[0])
		record[0].applyRecording(record[1])
	
	for i in range(len(Hand)):
		if Hand[i] != null:
			if isPlayer:
				if enemy.isAlive():
					Hand[i].visible = true
				else:
					Hand[i].visible = false
				Hand[i].moveTo(Vector2(cardposx-((handSize-i-1)*cardspacing), cardposy))
				Hand[i].isUsable()
	
	for card in Draw:
		card.moveTo(draw.position)
		
	for card in Discard:
		card.moveTo(discard.position)
				
	if isPlayer:
		if len(Draw) == 0:
			draw.visible = false
		else:
			draw.visible = true
			
		if len(Discard) == 0:
			discard.visible = false
		else:
			discard.visible = true
			
		if handUsable():
			reshuffleOn(false)
		else:
			reshuffleOn(true)

func print_debugDeck():
	var deckstr = "HAND:"
	for i in range(len(Hand)):
		deckstr +=  " " + Hand[i].cardName + str(Hand[i])
	deckstr += "\nDRAW:"
	for i in range(len(Draw)):
		deckstr +=  " " + Draw[i].cardName + str(Draw[i])
	deckstr += "\nDISCARD:"
	for i in range(len(Discard)):
		deckstr +=  " " + Discard[i].cardName + str(Discard[i])
	print_debug(deckstr)

func print_debugPriorities():
	var pr = "| "
	for card in Hand:
		if card == null:
			pr += "null: null | "
		else:
			pr += card.cardName + ": " + str(card.getPriority()) + " | "
	print_debug(pr)

func print_debugHand():
	var deckstr = ""
#	for i in range(len(Hand)):
#		if Hand[i] == null:
#			deckstr += " ? |"
#		else:
#			deckstr +=  " " + Hand[i].cardName + " " + str(Hand[i].indexbefore) + " " + str(Hand[i].handIndex) + " " + str(i) + " |"
	for i in Hand.size():
		if Hand[i] == null:
			deckstr += " ? |"
		else:
			deckstr += " " + Hand[i].cardName + str(Hand[i]) + " |"
	deckstr += "\n"
#	for i in pastHand1.size():
#		if pastHand1[i] == null:
#			deckstr += " ? |"
#		else:
#			deckstr += " " + pastHand1[i].cardName + str(pastHand1[i]) + " |"
	print_debug(deckstr)
	
func _on_shuffleButton_pressed():
	Input.action_press("reshuffle")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("reshuffle")

func _on_shuffleCardArea_area_entered(area):
	get_node("Reshuffle/glow").visible = true
	get_node("Reshuffle/Top/nameBack").visible = true

func _on_shuffleCardArea_area_exited(area):
	get_node("Reshuffle/glow").visible = false
	get_node("Reshuffle/Top/nameBack").visible = false

func _on_fleeCardArea_area_entered(area):
	get_node("Flee/glow").visible = true
	get_node("Flee/Top/nameBack").visible = true

func _on_fleeCardArea_area_exited(area):
	get_node("Flee/glow").visible = false
	get_node("Flee/Top/nameBack").visible = false

func _on_fleeButton_pressed():
	Input.action_press("flee")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("flee")
