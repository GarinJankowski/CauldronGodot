extends Node2D
var guy
var Bag

var Gear
var gearType
var ontexture
var offtexture
var texturesprite

var bagCardList = []
var sideBagCardList = []

var currentPos
var currentPlace

var on = false
var noGear = false

var hover = false

var normaltexture = preload("res://Bag/UI Elements/button_Bag.png")
var redtexture = preload("res://Bag/UI Elements/button_BagRed.png")

var bagCardPreload = preload("res://Bag/bagCard.tscn")

var Game

func init(g):
	Game = get_parent().get_parent().Game
	guy = Game.guy
	Bag = guy.Bag
	Gear = g
	gearType = Gear.gearType
	
	texturesprite = get_node("Sprite")
	ontexture = load("res://Bag/UI Elements/baggear_" + Gear.gearType + "On.png")
	offtexture = load("res://Bag/UI Elements/baggear_" + Gear.gearType + "Off.png")
	get_node("Label").text = Gear.gearName
	texturesprite.set_texture(offtexture)
	currentPlace = -2
	
	for i in Gear.cards.size():
		var bagCard = load("res://Bag/bagCard.tscn").instance()
		bagCard.init(Gear.cards[i])
		bagCard.disable()
		sideBagCardList.append(bagCard)
	Bag.bagCardDisplay.addBagCards(self)
	
	if Gear.gearName == "No Weapon" ||  Gear.gearName == "No Armor" || Gear.gearName == "No Headgear":
		noGear = true
		visible = false
		currentPlace = -1
		setPos()
	
#func _input(event):
	#if event is InputEventMouseMotion && held:
		#position += event.relative
		
func _input(event):
	if Bag.open && !guy.inCombat && hover && Input.is_action_just_released("RMB"):
		removeAllMods()

#puts on the Gear itself, instaniates the bagCards, sets the guy.gear, sets the Bag.bagGearEquipped, removes from Bag.bagGearList
func putOn():
	Gear.putOn(guy.Deck)
	
	for i in Gear.cards.size():
		var bagCard = bagCardPreload.instance()
		bagCard.init(Gear.cards[i])
		bagCard.sideBagCard = sideBagCardList[i]
		bagCardList.append(bagCard)
		Bag.bagCardList[Gear.cards[i].cardType].append(bagCard)
		Bag.get_node("deck/bagCards").add_child(bagCard)
		
	var cardType
	if gearType == "Weapon":
		cardType = "Attack"
	elif gearType == "Armor":
		cardType = "Defend"
	elif gearType == "Headgear":
		cardType = "Spell"
		
	Bag.bagCardListSize()
	for i in Bag.bagCardListSize:
		if contains(Bag.getBagCardList(i)):
			Bag.getBagCardList(i).setPos(i)
	
	guy.gear[gearType] = Gear
	Bag.bagGearEquipped[gearType] = self
	Bag.bagGearList.erase(self)
	
	on = true
	texturesprite.set_texture(ontexture)

#takes off the Gear itself, removes the bagCards, removes from guy.gear, removes from Bag.bagGearEquipped
func takeOff():
	Gear.takeOff(guy.Deck)
	
	for bagCard in bagCardList:
		bagCard.remove()
	bagCardList.clear()
	guy.gear[gearType] = null
	Bag.bagGearEquipped[gearType] = null
	
	on = false
	texturesprite.set_texture(offtexture)

func remove():
	for bagCard in bagCardList:
		bagCard.queue_free()
	for bagCard in sideBagCardList:
		bagCard.queue_free()
	queue_free()

func setPlace(place):
	if !noGear:
		currentPlace = place
		setPos()

func setPos():
	var y = -328 + currentPlace*54
	if currentPlace == -1:	
		texturesprite.set_texture(ontexture)
		if Gear.gearType == "Weapon":
			y = -534
		elif Gear.gearType == "Armor":
			y = -480
		elif Gear.gearType == "Headgear":
			y = -426
	position = Vector2(192, y)

func contains(bagCard):
	var isin = false
	for bc in bagCardList:
		if bc == bagCard:
			isin = true
	return isin

func isNoGear():
	return noGear

func removeAllMods():
	if !on:
		for i in Gear.cards.size():
			var Card = Gear.cards[i]
			for key in Card.mods:
				if key == "Stay" || key == "Link":
					while Card.mods[key] > 0:
						Card.mods[key] -= 1
						Bag.addMod(key)
				elif Card.mods[key]:
					Card.mods[key] = false
					Bag.addMod(key)
			Card.updateMods()
			sideBagCardList[i].updateMods()
	else:
		for bagCard in bagCardList:
			bagCard.removeAllMods()

func checkMods():
	var has = false
	if !on:
		for Card in Gear.cards:
			for key in Card.mods:
				if (key == "Stay" || key == "Link") && Card.mods[key] > 0:
					has = true
				elif Card.mods[key]:
					has = true
	else:
		for bagCard in bagCardList:
			if bagCard.checkMods():
				has = true
	return has

#Interaction Things
func enableAreaCollisions(truefalse):
	get_node("bagGearArea/CollisionShape2D").disabled = !truefalse
	get_node("dropbutton/dropArea/CollisionShape2D").disabled = !truefalse

func _on_drop_pressed():
	if !Bag.guy.inCombat && !noGear:
		Bag.dropGear(self)

func _on_hold_button_down():
	if !Bag.guy.inCombat:
		scale -= Vector2(0.03, 0.03)

func _on_hold_button_up():
	if !Bag.guy.inCombat:
		scale += Vector2(0.03, 0.03)
		
func _on_hold_pressed():
	if !Bag.guy.inCombat && !noGear:
		if on:
			Bag.takeOffGear(gearType)
		else:
			Bag.putOnGear(self)

func _on_drop_button_down():
	get_node("dropbutton/x").scale -= Vector2(0.002, 0.002)

func _on_drop_button_up():
	get_node("dropbutton/x").scale += Vector2(0.002, 0.002)

func _on_dropArea_area_entered(area):
	if area.get_name() == "cursorArea" && !Bag.guy.inCombat && !noGear:
		get_node("dropbutton/x").set_texture(redtexture)

func _on_dropArea_area_exited(area):
	if area.get_name() == "cursorArea" && !Bag.guy.inCombat && !noGear:
		get_node("dropbutton/x").set_texture(normaltexture)

func _on_bagGearArea_area_entered(area):
	if area.get_name() == "cursorArea":
		if !noGear || Bag.bagGearEquipped[gearType] == self:
			Bag.bagCardDisplay.open(self)
		hover = true

func _on_bagGearArea_area_exited(area):
	if area.get_name() == "cursorArea":
		Bag.bagCardDisplay.close()
		hover = false
