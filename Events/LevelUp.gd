extends "res://Events/Event.gd"

var ticks
var whichstep
var hpstep
var epstep
var mpstep

func init2(r):
	init(r)
	
	ticks = 10
	whichstep = rand_range(0, 1) + 29
	hpstep = rand_range(0, 1) + 29
	epstep = rand_range(0, 1) + 29
	mpstep = rand_range(0, 1) + 29

	get_node("which").rotation_degrees = rand_range(-1.5, 1.5)
	get_node("maxhealth").rotation_degrees = rand_range(-4, 4)
	get_node("maxenergy").rotation_degrees = rand_range(-4, 4)
	get_node("maxmana").rotation_degrees = rand_range(-4, 4)
	
func _process(delta):
	if ticks > 0:
		get_node("which").position.y -= whichstep
		get_node("maxhealth").position.y -= hpstep
		get_node("maxenergy").position.y -= epstep
		get_node("maxmana").position.y -= mpstep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	
	if !guy.inMenu && !close:	
		if Input.is_action_just_pressed("ui_left") || Input.is_action_just_pressed("number_1"):
			guy.addStat("Max Health", 5)
			textlog.push("[r]You gain 5 Max Health.")
			end2()
		elif Input.is_action_just_pressed("ui_up") || Input.is_action_just_pressed("number_2"):
			guy.addStat("Max Energy", -1)
			textlog.push("[y]You lose 1 Max Energy.")
			end2()
		elif Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("number_3"):
			guy.addStat("Max Mana", 5)
			textlog.push("[i]You gain 5 Max Mana.")
			end2()

func end2():
	ticks = 10
	whichstep = randi()%3 - 30
	hpstep = randi()%3 - 30
	epstep = randi()%3 - 30
	mpstep = randi()%3 - 30
	
	end()

func disableButtons():
	get_node("maxhealth/buttonHP").visible = false
	get_node("maxenergy/buttonEP").visible = false
	get_node("maxmana/buttonMP").visible = false
	
func enableButtons():
	get_node("maxhealth/buttonHP").visible = true
	get_node("maxenergy/buttonEP").visible = true
	get_node("maxmana/buttonMP").visible = true

func _on_statAreaHP_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("maxhealth/glow2").visible = true

func _on_statAreaHP_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("maxhealth/glow2").visible = false

func _on_statAreaEP_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("maxenergy/glow2").visible = true

func _on_statAreaEP_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("maxenergy/glow2").visible = false

func _on_statAreaMP_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("maxmana/glow2").visible = true

func _on_statAreaMP_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("maxmana/glow2").visible = false


func _on_buttonHP_pressed():
	Input.action_press("number_1")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_1")

func _on_buttonEP_pressed():
	Input.action_press("number_2")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_2")

func _on_buttonMP_pressed():
	Input.action_press("number_3")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_3")
