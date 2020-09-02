extends "res://Events/Event.gd"

var runes

var ticks
var tick2 = 8
var whatstep
var gearstep
var gearstepy = 0
var addstep
var ended = false

func init2(r):
	init(r)
	
	runes = r.runes
	var numrunes = runes.size()
	if numrunes == 2:
		get_node("things/rune1/runesprite").set_texture(load("res://Modifiers/mod_" + runes[0] + ".png"))
		get_node("things/rune2/runesprite").set_texture(load("res://Modifiers/mod_" + runes[1] + ".png"))
		get_node("things/rune3").visible = false
	elif numrunes == 1:
		get_node("things/rune1/runesprite").set_texture(load("res://Modifiers/mod_" + runes[0] + ".png"))
		get_node("things/rune2").visible = false
		get_node("things/rune3").visible = false
		get_node("things/gear").position.x -= 80
		get_node("things/scroll").position.x -= 80
		get_node("things/card").position.x -= 80
		get_node("things").position.x += 70
	else:
		get_node("things/rune1/runesprite").set_texture(load("res://Modifiers/mod_" + runes[0] + ".png"))
		get_node("things/rune3/runesprite").set_texture(load("res://Modifiers/mod_" + runes[1] + ".png"))
		get_node("things/rune2/runesprite").set_texture(load("res://Modifiers/mod_" + runes[2] + ".png"))
		get_node("things").position.x += 20
	for r in runes:
		guy.Bag.addMod(r)
	getGold()
	
	get_node("things/gear/gearType").set_texture(load("res://UI/Gear/" + r.gearType.to_lower() + "Icon.png"))
	get_node("things/gear/Label").text = r.gearName
	
	ticks = 10
	whatstep = rand_range(0, 1) + 28
	gearstep = rand_range(0, 1) + 67
	addstep = rand_range(0, 2) + 28
	
	get_node("what").rotation_degrees = rand_range(-2, 2)
	get_node("things").position.y += rand_range(-3, 3)
	get_node("things/gold").position.x += rand_range(-5, 5)
	get_node("things/gear").rotation_degrees = rand_range(-3, 3)
	for i in 3:
		get_node("things/rune" + str(i+1)).rotation_degrees = rand_range(-4, 4)
		get_node("things/rune" + str(i+1)).position.y += rand_range(-3, 3)
		get_node("things/rune" + str(i+1)).position.y += rand_range(-3, 3)
	get_node("add").rotation_degrees = rand_range(-4, 4)
	
	if r.scrollName != null:
		get_node("things/scroll").visible = true
		get_node("things/scroll").rotation_degrees = rand_range(-4, 4)
		get_node("things/scroll/Label").text = r.scrollName
		get_node("things/scroll/scroll").set_texture(load("res://UI/Gear/scrollIcon_" + r.scrollName + ".png"))
		get_node("things/card").position.x += 210
		get_node("things").position.x -= 100
		
	if r.cardName != null:
		var card = load("res://Card/Card.tscn").instance()
		r.card = card
		add_child(card)
		card.visible = false
		card.init(r.cardName)
		if card.cardType == "Item" && r.cardType == "Device":
			card.changeToDevice()
		
		get_node("things/card").visible = true
		get_node("things/card").rotation_degrees = rand_range(-3, 3)
		get_node("things/card/cardSprite").set_texture(card.get_node("Top/cardSprite").texture)
		get_node("things/card/cardCost").visible = card.get_node("Top/cardCost").visible
		get_node("things/card/nameText").text = card.cardName
		get_node("things/card/descriptionText").text = card.cardDescription
		get_node("things/card/costText").text = card.get_node("Top/costText").text
		get_node("things/card/costText").visible = card.get_node("Top/costText").visible
		var dynamicFont = card.dynamicFont
		get_node("things/card/nameText").add_font_override("font", dynamicFont)
		get_node("things").position.x -= 100
	
func _process(delta):
	if ticks > 0:
		get_node("what").position.y -= whatstep
		get_node("add").position.y -= addstep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	if tick2 > 0:
		if !ended:
			get_node("things/gear").position.x += gearstep
			get_node("things/scroll").position.x += gearstep
			get_node("things/card").position.x += gearstep
		get_node("things/gear").position.y += gearstepy
		get_node("things/scroll").position.y += gearstepy
		get_node("things/card").position.y += gearstepy
		get_node("things/gold").position.x += gearstep
		get_node("things/rune1").position.x += gearstep
		get_node("things/rune2").position.x += gearstep
		get_node("things/rune3").position.x += gearstep
		tick2 -= 1
	
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("ui_up") || Input.is_action_just_pressed("number_1"):
			end2()

func getGold():
	var amount = room.gold
	
	get_node("things/gold/amount").text = str(amount)
	if amount > 4 && amount < 10:
		get_node("things/gold/gold1").visible = false
		get_node("things/gold/gold2").visible = true
	elif amount >= 10:
		get_node("things/gold/gold1").visible = false
		get_node("things/gold/gold3").visible = true
	guy.gainGold(amount)

func end2():
	ticks = 10
	tick2 = 10
	whatstep = randi()%3 - 30
	gearstep = rand_range(0, 1) + 67
	gearstepy = 15
	addstep = randi()%3 - 30
	ended = true
	
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

func _on_moveAreaAdd_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("add/glow").visible = true

func _on_moveAreaAdd_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("add/glow").visible = false
