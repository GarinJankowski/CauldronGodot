extends "res://Map/Room/Room.gd"

var enemyName
var CombatInstance
var experience = 0

func init2(x, y):
	generateFinalBoss()
	roomName = "Final Boss"
	
	spritepath = "res://Map/Room/Room Icons/Combat Room Icons/icon_FinalBoss_" + enemyName
	
	get_node("Sprite").set_texture(load(spritepath + ".png"))
		
	events.append("Combat")
	events.append("Win")
	.init(x, y)
	
func Enter():
	EnterGeneral()

func generateFinalBoss():
	enemyName = get_parent().enemyGeneration["Final Boss"]

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse
