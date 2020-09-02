extends Node2D

var guy
var Bag
var map

var scrollName
var gearType

var currentPlace

var normaltexture = preload("res://Bag/UI Elements/button_Bag.png")
var redtexture = preload("res://Bag/UI Elements/button_BagRed.png")

var Game

func init(n):
	Game = get_parent().get_parent().Game
	guy = Game.guy
	Bag = guy.Bag
	map = Game.map
	
	currentPlace = -2
	
	scrollName = n
	gearType = "Scroll"
	get_node("Label").text = scrollName
	get_node("Sprite").set_texture(load("res://Bag/UI Elements/bagScroll_" + scrollName + ".png"))

func setPlace(place):
		currentPlace = place
		setPos()

func setPos():
	var y = -328 + currentPlace*54
	position = Vector2(192, y)

#unused bagGear functions
func putOn():
	pass
	
func takeOff():
	pass
	
func checkMods():
	return false

func contains(bagCard):
	return false

func isNoGear():
	return false
	
func forgeOn(truefalse):
	pass

func removeAllMods():
	pass

func modButtonsVisible(truefalse):
	pass

#Interaction Things
func enableAreaCollisions(truefalse):
	get_node("dropbutton/dropArea/CollisionShape2D").disabled = !truefalse
	
func _on_drop_pressed():
	if !Bag.guy.inCombat:
		Bag.dropScroll(self)

func _on_drop_button_down():
	if !Bag.guy.inCombat:
		get_node("dropbutton/x").scale -= Vector2(0.002, 0.002)

func _on_drop_button_up():
	if !Bag.guy.inCombat:
		get_node("dropbutton/x").scale += Vector2(0.002, 0.002)

func _on_dropArea_area_entered(area):
	if area.get_name() == "cursorArea" && !Bag.guy.inCombat:
		get_node("dropbutton/x").set_texture(redtexture)

func _on_dropArea_area_exited(area):
	if area.get_name() == "cursorArea" && !Bag.guy.inCombat:
		get_node("dropbutton/x").set_texture(normaltexture)
