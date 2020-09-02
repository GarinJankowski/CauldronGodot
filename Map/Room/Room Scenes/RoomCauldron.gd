extends "res://Map/Room/Room.gd"

var Body

func init2(x, y):
	roomName = "Cauldron"
	
	events.append("Cauldron")
	init(x, y)
	Body = guy.Body

func Enter():
	if map.currentTerrainEquals("Wasteland"):
		events.append("Cauldron")
	EnterGeneral()

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse
