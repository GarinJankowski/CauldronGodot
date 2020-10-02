extends Node2D

var Body

var mutationName
var mutationDescription
var positive
var index

var desty = 476
var starty = 780
var stepy = 38

var Game

func init(n, i):
	Game = get_parent().Game
	Body = get_parent()
	mutationName = n
	var mutVariables = Game.scriptgen.MutationScripts[mutationName][0]
	mutationDescription = mutVariables["mutationDescription"]
	positive = mutVariables["positive"]
	index = i
	
	makeSprite()
	position = Vector2(180 + 332*index, 780)
	rotation_degrees = rand_range(-2, 2)

func _process(delta):
	if position.y != desty:
		position.y -= stepy
		if position.y == starty || position.y < 0:
			queue_free()

func makeSprite():
	get_node("Name").text = mutationName
	get_node("Description").text = mutationDescription
	
	if positive == "Negative":
		get_node("glow/glow").modulate = "3ccb1bd0"
		get_node("glow/glowback").modulate = "3ccb1bd0"
	
	get_node("backSprite").set_texture(load("res://Body/mutation_back" + positive + ".png"))
	get_node("mutationSprite").set_texture(load("res://Body/" + positive + " Mutations/mutation_" + mutationName + ".png"))
	if get_node("mutationSprite").texture == null:
		get_node("mutationSprite").set_texture(load("res://Body/" + positive + " Mutations/mutation_" + positive + ".png"))

func end(chosen):
	if chosen:
		stepy *= 1.5
		desty -= stepy*10
	else:
		desty = starty
		stepy *= -1

func removeSprite():
	get_node("backSprite").queue_free()
	get_node("mutationSprite").queue_free()
	get_node("glow").queue_free()
	get_node("Name").queue_free()
	get_node("Description").queue_free()
	get_node("mutationButton").queue_free()
	get_node("mutationArea").queue_free()

func _on_mutationArea_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("glow").visible = true

func _on_mutationArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("glow").visible = false

func _on_mutationButton_pressed():
	if index == 0:
		Input.action_press("number_1")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_1")
	elif index == 1:
		Input.action_press("number_2")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_2")
	elif index == 2:
		Input.action_press("number_3")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_3")
