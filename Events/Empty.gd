extends "res://Events/Event.gd"

var scrollTeleportation = false
var teleportDirection = ""
var scrollHealing = false
var scrollSight = false
var scrollTime = false

var ticks = 0
var wherestep = 0
var upstep = 0
var scrollstep = 0
var rightstep = 0

func init2(r):
	init(r)
	checkScrolls()
	
	ticks = 10
	
	wherestep = rand_range(0, 1) + 28
	if map.canMoveUp:
		upstep = rand_range(0, 2) + 28
	else:
		get_node("right").position.x -= 65
		get_node("up").visible = false
		
	if map.canMoveRight:
		rightstep = rand_range(0, 2) + 28
	else:
		get_node("up").position.x += 65
		get_node("right").visible = false
		
	scrollstep = 29
	
	get_node("where").rotation_degrees = rand_range(-2, 2)
	get_node("up").rotation_degrees = rand_range(-4, 4)
	get_node("right").rotation_degrees = rand_range(-4, 4)
	
	if scrollTeleportation:
		get_node("teleportation").visible = true
		get_node("teleportation").rotation_degrees = rand_range(-2, 2)
		get_node("healing").position.x -= 170
		get_node("sight").position.x -= 170
		get_node("time").position.x -= 170
	if scrollHealing:
		get_node("healing").visible = true
		get_node("healing").rotation_degrees = rand_range(-2, 2)
		get_node("sight").position.x -= 170
		get_node("time").position.x -= 170
	if scrollSight:
		get_node("sight").visible = true
		get_node("sight").rotation_degrees = rand_range(-2, 2)
		get_node("time").position.x -= 170
	if scrollTime:
		get_node("time").visible = true
		get_node("time").rotation_degrees = rand_range(-2, 2)

func _process(delta):
	if ticks > 0:
		get_node("where").position.y -= wherestep
		get_node("up").position.y -= upstep
		get_node("right").position.y -= rightstep
		
		if scrollTeleportation:
			get_node("teleportation").position.y -= scrollstep
		if scrollHealing:
			get_node("healing").position.y -= scrollstep
		if scrollSight:
			get_node("sight").position.y -= scrollstep
		if scrollTime:
			get_node("time").position.y -= scrollstep
		ticks -= 1
		if ticks == 0 && close:
			queue_free()
			#room.queue_free_Events()
	
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("ui_up") && guy.posy < map.gridHeight-1 && map.canMoveUp:
			moveCharacter("up")
		elif (Input.is_action_just_pressed("ui_right")) && guy.posx < map.gridWidth-1 && map.canMoveRight:
			moveCharacter("right")

func moveCharacter(direction):
	ticks = 10
	wherestep = randi()%3 - 30
	upstep = randi()%3 - 30
	scrollstep = -29
	rightstep = randi()%3 - 30
	
	guy.previousX = guy.posx
	guy.previousY = guy.posy
	if direction == "up":
		guy.posy += 1
		map.lastMoved = "up"
	elif direction == "right":
		guy.posx += 1
		map.lastMoved = "right"
	map.updateCharacterPosition()
	
	room.get_node("Sprite").z_index = 14
	close = true
	
func teleportCharacter(direction):
	ticks = 10
	wherestep = randi()%3 - 30
	upstep = randi()%3 - 30
	scrollstep = -29
	rightstep = randi()%3 - 30
	
	guy.previousX = guy.posx
	guy.previousY = guy.posy
	if direction == "up":
		guy.posy += 1
		map.lastMoved = ""
	elif direction == "right":
		guy.posx += 1
		map.lastMoved = ""
	map.updateCharacterPosition()
	
	room.get_node("Sprite").z_index = 14
	close = true

func removeScrolls():
	if !guy.Bag.hasScroll("Scroll of Teleportation"):
			scrollTeleportation = true
			get_node("teleportation").visible = false
	if !guy.Bag.hasScroll("Scroll of Healing"):
			scrollHealing = true
			get_node("healing").visible = false
	if !guy.Bag.hasScroll("Scroll of Sight"):
			scrollSight = true
			get_node("sight").visible = false
	if !guy.Bag.hasScroll("Scroll of Time"):
			scrollTime = true
			get_node("time").visible = false
		

func checkScrolls():
	if guy.Bag.hasScroll("Scroll of Teleportation") && (map.currentTerrainEquals("Caves") || map.currentTerrainEquals("Forest")):
		if !map.canMoveUp && guy.posy < map.gridHeight-1:
			scrollTeleportation = true
			teleportDirection = "up"
			get_node("teleportation/Label").text = "Move Up"
		elif !map.canMoveRight && guy.posx < map.gridWidth-1:
			scrollTeleportation = true
			teleportDirection = "right"
			get_node("teleportation/Label").text = "Move Right"
			
	if guy.Bag.hasScroll("Scroll of Healing") && !guy.statsRestored && map.currentTerrainEquals("Desert") && (room.x+1 < map.gridWidth && (map.getTerrain(room.x+1, room.y) == "Desert") || (room.y+1 < map.gridHeight && map.getTerrain(room.x, room.y+1) == "Desert")):
		scrollHealing = true
	
	if guy.Bag.hasScroll("Scroll of Sight"):
		for x in 4:
			for y in 4:
				if !(x == 1 && y == 0) && !(y == 1 && x == 0) && guy.posx+x < map.gridWidth && guy.posy+y < map.gridHeight:
					if map.Terrain[guy.posx+x][guy.posy+y].fogged:
						scrollSight = true
						break;
	if guy.Bag.hasScroll("Scroll of Time"):
		for x in 4:
			for y in 4:
				if guy.posx+x < map.gridWidth && guy.posy+y < map.gridHeight:
					if map.Terrain[guy.posx+x][guy.posy+y].terrain == "Wasteland":
						scrollTime = true
						break;

func scrollFunction(function):
	var text = "You read the scroll. "
	if function == "teleportation":
		if teleportDirection == "up":
			teleportCharacter("up")
			text += "You teleport upward."
		elif teleportDirection == "right":
			teleportCharacter("right")
			text += "You teleport rightward."
	elif function == "healing":
		guy.restoreStats()
		text += "Your body feels refreshed."
	elif function == "sight":
		for x in 4:
			for y in 4:
				if guy.posx+x < map.gridWidth && guy.posy+y < map.gridHeight:
					if map.Terrain[guy.posx+x][guy.posy+y].terrain == "Hills":
						map.Terrain[guy.posx+x][guy.posy+y].unfog()
		text += "You see ahead."
	elif function == "time":
		for x in 4:
			for y in 4:
				if guy.posx+x < map.gridWidth && guy.posy+y < map.gridHeight:
					if map.Terrain[guy.posx+x][guy.posy+y].terrain == "Wasteland":
						var room = map.Rooms[guy.posx+x][guy.posy+y]
						if room.roomName == "Combat":
							room.neutralize()
						map.Terrain[guy.posx+x][guy.posy+y].changeTerrain("Field")
		text += "The waste withdraws."
	textlog.push("[s]" + text)
						
func disableButtons():
	get_node("up/buttonMoveUp").visible = false
	get_node("right/buttonMoveRight").visible = false
	get_node("teleportation/buttonTeleportation").visible = false
	get_node("healing/buttonHealing").visible = false
	get_node("sight/buttonSight").visible = false
	get_node("time/buttonTime").visible = false
	
func enableButtons():
	get_node("up/buttonMoveUp").visible = true
	get_node("right/buttonMoveRight").visible = true
	get_node("teleportation/buttonTeleportation").visible = true
	get_node("healing/buttonHealing").visible = true
	get_node("sight/buttonSight").visible = true
	get_node("time/buttonTime").visible = true

func _on_buttonMoveRight_pressed():
	Input.action_press("ui_right")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_right")


func _on_buttonMoveUp_pressed():
	Input.action_press("ui_up")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("ui_up")


func _on_moveAreaRight_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("right/glow").visible = true


func _on_moveAreaRight_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("right/glow").visible = false


func _on_moveAreaUp_area_entered(area):
	if area.get_name() == "cursorArea":
		get_node("up/glow").visible = true


func _on_moveAreaUp_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("up/glow").visible = false


func _on_buttonTeleportation_pressed():
	get_node("teleportation").visible = false
	get_node("teleportation/scrollArea/CollisionShape2D").disabled = true
	scrollFunction("teleportation")
	guy.Bag.destroyScroll("Scroll of Teleportation")

func _on_buttonHealing_pressed():
	get_node("healing").visible = false
	get_node("healing/scrollArea/CollisionShape2D").disabled = true
	scrollFunction("healing")
	guy.Bag.destroyScroll("Scroll of Healing")

func _on_buttonSight_pressed():
	get_node("sight").visible = false
	get_node("sight/scrollArea/CollisionShape2D").disabled = true
	scrollFunction("sight")
	guy.Bag.destroyScroll("Scroll of Sight")
	
func _on_buttonTime_pressed():
	get_node("time").visible = false
	get_node("time/scrollArea/CollisionShape2D").disabled = true
	scrollFunction("time")
	guy.Bag.destroyScroll("Scroll of Time")

