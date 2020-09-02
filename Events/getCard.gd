extends "res://Events/Event.gd"

var cardName
var cardType

var ticks
var tick2 = 8
var whatstep
var gearstep
var addstep
var leavestep

func init2(r):
	init(r)
	
	cardName = r.cardName
	cardType = r.cardType
	
	var card = load("res://Card/Card.tscn").instance()
	add_child(card)
	card.init(cardName)
	if card.cardType == "Item" && cardType == "Device":
		card.changeToDevice()
	
	get_node("card").visible = true
	get_node("card/cardSprite").set_texture(card.get_node("Top/cardSprite").texture)
	get_node("card/cardCost").visible = card.get_node("Top/cardCost").visible
	get_node("card/nameText").text = card.cardName
	get_node("card/descriptionText").text = card.cardDescription
	get_node("card/costText").text = card.get_node("Top/costText").text
	get_node("card/costText").visible = card.get_node("Top/costText").visible
	var dynamicFont = card.dynamicFont
	get_node("card/nameText").add_font_override("font", dynamicFont)
	card.queue_free()
	
	ticks = 10
	whatstep = rand_range(0, 1) + 28
	gearstep = rand_range(0, 1) + 67
	addstep = rand_range(0, 2) + 28
	leavestep = rand_range(0, 2) + 28
	
	get_node("what").rotation_degrees = rand_range(-2, 2)
	get_node("card").rotation_degrees = rand_range(-3, 3)
	get_node("card").position.y += rand_range(-3, 3)
	get_node("add").rotation_degrees = rand_range(-4, 4)
	get_node("leave").rotation_degrees = rand_range(-4, 4)
	
	
func _process(delta):
	if ticks > 0:
		get_node("what").position.y -= whatstep
		get_node("add").position.y -= addstep
		get_node("leave").position.y -= leavestep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	if tick2 > 0:	
		get_node("card").position.x += gearstep
		tick2 -= 1

	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("ui_up") || Input.is_action_just_pressed("number_1"):
			guy.Bag.addCard(cardName, cardType)
			end2(1)
		elif Input.is_action_just_pressed("ui_down") || Input.is_action_just_pressed("number_2"):
			end2(-1)

func end2(added):
	ticks = 10
	tick2 = 10
	whatstep = randi()%3 - 30
	gearstep = added*(rand_range(0, 1) + 67)
	addstep = randi()%3 - 30
	leavestep = randi()%3 - 30
	
	end()


func disableButtons():
	get_node("add/buttonAdd").visible = false
	get_node("add/buttonAdd").visible = false
	
func enableButtons():
	get_node("add/buttonAdd").visible = true
	get_node("add/buttonAdd").visible = true
	
func _on_buttonAdd_pressed():
	Input.action_press("ui_up")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_up")

func _on_buttonLeave_pressed():
	Input.action_press("ui_down")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_down")

func _on_moveAreaAdd_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("add/glow").visible = true

func _on_moveAreaAdd_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("add/glow").visible = false

func _on_moveAreaLeave_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = true

func _on_moveAreaLeave_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = false
