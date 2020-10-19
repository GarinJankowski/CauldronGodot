extends Node2D

var guy
var gridWidth = 20
var gridHeight = 20

onready var guySprite = get_node("CharacterSprite")
var positionX
var positionY
var Rooms = []
var Terrain = []
var terrainStrings = []
var wastelandLocations = []

var roomEmpty = preload("res://Map/Room/Room Scenes/RoomEmpty.tscn")
var roomGear = preload("res://Map/Room/Room Scenes/RoomGear.tscn")
var roomCauldron = preload("res://Map/Room/Room Scenes/RoomCauldron.tscn")
var roomShop = preload("res://Map/Room/Room Scenes/RoomShop.tscn")
var roomCombat = preload("res://Map/Room/Room Scenes/RoomCombat.tscn")
var roomBoss = preload("res://Map/Room/Room Scenes/RoomBoss.tscn")
var roomFinalBoss = preload("res://Map/Room/Room Scenes/RoomFinalBoss.tscn")

var terrainPreload = preload("res://Map/Terrain/Terrain.tscn")

var enemiesTier1 = {}
var enemiesTier2 = {}
var enemiesTier3 = {}
var enemiesTier4 = {}
var enemiesTier5 = {}
var enemiesTier6 = {}
var bossesA = []
var bossesB = []
var bossesC = []

var enemyGeneration = {
	"A": enemiesTier1,
	"B": enemiesTier2,
	"C": enemiesTier3,
	"D": enemiesTier4,
	"E": enemiesTier5,
	"F": enemiesTier6,
	"Boss A": bossesA,
	"Boss B": bossesB,
	"Boss C": bossesC,
	"Final Boss": ""
}

var eventDict = {
	"Empty": preload("res://Events/Empty.tscn"),
	"Combat": preload("res://Events/Combat.tscn"),
	"Stat": preload("res://Events/Stat.tscn"),
	"LevelUp": preload("res://Events/LevelUp.tscn"),
	"getGear": preload("res://Events/getGear.tscn"),
	"Scroll": preload("res://Events/Scroll.tscn"),
	"getCard": preload("res://Events/getCard.tscn"),
	"Item": preload("res://Events/Item.tscn"),
	"Cauldron": preload("res://Events/Cauldron.tscn"),
	"Shop": preload("res://Events/Shop.tscn"),
	"Win": preload("res://Events/Win.tscn")
}

var roomSize

var currentRoom
var currentTerrain
var currentEvent
var canMoveUp = true
var canMoveRight = true
var canMoveDown = false
var lastMoved = ""
var mapHover = false

var textlog
var itemgen
var Game
	
#init
func init():
	Game = get_parent().Game
	guy = Game.guy
	textlog = Game.textlog
	itemgen = Game.itemgen
	
	scale = Vector2(0.95,0.95)
	positionX = guySprite.position.x
	positionY = guySprite.position.y
	roomSize = guySprite.get_node("CharacterSprite").texture.get_size()*guySprite.get_node("CharacterSprite").scale
	generateFinalBoss()
	enemyGenerationSetup()
	bossGenerationSetup("")
	generateMap()
	updateCharacterPosition()

func generateFinalBoss():
	var enemyFile = File.new()
	enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
	
	var finalbosses = []
	while not enemyFile.eof_reached():
		var values = enemyFile.get_line().replace("\"", "").split("\t")
		if values[0] != "" && values[1] == "Final Boss":
			finalbosses.append(values[0])
	enemyGeneration["Final Boss"] = finalbosses[randi()%finalbosses.size()]

func enemyGenerationSetup():
	var terrainarray = ["Field", "Forest", "Caves", "Hills", "Desert", "Wasteland", "City"]
	for key in enemyGeneration:
		if !key.begins_with("Boss") && key != "Final Boss":
			for terrain in terrainarray:
				enemyGeneration[key][terrain] = []
				
	var enemyFile = File.new()
	enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
	
	while not enemyFile.eof_reached():
		var values = enemyFile.get_line().replace("\"", "").split("\t")
		if values[0] != "Name" && values[0] != "" && !values[1].begins_with("Boss") && values[1] != "Final Boss" && values[1] != "N/A":
			var terrains = (values[8] + ", Field, Wasteland, City").split(", ")
			for terr in terrains:
				if terr != "N/A":
					enemyGeneration[values[1]][terr].append(values[0])
			
	enemyFile.close()

func bossGenerationSetup(bosstier):
	var enemyFile = File.new()
	enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
	
	while not enemyFile.eof_reached():
		var values = enemyFile.get_line().replace("\"", "").split("\t")
		if values[0] != "" && ((bosstier == "" && values[1].begins_with("Boss")) || values[1] == bosstier) :
			enemyGeneration[values[1]].append(values[0])
		
	enemyFile.close()

func updateCharacterPosition():
	var x = guy.posx
	var y = guy.posy
	
	canMoveUp = true
	canMoveRight = true
	
	if x >= gridWidth-1:
		canMoveRight = false
	if y >= gridHeight-1:
		canMoveUp = false
	
	guySprite.position = Rooms[x][y].position
	updateFog()
	Terrain[x][y].Enter()
	if !currentTerrainEquals("Desert"):
		guy.restoreStats()
	Rooms[x][y].Enter()
	
	if currentTerrainEquals("Forest"):
		if lastMoved == "up" && canMoveRight:
			canMoveUp = false
		elif lastMoved == "right" && canMoveUp:
			canMoveRight = false
	elif currentTerrainEquals("Caves"):
		if lastMoved == "up" && canMoveUp:
			canMoveRight = false
		elif lastMoved == "right" && canMoveRight:
			canMoveUp = false

func showScrollIndicator(truefalse):
	get_node("CharacterSprite/scroll_indicator").visible = truefalse

func currentTerrainEquals(terr):
	if currentTerrain.terrain == terr:
		return true
	return false
	
func getTerrain(x, y):
	return Terrain[x][y].terrain

#calls all the methods to generate the entire map
func generateMap():
	generateTerrain()
	generateRooms()

func generateTerrain():
	terrainStrings = []
	for x in range(gridWidth):
		terrainStrings.append([])
		terrainStrings[x] = []
		for y in range(gridHeight):
			terrainStrings[x].append([])
			terrainStrings[x][y] = "Hills"
			
	for i in range(5):
		if randi()%2 == 0:
			generateCity()
			
	for i in range(14):
		if randi()%4 > 1:
			generateSingleTerrain("Caves")
		if randi()%3 > 1:
			generateSingleTerrain("Forest")
		if randi()%6 == 0:
			generateSingleTerrain("Desert")
		if randi()%7 > 5:
			generateSingleTerrain("Wasteland")
			
	for i in range(12):
		generateSingleTerrain("Caves")
		generateSingleTerrain("Forest")
	for i in range(3):
		generateSingleTerrain("Wasteland")
	
	generateSingleTerrain("Desert")
	generateSingleTerrain("Desert")
	generateSingleTerrain("Desert")
	
	var iter = 5
	if randi()%4 == 0:
		if randi()%2 == 0:
			iter += 1
			if randi()%15 == 0:
				iter += 1
		else:
			iter -= 1
			if randi()%15 == 0:
				iter -= 1
				
	for i in range(iter):
		for x in range(gridWidth):
			for y in range(gridHeight):
				generateSurroundingTerrain(x, y)
				
	for i in range(8):
		if randi()%2 > 0:
			generateCity()
			
	for x in range(gridWidth):
		for y in range(gridHeight):
			if randi()%10 == 0:
				terrainStrings[x][y] = "Hills"
	
#	for x in 3:
#		for y in 3:
#			terrainStrings[gridWidth-x-1][gridHeight-y-1] = "City"
	for x in 3:
		for y in 3:
			terrainStrings[x][y] = "Field"
	
	for x in range(gridWidth):
		Terrain.append([])
		Terrain[x] = []
		for y in range(gridHeight):
			Terrain[x].append([])
			Terrain[x][y] = terrainPreload.instance()
			add_child(Terrain[x][y])
			Terrain[x][y].init(x, y, terrainStrings[x][y])
			Terrain[x][y].position = Vector2(positionX + (roomSize.x*x), positionY - (roomSize.y*y))
			
func generateSingleTerrain(terr):
	var randx = randi()%gridWidth
	var randy = randi()%gridHeight
	
	if terrainStrings[randx][randy] != "Hills" || (randx == 0 && randy == 0) || (randx == gridWidth-1 && randy == gridHeight-1) || (terr == "Forest" && randx+randy < 7) || (terr == "Wasteland" && (randx+randy > 30 || randx+randy < 10)):
		generateSingleTerrain(terr)
	else:
		terrainStrings[randx][randy] = terr
		if terr == "Wasteland":
			wastelandLocations.append(Vector2(randx, randy))

func generateSurroundingTerrain(x, y):
	var terr
	if terrainStrings[x][y] != "Hills" && terrainStrings[x][y] != "City":
		terr = terrainStrings[x][y]
		var chance = 17
		if terr == "Desert":
			chance += 0 + randi()%2
		elif terr == "Forest":
			chance += 2 + randi()%2
		elif terr == "Caves":
			chance += 2 + randi()%2
		elif terr == "Wasteland":
			chance += 1 + randi()%2
			
		if x > 0 && randi()%25 > chance:
			terrainStrings[x-1][y] = terr
		if y > 0 && randi()%25 > chance:
			terrainStrings[x][y-1] = terr
		if x < gridWidth-1 && randi()%25 > chance:
			terrainStrings[x+1][y] = terr
		if y < gridHeight-1 && randi()%25 > chance:
			terrainStrings[x][y+1] = terr

func generateCity():
	return
	var posx = randi()%gridWidth
	var posy = randi()%gridHeight
	
	var sizevect = generateCityXY(posx, posy)
	
	if randi()%2 == 0:
		generateCityXY(randi()%int(sizevect.x) + posx + 1, randi()%int(sizevect.y) + posy + 1)
				
func generateCityXY(posx, posy):
	return
	var sizex = randi()%4+2
	var sizey = randi()%4+2
	
	if randi()%20 == 0:
		sizex += 1
		if randi()%40 == 0:
			sizex += 1
			if randi()%40 == 0:
				sizex += 1
				
	if randi()%20 == 0:
		sizey += 1
		if randi()%40 == 0:
			sizey += 1
			if randi()%40 == 0:
				sizey += 1
	
	if posx + sizex > gridWidth-1:
		posx = gridWidth-sizex-1
	if posy + sizey > gridHeight-1:
		posy = gridHeight-sizey-1
	
	for x in range(sizex):
		var x2 = x+posx
		for y in range(sizey):
			var y2 = y+posy
			if x2 > 1 || y2 > 1:
				terrainStrings[x2][y2] = "City"
	
	return Vector2(sizex, sizey)

#assigns room values to the Rooms array, generating the room portion of the map
func generateRooms():
	for x in range(gridWidth):
		Rooms.append([])
		Rooms[x] = []
		for y in range(gridHeight):
			Rooms[x].append([])
			Rooms[x][y] = generateRoom(x, y)
			Rooms[x][y].position = Terrain[x][y].position
			Rooms[x][y].position = Vector2(positionX + (roomSize.x*x), positionY - (roomSize.y*y))
			if x == gridWidth-1 && y == gridHeight-1:
				Rooms[x][y].position += Vector2(roomSize.x/8, -roomSize.y/8)
			
#generates an individual room based off of its location on the grid
func generateRoom(x, y):
	var room
	if x == 0 && y == 0:
		room = roomEmpty.instance()
		add_child(room)
		room.init2(x, y)
	elif x == gridWidth-1 && y == gridHeight-1:
		room = roomFinalBoss.instance()
		add_child(room)
		room.init2(x, y)
	else:
		var roomFile = File.new()
		roomFile.open("res://Map/Room Sheet.txt", roomFile.READ)
		
		while not roomFile.eof_reached():
			var line = str(roomFile.get_line())
			if line.begins_with(getTier(x, y)):
				room = generateRoomFromLine(line, x, y)
				break
		roomFile.close()
		
	return room
	
func generateRoomFromLine(line, x, y):
	var values = line.split("\t")
	var numCombat = float(values[1])
	
	var numWeapon = float(values[2]) + numCombat
	var numArmor = float(values[3]) + numWeapon
	var numHeadgear = float(values[4]) + numArmor
	
	var numCauldron = float(values[5]) + numHeadgear
	var numShop = float(values[6]) + numCauldron
	
	var numBoss = float(values[7]) + numShop
	
	var room
	var rand = randi()%100
	if checkWasteland(x, y):
		if checkLowerTwoRooms(x, y, "@RoomCauldron"):
			room = roomBoss.instance()
		else:
			room = roomCauldron.instance()
		add_child(room)
		room.init2(x, y)
	elif rand < numCombat || terrainStrings[x][y] == "Wasteland":
		room = roomCombat.instance()
		add_child(room)
		room.init2(x, y)
	elif rand < numWeapon:
		if checkLowerTwoRooms(x, y, "@RoomGear") && randi()%2 > 0:
			room = roomCombat.instance()
			add_child(room)
			room.init2(x, y)
		else:
			room = roomGear.instance()
			add_child(room)
			room.init2(x, y, "Weapon")
	elif rand < numArmor:
		if checkLowerTwoRooms(x, y, "@RoomGear") && randi()%2 > 0:
			room = roomCombat.instance()
			add_child(room)
			room.init2(x, y)
		else:
			room = roomGear.instance()
			add_child(room)
			room.init2(x, y, "Armor")
	elif rand < numHeadgear:
		if checkLowerTwoRooms(x, y, "@RoomGear") && randi()%2 > 0:
			room = roomCombat.instance()
			add_child(room)
			room.init2(x, y)
		else:
			room = roomGear.instance()
			add_child(room)
			room.init2(x, y, "Headgear")
	elif rand < numCauldron:
		if checkLowerTwoRooms(x, y, "@RoomCauldron"):
			room = roomBoss.instance()
		else:
			room = roomCauldron.instance()
		add_child(room)
		room.init2(x, y)
	elif rand < numShop:
		if checkLowerTwoRooms(x, y, "@RoomShop") || (y > 0 && x > 0 && Rooms[x-1][y-1].name.begins_with("@RoomShop")) || (x > 0 && y < gridHeight-1 && Rooms[x-1][y+1].name.begins_with("@RoomShop")):
			room = roomCombat.instance()
		else:
			room = roomShop.instance()
		add_child(room)
		room.init2(x, y)
	elif rand < numBoss:
		if checkLowerTwoRooms(x, y, "@RoomBoss"):
			room = roomCombat.instance()
		else:
			room = roomBoss.instance()
		add_child(room)
		room.init2(x, y)
	else:
		room = roomEmpty.instance()
		add_child(room)
		room.init2(x, y)
		
	return room
	
func checkLowerTwoRooms(x, y, roomName):
	if (y > 0 && Rooms[x][y-1].name.begins_with(roomName)) || (x > 0 && Rooms[x-1][y].name.begins_with("roomName")):
		return true
	return false

func checkWasteland(x, y):
	for vect in wastelandLocations:
		if vect == Vector2(x, y):
			return true
	return false

func updateFog():
	for x in range(3):
		for y in range(3):
			var gx = guy.posx+x-1
			var gy = guy.posy+y-1
			
			if gx >= 0 && gx <= gridWidth-1 && gy >= 0 && gy <= gridHeight-1:
				if (x == 1 && y == 2) || (y == 1 && x == 2) || Rooms[gx][gy].clear:
					Terrain[gx][gy].fog(false)
				else:
					Terrain[gx][gy].fog(true)

func getTier(x, y):
	var t = x+y
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

func setCurrentEvent(event):
	currentEvent = event


func _on_mapArea_area_entered(area):
	if area.get_name() == "cursorArea":
		mapHover = true
		Game.tileTooltip(true)

func _on_mapArea_area_exited(area):
	if area.get_name() == "cursorArea":
		mapHover = false
		Game.tileTooltip(false)

func _on_roomArea_area_entered(area):
	if area.get_name() == "cursorArea":
		mapHover = true
		Game.tileTooltip(true, currentRoom, null, true)

func _on_roomArea_area_exited(area):
	if area.get_name() == "cursorArea":
		mapHover = false
		Game.tileTooltip(false)

func _on_terrainArea_area_entered(area):
	if area.get_name() == "cursorArea":
		mapHover = true
		Game.tileTooltip(true, null, currentTerrain, true)

func _on_terrainArea_area_exited(area):
	if area.get_name() == "cursorArea":
		mapHover = false
		Game.tileTooltip(false)
