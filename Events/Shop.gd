extends "res://Events/Event.gd"

var stocklist = []

var ticks
var leavestep
var shopstep = 30
var goldstep = 10
var goldnode
var golddestx

func init2(r):
	init(r)
	
	ticks = 10
	leavestep = rand_range(0, 2) + 28
	textlog.push("[G]You come across a traveler selling their wares.")
	
	goldnode = guy.get_node("Control/Gold")
	golddestx = goldnode.rect_position.x
	get_node("shop").position.y += ticks*shopstep
	
	var itemdeviceCard = load("res://Card/Card.tscn").instance()
	add_child(itemdeviceCard)
	itemdeviceCard.init(itemgen.ShopItemTurnedDevice())
	itemdeviceCard.changeToDevice()
	var itemdevice = load("res://Shop/shopCard.tscn").instance()
	get_node("shop").add_child(itemdevice)
	itemdevice.init(itemdeviceCard, 2)
	itemdevice.position.x = 535
	
	var deviceCard = load("res://Card/Card.tscn").instance()
	add_child(deviceCard)
	var devicearray = itemgen.ShopDevice(r.x, r.y)
	var devicecost = 5
	if devicearray[1] == 2:
		devicecost = 8
	elif devicearray[1] == 3:
		devicecost = 12
	deviceCard.init(devicearray[0])
	var device = load("res://Shop/shopCard.tscn").instance()
	get_node("shop").add_child(device)
	device.init(deviceCard, devicecost)
	device.position.x = 355
	
	var itemCard = load("res://Card/Card.tscn").instance()
	add_child(itemCard)
	itemCard.init(itemgen.ShopItem())
	var item = load("res://Shop/shopCard.tscn").instance()
	get_node("shop").add_child(item)
	item.init(itemCard, 8)
	item.position.x = 175
	
	var geararray = itemgen.ShopGear(r.x, r.y)
	var gearcost = 10
	if geararray[2] == 3:
		gearcost = 15
	var gear = load("res://Shop/shopGear.tscn").instance()
	get_node("shop").add_child(gear)
	gear.init(geararray[0], geararray[1], gearcost, geararray[3])
	gear.position.x = -75
	
	stocklist.append(gear)
	stocklist.append(item)
	stocklist.append(device)
	stocklist.append(itemdevice)
	
	itemCard.queue_free()
	deviceCard.queue_free()
	itemdeviceCard.queue_free()

func _process(delta):
	if goldnode.rect_position.x != golddestx:
		goldnode.rect_position.x += 1
	if ticks > 0:
		get_node("leave").position.y -= leavestep
		get_node("shop").position.y -= shopstep
		goldnode.rect_position.x -= goldstep
		golddestx = goldnode.rect_position.x
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
	
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("ui_down") || Input.is_action_just_pressed("number_2"):
			end2()

func updateShop():
	goldnode.rect_position.x -= 15
	for stock in stocklist:
		stock.checkBuyable()

func end2():
	ticks = 10
	leavestep = randi()%3 - 30
	shopstep *= -1
	goldstep *= -1
	end()
	
func disableButtons():
	get_node("leave/buttonLeave").visible = false
	for stock in stocklist:
		stock.get_node("buttonCard").visible = false
		stock.enableAreaCollisions(false)
	
func enableButtons():
	get_node("leave/buttonLeave").visible = true
	for stock in stocklist:
		stock.get_node("buttonCard").visible = true
		stock.enableAreaCollisions(true)

func _on_moveAreaLeave_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = true

func _on_moveAreaLeave_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("leave/glow").visible = false

func _on_buttonLeave_pressed():
	Input.action_press("ui_down")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_down")
