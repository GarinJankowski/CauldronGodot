extends Node2D

var Game
var guy
var map
var itemgen
var textlog
var scriptgen
var mapSize = Vector2(550, 550)
var cursor

var roomInfo = {}
var terrainInfo = {}
var runeInfo = {}

func _ready():
	randomize()
	
	Game = self
	get_node("BackLayer").init()
	get_node("MapLayer").init()
	get_node("CharacterLayer").init()
	get_node("CursorLayer").init()
	cursor = get_node("CursorLayer/cursor")
	
	scriptgen = preload("res://ScriptGenerator.tscn").instance()
	add_child(scriptgen)
	
	textlog = preload("res://UI/TextLog.tscn").instance()
	get_node("BackLayer").add_child(textlog)
	
	guy = preload("res://Character/Character.tscn").instance()
	get_node("CharacterLayer").add_child(guy)
	
	itemgen = preload("res://Gear/ItemGeneration.tscn").instance()
	add_child(itemgen)
	
	map = preload("res://Map/Map.tscn").instance()
	get_node("MapLayer").add_child(map)
	
	scriptgen.init()
	textlog.init()
	guy.init()
	itemgen.init()
	map.init()
	
	map.position.x += 680
	textlog.position.x -= 670
	
	roomInfo = {
		"Gear": "Potentially useful equipment along with some runes and gold.",
		"Combat": "An encounter with a hostile being.",
		"Neutral": "An encounter with an impartial being.",
		"Boss": "An encounter with a being not unlike yourself.",
		"Final Boss": "An encounter with a greater being.",
		"Shop": "A traveling scavenger looking to sell their wares.",
		"Cauldron": "A structure filled with a strange liquid."
	}
	
	terrainInfo = {
		"Neutral": "Has no effect.",
		"City": "Has no effect.",
		"Field": "Has no effect.",
		"Hills": "You cannot see this tile unless it is directly ahead.",
		"Caves": "On this tile you must travel in the same direction traveled last.",
		"Forest": "On this tile you cannot travel in the same direction traveled last.",
		"Desert": "Combat provides a second stat upgrade and prevents post-combat healing.",
		"Wasteland": "Filled with mutated creatures. Cauldrons have twice the effect."
	}
	
	runeInfo = {
		"Burn": "When played, this card will be removed for the rest of combat.",
		"Flow": "If this card is in your hand at the end of your turn, discard it for 1 turn.",
		"Link": "Playing this card will draw a card with this Link value plus one. This rune can be stacked.",
		"Void": "This card cannot be drawn by any means.",
		"Push": "Playing this card discards all cards in hand for 3 turns.",
		"Copy": "There will be an additional copy of this card in your deck during combat.",
		"Stay": "Burning or discarding this card will instead pay one Stay for the rest of combat. This rune can be stacked."
	}

func setGlobals(scene):
	scene.scriptgen = scriptgen
	scene.textlog = textlog
	scene.guy = guy
	scene.itemgen = itemgen
	scene.map = map

func tileTooltip(truefalse, room = null, terrain = null, mapbottom = false):
	if !map.mapHover || guy.Bag.open || guy.Body.open:
		cursor.get_node("roomTooltip").visible = false
		cursor.get_node("terrainTooltip").visible = false
		cursor.get_node("youTooltip").visible = false
	elif room == null && terrain == null:
		cursor.get_node("roomTooltip").visible = true
		cursor.get_node("terrainTooltip").visible = true
	elif truefalse:
		var roomPos = 182
		var terrainPos = 278
		var pos = Vector2(0, 0)
		if room == null || room.roomName == "None" || (terrain != null && terrain.tempFogged && terrain.fogged):
			if terrain != null:
				pos = Vector2(terrain.x, terrain.y)
			cursor.get_node("roomTooltip").visible = false
			terrainPos -= 96
		else:
			pos = Vector2(room.x, room.y)
			cursor.get_node("roomTooltip").visible = true
			var roomName = room.roomName
			if roomName == "Weapon" || roomName == "Armor" || roomName == "Headgear":
				roomName = "Gear"
			cursor.get_node("roomTooltip/Label/Name").text = roomName
			cursor.get_node("roomTooltip/Description").text = roomInfo[roomName]
			cursor.get_node("roomTooltip/Icon/pic").set_texture(room.spriteTexture)
			if roomName == "Neutral":
				cursor.get_node("roomTooltip/Icon/pic").modulate = "aaffffff"
			else:
				cursor.get_node("roomTooltip/Icon/pic").modulate = "ffffff"
		
		if terrain != null:
			cursor.get_node("terrainTooltip").visible = true
			cursor.get_node("terrainTooltip/Label/Name").text = terrain.terrain
			cursor.get_node("terrainTooltip/Description").text = terrainInfo[terrain.terrain]
			cursor.get_node("terrainTooltip/Icon/pic").set_texture(terrain.spriteTexture)
			
		if pos == Vector2(guy.posx, guy.posy):
			roomPos += 26
			terrainPos += 26
			if !mapbottom:
				cursor.get_node("youTooltip").visible = true
		else:
			cursor.get_node("youTooltip").visible = false
		
		cursor.get_node("roomTooltip").position.y = roomPos
		cursor.get_node("terrainTooltip").position.y = terrainPos

func runeTooltip(truefalse, rune = null):
	if truefalse:
		cursor.get_node("runeTooltip").visible = true
		cursor.get_node("runeTooltip/Icon/pic").set_texture(load("res://Modifiers/mod_" + rune + ".png"))
		cursor.get_node("runeTooltip/Label/Name").text = rune
		cursor.get_node("runeTooltip/Description").text = runeInfo[rune]
	else:
		cursor.get_node("runeTooltip").visible = false

func effectTooltip(truefalse, effect = null):
	cursor.get_node("effectGoodTooltip").visible = false
	cursor.get_node("effectBadTooltip").visible = false
	if truefalse && effect != null:
		var goodbad = "Bad"
		if effect.good:
			goodbad = "Good"
		cursor.get_node("effect" + goodbad + "Tooltip").visible = true
		cursor.get_node("effect" + goodbad + "Tooltip/Label/Name").text = effect.displayName
		cursor.get_node("effect" + goodbad + "Tooltip/Description").text = effect.displayTurns
		if effect.displayTurns != "":
			cursor.get_node("effect" + goodbad + "Tooltip/whitesquare").scale.y = 1
			cursor.get_node("effect" + goodbad + "Tooltip/whitesquare").position.y = 8
		else:
			cursor.get_node("effect" + goodbad + "Tooltip/whitesquare").scale.y = 0.59
			cursor.get_node("effect" + goodbad + "Tooltip/whitesquare").position.y = -55
