extends "res://Map/Room/Room.gd"

func init2(x, y):
	roomName = "Shop"
	
	events.append("Shop")
	init(x, y)

func Enter():
	EnterGeneral()

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse
