extends "res://Map/Room/Room.gd"

var enemyName
var CombatInstance
var experience

func init2(x, y):
	roomName = "Combat"
	
	generateEnemy(x, y)
	spritepath = "res://Map/Room/Room Icons/Combat Room Icons/icon_RoomCombat_" + enemyName
	get_node("Sprite").set_texture(load(spritepath + ".png"))
		
	events.append("Combat")
	.init(x, y)

func Enter():
	EnterGeneral()

func neutralize():
	roomName = "Neutral"
	get_node("Sprite").modulate = "aaffffff"

func generateEnemy(px, py):
	var xp = {
		"A": 2,
		"B": 4,
		"C": 6,
		"D": 10,
		"E": 14,
		"F": 18
	}
	
	var m = get_parent()
	var x = px
	var y = py
	
	if (x == 1 && y == 0) || (x == 0 && y == 1) || (x == 1 && y == 1):
		enemyName = "Dummy"
		experience = 1
		return
	
	if randi()%5 < 2:
		if randi()%2 == 0:
			if getTier(px, py) == 'A':
				x += 1
			else:
				x += 3
		else:
			x -= 3
		
	var tier = getTier(x, y)
	var terrain = m.Terrain[px][py].terrain
	
	enemyName = m.enemyGeneration[tier][terrain][randi()%m.enemyGeneration[tier][terrain].size()]
	if enemyName == "Rat":
		experience = 1
	else:
		experience = xp[tier]

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse
