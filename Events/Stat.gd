extends "res://Events/Event.gd"

var ticks
var whichstep
var strstep
var dexstep
var intstep

func init2(r):
	init(r)
	
	ticks = 10
	whichstep = rand_range(0, 1) + 29
	strstep = rand_range(0, 1) + 29
	dexstep = rand_range(0, 1) + 29
	intstep = rand_range(0, 1) + 29

	get_node("which").rotation_degrees = rand_range(-1.5, 1.5)
	get_node("str").rotation_degrees = rand_range(-4, 4)
	get_node("dex").rotation_degrees = rand_range(-4, 4)
	get_node("int").rotation_degrees = rand_range(-4, 4)
	
func _process(delta):
	if ticks > 0:
		get_node("which").position.y -= whichstep
		get_node("str").position.y -= strstep
		get_node("dex").position.y -= dexstep
		get_node("int").position.y -= intstep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	
	if !guy.inMenu && !close:	
		if Input.is_action_just_pressed("ui_left") || Input.is_action_just_pressed("number_1"):
			guy.addStat("Strength", 1)
			textlog.push("[b]You gain 1 Strength.")
			end2()
		elif Input.is_action_just_pressed("ui_up") || Input.is_action_just_pressed("number_2"):
			guy.addStat("Dexterity", 1)
			textlog.push("[l]You gain 1 Dexterity.")
			end2()
		elif Input.is_action_just_pressed("ui_right") || Input.is_action_just_pressed("number_3"):
			guy.addStat("Intelligence", 1)
			textlog.push("[i]You gain 1 Intelligence.")
			end2()

func end2():
	ticks = 10
	whichstep = randi()%3 - 30
	strstep = randi()%3 - 30
	dexstep = randi()%3 - 30
	intstep = randi()%3 - 30
	
	end()


func disableButtons():
	get_node("str/buttonStr").visible = false
	get_node("dex/buttonDex").visible = false
	get_node("int/buttonInt").visible = false
	
func enableButtons():
	get_node("str/buttonStr").visible = true
	get_node("dex/buttonDex").visible = true
	get_node("int/buttonInt").visible = true

func _on_buttonStr_pressed():
	Input.action_press("number_1")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_1")

func _on_buttonDex_pressed():
	Input.action_press("number_2")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_2")

func _on_buttonInt_pressed():
	Input.action_press("number_3")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("number_3")


func _on_statAreaStr_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("str/glow2").visible = true


func _on_statAreaStr_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("str/glow2").visible = false


func _on_statAreaDex_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("dex/glow2").visible = true


func _on_statAreaDex_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("dex/glow2").visible = false


func _on_statAreaInt_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("int/glow2").visible = true


func _on_statAreaInt_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("int/glow2").visible = false
