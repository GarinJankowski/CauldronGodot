extends "res://Events/Event.gd"

var gearName
var gearType

var ticks
var tick2 = 8
var whatstep
var gearstep
var addstep
var leavestep

var bagfullmessage = false

func init2(r):
	init(r)
	
	gearName = r.gearName
	gearType = r.gearType
	
	get_node("gear/gearType").set_texture(load("res://UI/Gear/" + gearType.to_lower() + "Icon.png"))
	get_node("gear/Label").text = gearName
	
	ticks = 10
	whatstep = rand_range(0, 1) + 28
	gearstep = rand_range(0, 1) + 67
	addstep = rand_range(0, 2) + 28
	leavestep = rand_range(0, 2) + 28
	
	get_node("what").rotation_degrees = rand_range(-2, 2)
	get_node("gear").rotation_degrees = rand_range(-2, 2)
	get_node("gear").position.y += rand_range(-5, 5)
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
		get_node("gear").position.x += gearstep
		tick2 -= 1
	
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("ui_up") || Input.is_action_just_pressed("number_1"):
			if len(guy.Bag.bagGearList) < guy.Bag.maxsize:
				guy.Bag.addGear(gearName)
				var gearstr = ""
				if gearType == "Weapon":
					gearstr = "[b]"
				elif gearType == "Armor":
					gearstr = "[l]"
				elif gearType == "Headgear":
					gearstr = "[i]"
				gearstr += gearName + "[n]"
				textlog.push("You put the " + gearstr + " in your bag.")
				end2(1)
			elif !bagfullmessage:
				textlog.push("[r]Your bag is full.")
				bagfullmessage = true
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
