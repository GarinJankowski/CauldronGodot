extends "res://Events/Event.gd"

var mod1
var mod2
var mod3

var pBurn = 20
var pFlow = 20
var pStay = 13
var pLink = 20
var pPush = 14
var pCopy = 8

var ticks
var tick2 = 8
var leavestep
var modstep
var forgestep

func init2(m, r):
	init(m, r)
	
	pFlow += pBurn
	pStay += pFlow
	pLink += pStay
	pPush += pLink
	pCopy += pPush
	
	mod1 = randomMod()
	mod2 = randomMod()
	mod3 = randomMod()
	
	get_node("forge/mod1").set_texture(load("res://Modifiers/mod_" + mod1 + ".png"))
	get_node("forge/mod2").set_texture(load("res://Modifiers/mod_" + mod2 + ".png"))
	get_node("forge/mod3").set_texture(load("res://Modifiers/mod_" + mod3 + ".png"))
	
	guy.Bag.addMod(mod1)
	guy.Bag.addMod(mod2)
	guy.Bag.addMod(mod3)
	
	guy.Bag.forgeOn(true)

	ticks = 10
	forgestep = 29
	leavestep = rand_range(0, 2) + 28
	modstep = 125
	
	get_node("leave").rotation_degrees = rand_range(-4, 4)
	
	textlog.push("[o]You obtain a " + modColor(mod1) + ", " + modColor(mod2) + ", and " + modColor(mod3) + " rune.")

func _process(delta):
	if ticks > 0:
		get_node("leave").position.y -= leavestep
		get_node("forge").position.y -= forgestep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	if tick2 > 0:	
		get_node("mods").position.x += modstep
		tick2 -= 1
	
	if !guy.inMenu && !close:
		get_node("forge/buttonBag").disabled = false
		if Input.is_action_just_pressed("ui_down") || Input.is_action_just_pressed("number_2"):
			end2()

func end2():
	guy.Bag.forgeOn(false)
	guy.updateUI()
	
	ticks = 10
	leavestep = randi()%3 - 30
	forgestep = -29
	
	end()

func randomMod():
	var rand = randi()%100
	var mod
	
	if rand < pBurn:
		mod = "Burn"
	elif rand < pFlow:
		mod = "Flow"
	elif rand < pStay:
		mod = "Stay"
	elif rand < pLink:
		mod = "Link"
	elif rand < pPush:
		mod = "Push"
	elif rand < pCopy:
		mod = "Copy"
	else:
		mod = "Void"
	return mod

func modColor(modstr):
	var new = ""
	if modstr == "Burn":
		new = "[r]"
	elif modstr == "Flow":
		new = "[color=#1aecfb]"
	elif modstr == "Stay":
		new = "[color=#27f30f]"
	elif modstr == "Link":
		new = "[color=#c2c2c2]"
	elif modstr == "Push":
		new = "[color=#ffcc01]"
	elif modstr == "Copy":
		new = "[color=#d314ff]"
	elif modstr == "Void":
		new = "[color=#ffffff]"
		
	return new + modstr + "[o]"

func disableButtons():
	get_node("leave/buttonLeave").visible = false
	get_node("forge/buttonBag").visible = false
	
func enableButtons():
	get_node("leave/buttonLeave").visible = true
	get_node("forge/buttonBag").visible = true
	
func _on_buttonLeave_pressed():
	Input.action_press("ui_down")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_down")

func _on_moveAreaLeave_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = true

func _on_moveAreaLeave_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = false


func _on_buttonBag_pressed():
	Input.action_press("bag")
	get_node("forge/buttonBag").disabled = true
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("bag")

func _on_buttonBag_button_down():
	get_node("forge/button_Forge").scale -= Vector2(0.007, 0.007)

func _on_buttonBag_button_up():
	get_node("forge/button_Forge").scale += Vector2(0.007, 0.007)
