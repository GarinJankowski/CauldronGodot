extends Node2D

var guy
var itemgen
var roomName
var x
var y
var clear = false
var terrain

var events = []
var eventindex = -1

var eventsList = []

onready var spriteTexture
onready var spriteTextureCLEAR
var spritepath = "N/A"
var map
var textlog

var Game

func init(px, py):
	Game = get_parent().Game
	z_index = 9
	map = Game.map
	textlog = Game.textlog
	guy = Game.guy
	itemgen = Game.itemgen
	x = px
	y = py
	spriteTexture = get_node("Sprite").texture
	get_node("Sprite").scale = Vector2(0.051, 0.051)
	
	if roomName == "Boss" && getTier(x, y) != "B":
		pass
	else:
		var spath = get_node("Sprite").texture.resource_path
		spritepath = spath.substr(0, len(spath)-4)
		if spritepath != "N/A":
			spriteTextureCLEAR = load(spritepath + "CLEAR.png")
	terrain = map.Terrain[x][y]
	if terrain == null:
		print_debug(roomName)

func EnterGeneral():
	map.currentRoom = self
	map.get_node("Room/roomIcon").set_texture(spriteTexture)
	map.get_node("Room/roomLabel").text = roomName
	nextEvent()

func nextEvent():
	eventindex += 1
	if eventindex >= len(events):
		roomClear()
	else:
		var newevent = map.eventDict[events[eventindex]].instance()
		guy.add_child(newevent)
		newevent.init2(self)
		eventsList.append(newevent)

func getSize():
	return spriteTexture.get_size()*scale
	
func roomClear():
	map.Terrain[x][y].roomClear()
	
	if spritepath != "N/A":
		get_node("Sprite").modulate = "222222"
		#get_node("Sprite").set_texture(spriteTextureCLEAR)
	clear = true
	
	var empty = load("res://Events/Empty.tscn").instance()
	guy.add_child(empty)
	empty.init2(self)
	eventsList.append(empty)

func queue_free_Events():
	print_debug(x)
	print_debug(y)
	for e in eventsList:
		if e != null:
			e.queue_free()

func getTier(px, py):
	var t = px+py
	var tier
	
	if t <= 6:
		tier = 'A'
	elif t <= 11:
		tier = 'B'
	elif t <= 18:
		tier = 'C'
	elif t <= 25:
		tier = 'D'
	elif t <= 32:
		tier = 'E'
	else:
		tier = 'F'
	
	return tier
	
func getTierInt(px, py):
	var t = px+py
	var tier
	
	if t <= 5:
		tier = 1
	elif t <= 11:
		tier = 2
	elif t <= 18:
		tier = 3
	elif t <= 25:
		tier = 4
	elif t <= 32:
		tier = 5
	else:
		tier = 6
	
	return tier
