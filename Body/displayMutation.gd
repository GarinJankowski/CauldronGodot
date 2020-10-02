extends Node2D

var bodyMutation

var startx
var midx
var destx

var destinationx

var stepx = 75

func init(bodyMut):
	bodyMutation = bodyMut
	makeSprite()
	
	visible = false
	position.y = 968
	if bodyMutation.positive:
		position.x = -240
	else:
		position.x = 1260
		
	startx = position.x
	midx = 510
	destx = startx
	if !bodyMutation.positive:
		stepx *= -1
		
func _process(delta):
	if position.x != destinationx:
		position.x += stepx
		if position.x == destx:
			visible = false
			position.x = startx
			destinationx = startx
			stepx *= -1
		if position.x == midx:
			z_index = 19
	
func select():
	z_index = 0
	position.x = startx
	visible = true
	destinationx = midx
	
func deselect():
	z_index = 0
	destinationx = destx
	stepx *= -1

func makeSprite():
	get_node("Name").text = bodyMutation.mutationName
	get_node("Description").text = bodyMutation.mutationDescription
	
	var pos = "Positive"
	if !bodyMutation.positive:
		pos = "Negative"
	
	get_node("backSprite").set_texture(load("res://Body/mutation_back" + pos + ".png"))
	get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + bodyMutation.mutationName + ".png"))
	if get_node("mutationSprite").texture == null:
		get_node("mutationSprite").set_texture(load("res://Body/" + pos + " Mutations/mutation_" + pos + ".png"))
		
	updateMultiplier()

func updateMultiplier():
	if bodyMutation.scriptObject.multiplier > 1:
		get_node("multiplier").text = "x" + str(bodyMutation.scriptObject.multiplier)

