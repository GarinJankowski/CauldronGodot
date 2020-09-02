extends Node2D

var Card
var bagCard
var cardSprite
var Bag

var hover = false
var startX = 200
var destinationX = 512
var dest1 = 512
var dest2 = 824
var stepX = 52

var textlog

var Game

func _on_Area2D_mouse_entered():
	visible = false

func init(c, b, bc):
	Game = c.Game
	Card = c
	Bag = b
	bagCard = bc
	get_node("Top/cardSprite").set_texture(Card.get_node("Top/cardSprite").texture)
	get_node("Top/cardIcon").set_texture(Card.get_node("Top/cardIcon").texture)
	get_node("Top/cardCost").visible = Card.get_node("Top/cardCost").visible
	get_node("Top/nameText").text = Card.cardName
	get_node("Top/descriptionText").text = Card.cardDescription
	get_node("Top/costText").text = Card.get_node("Top/costText").text
	get_node("Top/costText").visible = Card.get_node("Top/costText").visible
	updateMods()
	
	if len(Card.cardName) > 13:
		var dynamic_font = DynamicFont.new()
		dynamic_font.font_data = load("res://TIMESS__.ttf")
		dynamic_font.size = 36
		get_node("Top/nameText").add_font_override("font", dynamic_font)
	
	visible = false
	position = Vector2(512, -211)
	
	enableAreaCollisions(false)

func _process(delta):
	if position.x != destinationX:
		position.x += stepX
		if position.x == dest2:
			visible = false
	for key in Bag.modList:
		if get_node("Mods/forgeButtonsCard/" + key + "/mod").scale > Vector2(1, 1):
			get_node("Mods/forgeButtonsCard/" + key + "/mod").scale -= Vector2(0.1, 0.1)
	
func _input(event):
	if Bag.open && !Bag.guy.inCombat && hover && Input.is_action_just_released("RMB"):
		bagCard.removeAllMods()

func changeMod(modname):
	get_node("Mods/forgeButtonsCard/" + modname + "/mod").scale = Vector2(1.5, 1.5)

func select():
	position.x = startX
	visible = true
	destinationX = dest1
	enableAreaCollisions(true)
	
func deselect():
	destinationX = dest2
	enableAreaCollisions(false)
	
func pullBack():
	destinationX = startX
	stepX = -26

func enableAreaCollisions(truefalse):
	for key in Card.mods:
		get_node("Mods/forgeButtonsCard/" + key + "/modAreaDisplay/CollisionShape2D").disabled = !truefalse
	get_node("displayArea/CollisionShape2D").disabled = !truefalse

func updateMods():
	for key in Card.mods:
		if (key == "Stay" || key == "Link") && Card.mods[key] > 0:
			get_node("Mods/forgeButtonsCard/" + key).visible = true
			get_node("Mods/forgeButtonsCard/" + key + "/mod/text").text = str(Card.mods[key])
		elif Card.mods[key]:
			get_node("Mods/forgeButtonsCard/" + key).visible = true
		else:
			get_node("Mods/forgeButtonsCard/" + key).visible = false
	
	Card.updateMods()


func _on_displayArea_area_entered(area):
	if area.get_name() == "cursorArea" && Bag.open:
		hover = true

func _on_displayArea_area_exited(area):
	if area.get_name() == "cursorArea":
		hover = false
