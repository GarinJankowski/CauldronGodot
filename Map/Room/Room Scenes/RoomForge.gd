extends "res://Map/Room/Room.gd"

func init2(x, y):
	roomName = "Forge"
	
	events.append("Forge")
	init(x, y)

func Enter():
	EnterGeneral()
