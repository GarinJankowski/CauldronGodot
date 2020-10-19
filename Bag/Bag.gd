extends Node2D

var guy
var map
var textlog

var ticks = 8

var gearPreload = preload("res://Gear/Gear.tscn")
var maxsize = 6
var noWeapon
var noArmor
var noHeadgear
var bagGearEquipped = {
	"Weapon": noWeapon,
	"Armor": noArmor,
	"Headgear": noHeadgear
}
var bagGearPreload = preload("res://Bag/bagGear.tscn")
var bagScrollPreload = preload("res://Bag/bagScroll.tscn")
var bagGearList = []
var open = false

var bagCardList = {
	"Device": null,
	"Attack": null,
	"Defend": null,
	"Spell": null,
	"Positive": null,
	"Negative": null,
	"Item": null,
	"Harmful": null
}
var bagCardListSize
var bagCardPreload = preload("res://Bag/bagCard.tscn")
var selectedBagCard
var cursorPosition = Vector2(0, 0)

var bagCardDisplay

var guynode
var backnode
var modnode
var decknode
var bagnode

var botstep = Vector2(0, 0)
var botstepy = 53
var sidestep = Vector2(0, 0)
var sidestepx = 47.5
var backstep = Vector2(0, 0)
var backstepy = 150

var modposStart
var modposDest

var deckposStart
var deckposDest

var bagposStart
var bagposDest

var backposStart
var backposDest

var mainButton

var bagButton
var bodyButton
var buttonstepy
var buttonstarty
var buttondesty

var runesHover = false
var canScroll = false
var bagCardsOnScreen = 13.0
var deckScrollValue = bagCardsOnScreen
var bagCardHeight = 37.0
var scrollButtonStepx = 0
var scrollButtonStartx
var scrollButtonTicks = 0
var bagButtonTicks = 0
var bodyButtonTicks = 0
var mainButtonScale = 0.002

var modList = {
	"Burn": 0,
	"Flow": 0,
	"Push": 0,
	"Copy": 0,
	"Stay": 0,
	"Link": 0,
	"Void": 0
}

var Game

func init():
	Game = get_parent().Game
	guy = Game.guy
	map = Game.map
	textlog = Game.textlog
	
	bagCardDisplay = load("res://Bag/bagCardDisplay.tscn").instance()
	get_node("bag/bagCardDisplay").add_child(bagCardDisplay)
	bagCardDisplay.init()
	
	initNoGear()
	updateGold()
	
	_enable_mod_areas(false)
	enableAreaCollisions(false)
	updateModButtons()
	
	nodeSetup()

func nodeSetup():
	guynode = guy.get_node("Control")
	
	backnode = get_node("back")
	backposStart = backnode.position
	backposDest = backposStart
	
	modnode = get_node("mods")
	modposStart = modnode.position
	modposDest = modposStart
	
	decknode = get_node("deck")
	deckposStart = decknode.position
	deckposDest = deckposStart
	
	bagnode = get_node("bag")
	bagposStart = bagnode.position
	bagposDest = bagposStart
	
	backnode.visible = false
	modnode.visible = false
	decknode.visible = false
	bagnode.visible = false
	
	mainButton = get_node("bagButtonMain/buttonBag")
	
	bagButton = get_node("bagButtonMain")
	bodyButton = get_node("bodyButtonMain")
	buttonstarty = bagButton.position.y
	buttondesty = buttonstarty
	buttonstepy = 0
	
	scrollButtonStartx = get_node("deck/pageDownButton").position.x

func moveNodes():
	if bagButton.position.y != buttondesty:
		bagButton.position.y += buttonstepy
		bodyButton.position.y += buttonstepy
	if guynode.position != guy.nodePosDest:
		guynode.position += guy.step
		if guynode.position == guy.nodePosStart:
			guynode.z_index = 2
	if backnode.position != backposDest:
		backnode.position += backstep
		if backnode.position == backposStart:
			backnode.visible = false
	if modnode.position != modposDest:
		modnode.position += botstep
		if modnode.position == modposStart:
			modnode.visible = false
	if decknode.position != deckposDest:
		decknode.position += sidestep
		if decknode.position == deckposStart:
			decknode.visible = false
	if bagnode.position != bagposDest:
		bagnode.position -= sidestep
		if bagnode.position == bagposStart:
			bagnode.visible = false
	if bagButtonTicks > 0:
		get_node("bagButtonMain/button_Bag").scale -= Vector2(mainButtonScale, mainButtonScale)
		bagButtonTicks -= 1
	if bodyButtonTicks > 0:
		get_node("bodyButtonMain/button_Body").scale -= Vector2(mainButtonScale, mainButtonScale)
		bodyButtonTicks -= 1
			
	if scrollButtonTicks > 0:
		scrollButtonTicks -= 1
		get_node("deck/pageUpButton").position.x += scrollButtonStepx
		get_node("deck/pageDownButton").position.x += scrollButtonStepx
		if scrollButtonTicks == 0:
			if !canScroll:
				get_node("deck/pageUpButton").visible = false
				get_node("deck/pageDownButton").visible = false
				get_node("deck/pageUpButton").position.x = scrollButtonStartx
				get_node("deck/pageDownButton").position.x = scrollButtonStartx

func _process(delta):
	if !open && Input.is_action_just_pressed("bag"):
		if guy.Body.open:
			guy.Body.close()
		open()
		if guy.inMenu:
			mainButton.disabled = true
			get_parent().Body.mainButton.disabled = true
	elif open && (Input.is_action_just_pressed("bag") || Input.is_action_just_pressed("ui_cancel")):
		close()
		if !guy.inMenu:
			mainButton.disabled = false
			get_parent().Body.mainButton.disabled = false
	for key in modList:
		if get_node("mods/forgeButtonsBag/" + key + "/mod").scale > Vector2(1, 1):
			get_node("mods/forgeButtonsBag/" + key + "/mod").scale -= Vector2(0.1, 0.1)
	
	moveNodes()

func _input(event):
	if open && canScroll && event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			deckScrollUp(-1, 4)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			deckScrollUp(1, 4)
	if open && !guy.inCombat && runesHover && Input.is_action_just_released("RMB"):
		removeAllMods()
		

func open():
	z_index = 29
	guynode.z_index = 30
	open = true
	guy.inMenu = true
	mainButton.disabled = true
	
	backnode.visible = true
	modnode.visible = true
	decknode.visible = true
	bagnode.visible = true
	
	guy.step = Vector2(0, -guy.stepy)
	guy.nodePosDest = guy.nodePosStart + guy.step*ticks
	
	backstep = Vector2(0, backstepy)
	backposDest = backposStart + backstep*ticks/2
	
	botstep = Vector2(0, -botstepy)
	modposDest = modposStart + botstep*ticks
	
	sidestep = Vector2(sidestepx, 0)
	deckposDest = deckposStart + sidestep*ticks
	bagposDest = bagposStart - sidestep*ticks
	
	map.currentEvent.disableButtons()
	Game.tileTooltip(false)
	yield(get_tree().create_timer(0.15), "timeout")
	_enable_mod_areas(true)
	enableAreaCollisions(true)
	
func close():
	enableAreaCollisions(false)
	z_index = 28
	open = false
	guy.inMenu = false
	mainButton.disabled = false
	_enable_mod_areas(false)
	
	guy.step = Vector2(0, guy.stepy)
	guy.nodePosDest = guy.nodePosStart
	
	backstep = Vector2(0, -backstepy)
	backposDest = backposStart
	
	botstep = Vector2(0, botstepy)
	modposDest = modposStart
	
	sidestep = Vector2(-sidestepx, 0)
	deckposDest = deckposStart
	bagposDest = bagposStart
	
	map.currentEvent.enableButtons()

func addMod(mod, amount = 1):
	modList[mod] += amount;
	get_node("mods/forgeButtonsBag/" + mod + "/Label").text = "x" + str(modList[mod])
	get_node("mods/content/" + mod).visible = false
	get_node("mods/forgeButtonsBag/" + mod + "/mod").scale = Vector2(1.5, 1.5)
	updateModButtons()

func subtractMod(mod):
	modList[mod] -= 1;
	get_node("mods/forgeButtonsBag/" + mod + "/Label").text = "x" + str(modList[mod])
	if modList[mod] == 0:
		get_node("mods/content/" + mod).visible = true
	get_node("mods/forgeButtonsBag/" + mod + "/mod").scale = Vector2(1.5, 1.5)
	updateModButtons()

func getMod(rune):
	return modList[rune]

func addGear(gearName):
	var gear = gearPreload.instance()
	var bagGear = bagGearPreload.instance()
	
	add_child(gear)
	gear.init(gearName)
	
	get_node("bag").add_child(bagGear)
	bagGearList.append(bagGear)
	bagGear.init(gear)
	bagGear.setPlace(bagGearList.find(bagGear))
	updateGearList()
	tickMainBagButton()

func addScroll(scrollName):
	var bagScroll = bagScrollPreload.instance()
	
	get_node("bag").add_child(bagScroll)
	bagGearList.append(bagScroll)
	bagScroll.init(scrollName)
	bagScroll.setPlace(bagGearList.find(bagScroll))
	updateGearList()
	tickMainBagButton()
	
	textlog.push("You put the [s]" + scrollName + "[n] in your bag.")

func addCard(cardName, cardType = ""):
	var Card = load("res://Card/Card.tscn").instance()
	guy.Deck.add(Card)
	Card.init(cardName)
	if Card.cardType == "Item" && cardType == "Device":
		Card.changeToDevice()
	
	var bagCard = load("res://Bag/bagCard.tscn").instance()
	bagCard.init(Card)
	if cardType == "":
		cardType = Card.cardType
	bagCardList[cardType].append(bagCard)
	get_node("deck/bagCards").add_child(bagCard)
	
	bagCardListSize()
	updateBagCards()
	selectCard(bagCard)
	if cardType != "Positive" && cardType != "Negative":
		tickMainBagButton()

func hasScroll(scrollName):
	for bagItem in bagGearList:
		if bagItem.gearType == "Scroll" && bagItem.scrollName == scrollName:
			return true
	return false

func updateGearList():
	for i in len(bagGearList):
		if bagGearList[i] != null:
			bagGearList[i].setPlace(i)

func destroyBagCard(card):
	for key in bagCardList:
		for bagCard in bagCardList[key]:
			if card.equals(bagCard.Card):
				var bc = bagCard
				bc.removeAllMods()
				bc.remove()
				bc.destroy()
				break
	selectCard(getBagCardList(0))

func putOnGear(bagGear):
	var gearType = bagGear.Gear.gearType
	
	var toBeRemoved = bagGearEquipped[gearType]
	toBeRemoved.setPlace(bagGear.currentPlace)
	toBeRemoved.takeOff()
	if !toBeRemoved.isNoGear():
		bagGearList.insert(bagGear.currentPlace, toBeRemoved)
		
	bagGear.setPlace(-1)
	bagGear.putOn()
	selectNewCard(bagGear)
	
	get_node("bag/No" + gearType).visible = false
	updateGearList()
	bagCardListSize()
	bagCardMoveTo()
	bagCardDisplay.checkTabs()

func takeOffGear(gearType):
	if bagGearList.size() < maxsize:
		var toBeRemoved = bagGearEquipped[gearType]
		toBeRemoved.takeOff()
		toBeRemoved.setPlace(len(bagGearList))
		bagGearList.append(toBeRemoved)
		
		if gearType == "Weapon":
			noWeapon.putOn()
		elif gearType == "Armor":
			noArmor.putOn()
		elif gearType == "Headgear":
			noHeadgear.putOn()
		selectNewCard(bagGearEquipped[gearType])
		get_node("bag/No" + gearType).visible = true
		
		updateGearList()
		bagCardListSize()
		bagCardMoveTo()
		bagCardDisplay.checkTabs()

func dropGear(bagGear):
	var gearType = bagGear.gearType
	bagGear.removeAllMods()
	if bagGearEquipped[gearType] == bagGear:
		var toBeRemoved = bagGearEquipped[gearType]
		toBeRemoved.takeOff()
		toBeRemoved.remove()
		
		if gearType == "Weapon":
			noWeapon.putOn()
		elif gearType == "Armor":
			noArmor.putOn()
		elif gearType == "Headgear":
			noHeadgear.putOn()
		selectNewCard(bagGearEquipped[gearType])
		get_node("bag/No" + gearType).visible = true
	else:
		for i in range(len(bagGearList)):
			if(bagGearList[i] == bagGear):
				bagGearList[i].remove()
				bagGearList.remove(i)
				break
		
	updateGearList()
	bagCardListSize()
	bagCardMoveTo()

func dropScroll(bagScroll):
	for i in range(len(bagGearList)):
			if(bagGearList[i] == bagScroll):
				bagGearList[i].queue_free()
				bagGearList.remove(i)
				break
	
	updateGearList()
	bagCardListSize()
	bagCardMoveTo()
	if map.currentEvent.name == "eventEmpty":
		map.currentEvent.removeScrolls()

func destroyScroll(scrollName):
	for i in range(len(bagGearList)):
			if bagGearList[i].gearType == "Scroll" && bagGearList[i].scrollName == scrollName:
				bagGearList[i].queue_free()
				bagGearList.remove(i)
				break
		
	updateGearList()
	bagCardListSize()
	bagCardMoveTo()

func initNoGear():
	var attackList = []
	bagCardList["Attack"] = attackList
	var defendList = []
	bagCardList["Defend"] = defendList
	var spellList = []
	bagCardList["Spell"] = spellList
	var positiveList = []
	bagCardList["Positive"] = positiveList
	var negativeList = []
	bagCardList["Negative"] = negativeList
	var deviceList = []
	bagCardList["Device"] = deviceList
	var itemList = []
	bagCardList["Item"] = itemList
	var harmfulList = []
	bagCardList["Harmful"] = harmfulList
	
	#create and equip No Weapon
	var noWeaponGear = gearPreload.instance()
	noWeapon = bagGearPreload.instance()
	
	add_child(noWeaponGear)
	noWeaponGear.init("No Weapon")
	
	get_node("bag").add_child(noWeapon)
	bagGearList.append(noWeapon)
	noWeapon.init(noWeaponGear)
	noWeapon.putOn()
	
	#create and equip No Armor
	var noArmorGear = gearPreload.instance()
	noArmor = bagGearPreload.instance()
	
	add_child(noArmorGear)
	noArmorGear.init("No Armor")
	
	get_node("bag").add_child(noArmor)
	bagGearList.append(noArmor)
	noArmor.init(noArmorGear)
	noArmor.putOn()
	
	#create and equip No Headgear
	var noHeadgearGear = gearPreload.instance()
	noHeadgear = bagGearPreload.instance()
	
	add_child(noHeadgearGear)
	noHeadgearGear.init("No Headgear")
	
	get_node("bag").add_child(noHeadgear)
	bagGearList.append(noHeadgear)
	noHeadgear.init(noHeadgearGear)
	noHeadgear.putOn()
	
	selectCard(bagCardList["Attack"][0])
	bagCardListSize()

func bagCardMoveTo():
	for i in guy.Deck.size():
		getBagCardList(i).moveTo(i)

func updateBagCards():
	for i in guy.Deck.size():
		getBagCardList(i).setPos(i)

func selectNewCard(bagGear):
	if len(bagGear.bagCardList) > 0:
		selectCard(bagGear.bagCardList[0])
	elif bagCardListSize > 0:
		selectCard(getBagCardList(0))

func selectCard(bagCard):
	if selectedBagCard != null:
		selectedBagCard.deselect()
	selectedBagCard = bagCard
	selectedBagCard.select()

func bagCardListSize():
	var size = 0
	for key in bagCardList:
		for i in bagCardList[key]:
			size += 1
	bagCardListSize = size
	return bagCardListSize
	
func getBagCardList(index):
	var key = "Device"
	var keylist = ["Device", "Attack", "Defend", "Spell", "Positive", "Negative", "Item", "Harmful"]
	while index >= len(bagCardList[key]):
		index -= len(bagCardList[key])
		for i in keylist.size():
			if i < keylist.size()-1 && keylist[i] == key:
				key = keylist[i+1]
				break
	return bagCardList[key][index]
	
func removeBagCardList(bagCard):
	for key in bagCardList:
		for bc in bagCardList[key]:
			if bc == bagCard:
				bagCardList[key].erase(bc)
				break

func applyMod(modname):
	var card = selectedBagCard.Card
	if modList[modname] > 0 && (!card.hasMod(modname) || modname == "Link" || modname == "Stay"):
		card.applyMod(modname)
		subtractMod(modname)
		selectedBagCard.displayCard.changeMod(modname)
		updateMods()

func removeMod(modname):
	var card = selectedBagCard.Card
	if modname == "Stay" || modname == "Link":
		card.incrementMod(modname, "down")
	else:
		card.removeMod(modname)
	addMod(modname)
	selectedBagCard.displayCard.changeMod(modname)
	updateMods()

func incrementMod(modname, updown):
	if modname == "Stay":
		if updown == "up" && modList[modname] > 0:
			subtractMod(modname)
		elif updown == "down" && selectedBagCard.Card.mods["Stay"] > 1:
			addMod(modname)
		else:
			return
	var card = selectedBagCard.Card
	card.incrementMod(modname, updown)
	selectedBagCard.displayCard.changeMod(modname)
	updateMods()

func removeAllMods():
	for key in bagCardList:
		for bc in bagCardList[key]:
			bc.removeAllMods()
	for bg in bagGearList:
		if bg.gearType != "Scroll":
			bg.removeAllMods()

func updateMods():
	selectedBagCard.updateMods()

func updateModButtons():
	for key in modList:
		if modList[key] > 0:
			get_node("mods/forgeButtonsBag/" + key).visible = true
		else:
			get_node("mods/forgeButtonsBag/" + key).visible = false
			
func deckScrollUp(updown, amount):
	if amount > 0 && ((updown == 1 && deckScrollValue <= bagCardListSize) || (updown == -1 && deckScrollValue > bagCardsOnScreen)):
		var scroll = bagCardHeight*updown
		get_node("deck/bagCards").position.y -= scroll
		deckScrollValue += scroll/bagCardHeight
		deckScrollUp(updown, amount-1)

func updateGold():
	get_node("bag/Gold/Amount").text = str(guy.Gold)

#Interaction Things
func enableAreaCollisions(truefalse):
	get_node("deck/scrollArea/CollisionShape2D").disabled = !truefalse
	selectedBagCard.displayCard.enableAreaCollisions(truefalse)
	_enable_mod_areas(truefalse)
	for key in bagCardList:
		for bagCard in bagCardList[key]:
			bagCard.enableAreaCollisions(truefalse)
	for thing in bagGearList:
		thing.enableAreaCollisions(truefalse)
	for key in bagGearEquipped:
		bagGearEquipped[key].enableAreaCollisions(truefalse)
	noWeapon.enableAreaCollisions(truefalse)
	noArmor.enableAreaCollisions(truefalse)
	noHeadgear.enableAreaCollisions(truefalse)
	get_node("mods/runesArea/CollisionShape2D").disabled = !truefalse

func tickMainBagButton():
	var newticks = 6
	bagButtonTicks += newticks
	var bscale = mainButtonScale*newticks
	get_node("bagButtonMain/button_Bag").scale += Vector2(bscale, bscale)

func tickMainBodyButton():
	var newticks = 6
	bodyButtonTicks += newticks
	var bscale = mainButtonScale*newticks
	get_node("bodyButtonMain/button_Body").scale += Vector2(bscale, bscale)
	

func _on_buttonBody_button_down():
	get_node("bodyButtonMain/button_Body").scale -= Vector2(0.005, 0.005)

func _on_buttonBody_button_up():
	get_node("bodyButtonMain/button_Body").scale += Vector2(0.005, 0.005)

func _on_buttonBody_pressed():
	Input.action_press("body")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("body")


func _on_buttonBag_button_down():
	get_node("bagButtonMain/button_Bag").scale -= Vector2(0.005, 0.005)

func _on_buttonBag_button_up():
	get_node("bagButtonMain/button_Bag").scale += Vector2(0.005, 0.005)

func _on_buttonBag_pressed():
	Input.action_press("bag")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("bag")


func _on_buttonBodyMenu_button_down():
	get_node("back/bodyButtonMenu/button_Body").scale -= Vector2(0.003, 0.003)

func _on_buttonBodyMenu_button_up():
	get_node("back/bodyButtonMenu/button_Body").scale += Vector2(0.003, 0.003)

func _on_buttonBodyMenu_pressed():
	Input.action_press("body")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("body")


func _on_buttonBagMenu_button_down():
	get_node("back/bagButtonMenu/button_Bag").scale -= Vector2(0.003, 0.003)

func _on_buttonBagMenu_button_up():
	get_node("back/bagButtonMenu/button_Bag").scale += Vector2(0.003, 0.003)

func _on_buttonBagMenu_pressed():
	Input.action_press("bag")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("bag")

func _enable_mod_areas(truefalse):
	for key in modList:
		get_node("mods/modForgeAreas/" + key + "/modArea/CollisionShape2D").disabled = !truefalse

func _on_Area2D_area_shape_entered(area_id, area, area_shape, self_shape):
	if area.get_name() == "cursorArea" && self_shape < bagCardListSize:
		getBagCardList(self_shape).scrollOver(true)


func _on_Area2D_area_shape_exited(area_id, area, area_shape, self_shape):
	if area.get_name() == "cursorArea" && self_shape < bagCardListSize:
		getBagCardList(self_shape).scrollOver(false)


func _on_scrollArea_area_entered(area):
	if area.get_name() == "cursorArea" && bagCardListSize > 13:
		canScroll = true
		get_node("deck/pageUpButton").visible = true
		get_node("deck/pageDownButton").visible = true
		scrollButtonTicks = 4
		scrollButtonStepx = 10

func _on_scrollArea_area_exited(area):
	if area.get_name() == "cursorArea" && bagCardListSize > 13:
		canScroll = false
		scrollButtonTicks = 4
		scrollButtonStepx = -10

func _on_button_ScrollPageUp_pressed():
		deckScrollUp(-1, bagCardsOnScreen+2)

func _on_button_ScrollPageUp_button_up():
	get_node("deck/pageUpButton/scrollPageButton").scale += Vector2(0.003, 0.003)

func _on_button_ScrollPageUp_button_down():
	get_node("deck/pageUpButton/scrollPageButton").scale -= Vector2(0.003, 0.003)


func _on_button_ScrollPageDown_pressed():
		deckScrollUp(1, bagCardsOnScreen+2)

func _on_button_ScrollPageDown_button_up():
	get_node("deck/pageDownButton/scrollPageButton").scale += Vector2(0.003, 0.003)

func _on_button_ScrollPageDown_button_down():
	get_node("deck/pageDownButton/scrollPageButton").scale -= Vector2(0.003, 0.003)


func _on_runesArea_area_entered(area):
	if area.get_name() == "cursorArea" && open:
		runesHover = true

func _on_runesArea_area_exited(area):
	if area.get_name() == "cursorArea":
		runesHover = false
