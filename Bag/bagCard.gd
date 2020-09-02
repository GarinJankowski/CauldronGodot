extends Node2D

var guy
var Card
var displayCard
var Bag
var selected = false
var move = false
var sideBagCard

var posx = 228
var posy = -542

var height = 40
var offscreenx = posx-400
var newposy = posy
var newposx = posx

var hover = false
var disabled = false

var Game

func init(c):
	Game = c.Game
	guy = Game.guy
	Card = c
	Bag = guy.Bag
	
	displayCard = load("res://Bag/displayCard.tscn").instance()
	Bag.get_node("back").add_child(displayCard)
	displayCard.init(Card, Bag, self)
	
	get_node("cardName").text = Card.cardName
	get_node("bagCardSprite").set_texture(load("res://Bag/UI Elements/bagCards/bagCard_" + Card.cardType + ".png"))
	get_node("cardIcon").set_texture(load("res://Card/CardIcons/cardIcon_" + Card.cardName + ".png"))
	
	updateMods()
	
	moveIn()
	
func disable():
	enableAreaCollisions(false)
	get_node("bagCardButton").visible = false
	disabled = true

func _process(delta):
	if !disabled:
		if newposy > position.y:
			position.y += height/4
		elif newposy < position.y:
			position.y -= height/4
			
		if newposx > position.x:
			position.x += 25
			if position.x == newposx:
				z_index = 0
		elif newposx < position.x:
			position.x -= 25
			if position.x == newposx:
				displayCard.queue_free()
				queue_free()
	
func _input(event):
	if Bag.open && !guy.inCombat && hover && Input.is_action_just_released("RMB"):
		removeAllMods()

func moveIn():
	z_index = 0
	position.x = offscreenx
	newposx = posx
	
func remove():
	if selected:
		Bag.selectedBagCard = null
		displayCard.pullBack()
	Bag.removeBagCardList(self)
	newposx = offscreenx

func moveTo(index):
	newposy = index*40 + posy

func setPos(index):
	newposy = index*40+posy
	position.y = newposy
	
func select():
	selected = true
	displayCard.select()
	get_node("bagCardCursor").visible = true
	get_node("cardIcon").modulate = "55ffffff"
	get_node("nameBack").visible = true
	
	for key in Card.mods:
		if Card.mods[key]:
			get_node("modBacks/" + key + "Back").visible = true
	
func deselect():
	selected = false
	displayCard.deselect()
	get_node("bagCardCursor").visible = false
	get_node("cardIcon").modulate = "19ffffff"
	get_node("nameBack").visible = false
	
	for key in Card.mods:
		get_node("modBacks/" + key + "Back").visible = false
	
func updateMods():
	Card.updateMods()
	displayCard.updateMods()
	if sideBagCard != null:
		sideBagCard.updateMods()
	
	for key in Card.mods:
		if (key == "Link" || key == "Stay"):
			if Card.mods[key] > 0:
				get_node("mods/" + key).visible = true
				get_node("mods/" + key + "Text").text = str(Card.mods[key])
				get_node("mods/" + key + "Text").visible = true
			else:
				get_node("mods/" + key).visible = false
				get_node("mods/" + key + "Text").visible = false
		else:
			if Card.mods[key]:
				get_node("mods/" + key).visible = true
			else:
				get_node("mods/" + key).visible = false
	
	for key in Card.mods:
		if Card.mods[key]:
			get_node("modBacks/" + key + "Back").visible = true
		else:
			get_node("modBacks/" + key + "Back").visible = false

func removeAllMods():
	for key in Card.mods:
		if key == "Stay" || key == "Link":
			while Card.mods[key] > 0:
				Card.mods[key] -= 1
				Bag.addMod(key)
		elif Card.mods[key]:
			Card.mods[key] = false
			Bag.addMod(key)
	updateMods()
	
func checkMods():
	var has = false
	for key in Card.mods:
		if (key == "Stay" || key == "Link") && Card.mods[key] > 0:
			has = true
		elif Card.mods[key]:
			has = true
	return has
			
func scrollOver(truefalse):
	if truefalse:
		get_node("cardIcon").modulate = "55ffffff"
	else:
		get_node("cardIcon").modulate = "19ffffff"
	get_node("nameBack").visible = truefalse
		
	for key in Card.mods:
		if Card.mods[key]:
			get_node("modBacks/" + key + "Back").visible = truefalse

func destroy():
	displayCard.queue_free()
	if sideBagCard != null:
		sideBagCard.queue_free()
	queue_free()

#Interaction Things
func enableAreaCollisions(truefalse):
	get_node("bagCardArea/CollisionShape2D").disabled = !truefalse

func _on_bagCardButton_pressed():
	if !selected:
		Bag.selectCard(self)

func _on_bagCardArea_area_entered(area):
	if area.get_name() == "cursorArea" && Bag.open:
		hover = true
		scrollOver(true)

func _on_bagCardArea_area_exited(area):
	if area.get_name() == "cursorArea":
		hover = false
		if !selected:
			scrollOver(false)

