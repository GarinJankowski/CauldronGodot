extends Node2D

var Body
var mutationName
var mutationDescription
var positive
var multiplier = 1

var selected = false
var displayMutation

var index
var posx = 228
var posy = -542

var Game

func init(mutname, i):
	Game = get_parent().get_parent().get_parent().Game
	
	var mutscript = Game.scriptgen.MutationScripts[mutname]
	
	mutationName = mutname
	mutationDescription = mutscript[0]["mutationDescription"]
	positive = mutscript[0]["positive"]
	
	index = i
	
	makeSprite()
	position = Vector2(posx, posy + i*86)
	
	displayMutation = load("res://Body/displayMutation.tscn").instance()
	Body.get_node("back").add_child(displayMutation)
	displayMutation.init(self)

func incrementMutation():
	multiplier += 1
	get_node("multiplier").visible = true
	get_node("multiplier").text = "x" + str(multiplier)
	displayMutation.updateMultiplier()

func makeSprite():
	get_node("Name").text = mutationName
	
	if positive == "Negative":
		get_node("glow/glow").modulate = "3ccb1bd0"
	
	get_node("mutationSprite").set_texture(load("res://Body/" + positive + " Mutations/mutation_" + mutationName + ".png"))
	if get_node("mutationSprite").texture == null:
		get_node("mutationSprite").set_texture(load("res://Body/" + positive + " Mutations/mutation_" + positive + ".png"))

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
