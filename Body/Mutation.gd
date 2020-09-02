extends Node2D

var body

var mutationName
var mutationDescription
var positive
var index

var desty = 476
var starty = 780
var stepy = 38

var Game

func init(n, d, p, b, i):
	Game = get_parent().Game
	mutationName = n
	mutationDescription = d
	positive = p
	index = i
	
	body = b
	
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
	
	var pos = "Positive"
	if !positive:
		pos = "Negative"
		get_node("glow/glow").modulate = "3ccb1bd0"
		get_node("glow/glowback").modulate = "3ccb1bd0"
	
	get_node("backSprite").set_texture(load("res://Body/mutation_back" + pos + ".png"))
	get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + mutationName + ".png"))
	if get_node("mutationSprite").texture == null:
		get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + pos + ".png"))

func end(chosen):
	if chosen:
		stepy *= 1.5
		desty -= stepy*10
	else:
		desty = starty
		stepy *= -1

func apply():
	body.addMutation(self)

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
