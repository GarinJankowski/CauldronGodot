extends "res://Map/Room/Room.gd"

var enemyName
var CombatInstance
var experience

var gearName
var gearType

var gold

var runes = []

var scrollName

var cardName
var cardType
var card

func init2(x, y):
	roomName = "Boss"
	
	generateBoss(x, y)
	spritepath = "res://Map/Room/Room Icons/Combat Room Icons/icon_RoomBoss_" + enemyName
		
	get_node("Sprite").set_texture(load(spritepath + ".png"))
		
	events.append("Combat")
	.init(x, y)
	
	
func Enter():
	EnterGeneral()

func generateBoss(x, y):
	var m = get_parent()
	var bossName
	var tier = getTier(x, y)
	var bosstier = "Boss "
	if tier == "A" || tier == "B":
		bosstier += "A"
	if tier == "C" || tier == "D":
		bosstier += "B"
	if tier == "E" || tier == "F":
		bosstier += "C"
	
	if m.enemyGeneration[bosstier].empty():
		m.bossGenerationSetup(bosstier)
	
	var rand = randi()%m.enemyGeneration[bosstier].size()

	enemyName = m.enemyGeneration[bosstier][rand]
	m.enemyGeneration[bosstier].remove(rand)
	
	experience = 10 + 5*getTierInt(x, y)
	if bosstier == "Boss A":
		gold = 5
	elif bosstier == "Boss B":
		gold = 8
	elif bosstier == "Boss C":
		gold = 12
	
	setBossRewards()
	
func setBossRewards():
	var enemyFile = File.new()
	enemyFile.open("res://Enemy/Enemy Sheet.txt", enemyFile.READ)
	var values
	
	while not enemyFile.eof_reached():
		var line = str(enemyFile.get_line())
		if line.begins_with(enemyName):
			values = line
			break
	enemyFile.close()
	
	values = Array(values.replace("\"", "").split("\t"))
	values = values.slice(8, values.size()-1, 1, false)
	
	gearName = values.pop_front()
	var gearFile = File.new()
	gearFile.open("res://Gear/Gear Sheet.txt", gearFile.READ)
	while not gearFile.eof_reached():
		var line = str(gearFile.get_line())
		if line.begins_with(gearName):
			gearType = line.replace("\"", "").split("\t")[1]
			break
	gearFile.close()
	
	runes = values.pop_front().split(", ")
	
	for item in values:
		if ": " in item:
			var itemvals = item.split(": ")
			if itemvals[0] == "Scroll":
				scrollName = "Scroll of " + itemvals[1]
			else:
				cardType = itemvals[0]
				cardName = itemvals[1]

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse
