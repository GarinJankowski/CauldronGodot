extends Node2D

var Body
var mutationName
var mutationDescription
var multiplier

var selected = false
var displayMutation

var positive
var index
var posx = 228
var posy = -542

var Game

func init(v, p, i, b):
	Game = get_parent().get_parent().get_parent().Game
	
	Body = b
	
	mutationName = v[0]
	mutationDescription = v[1]
	multiplier = 1
	
	index = i
	positive = p
	
	makeSprite()
	position = Vector2(posx, posy + i*86)
	
	displayMutation = load("res://Body/displayMutation.tscn").instance()
	Body.get_node("back").add_child(displayMutation)
	displayMutation.init(self)

func nameEquals(n):
	if n == mutationName:
		return true
	return false

func incrementMutation():
	multiplier += 1
	get_node("multiplier").visible = true
	get_node("multiplier").text = "x" + str(multiplier)
	displayMutation.updateMultiplier()

func makeSprite():
	get_node("Name").text = mutationName
	
	var pos = "Positive"
	if !positive:
		pos = "Negative"
		get_node("glow/glow").modulate = "3ccb1bd0"
	
	get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + mutationName + ".png"))
	if get_node("mutationSprite").texture == null:
		get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + pos + ".png"))

func select():
	selected = true
	displayMutation.select()
	get_node("bagMutationCursor").visible = true
	get_node("glow").visible = true
	
func deselect():
	selected = false
	displayMutation.deselect()
	get_node("bagMutationCursor").visible = false
	get_node("glow").visible = false

func enableAreaCollisions(truefalse):
	get_node("mutationArea/CollisionShape2D").disabled = !truefalse

func _on_mutationArea_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("glow").visible = true

func _on_mutationArea_area_exited(area):
	if area.get_name() == "cursorArea" && !selected:
		get_node("glow").visible = false

func _on_mutationButton_pressed():
	if !selected:
		Body.selectMutation(self)
