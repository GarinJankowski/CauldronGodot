extends "res://Map/Room/Room.gd"

var gearName
var gearType

var gold

var runes = []

var scrollName

var cardName
var cardType
var card

func init2(x, y, gearT):
	roomName = gearT
	
	gearType = gearT
	var sprite = get_node("Sprite")
	if gearType == "Weapon":
		sprite.set_texture(preload("res://Map/Room/Room Icons/icon_RoomGearWeapon.png"))
	elif gearType == "Armor":
		sprite.set_texture(preload("res://Map/Room/Room Icons/icon_RoomGearArmor.png"))
	elif gearType == "Headgear":
		sprite.set_texture(preload("res://Map/Room/Room Icons/icon_RoomGearHeadgear.png"))
	
	init(x, y)
	
	itemgen.Runes(runes)
	gold = itemgen.Gold(x, y)
	
	events.append("Item")
	events.append("getGear")
	scrollEvent(x, y)
	itemEvent()
	
func scrollEvent(x, y):
	var chance
	if x+y < 30:
		chance = 15
	elif x+y < 34:
		chance = 8
	else:
		chance = -1
	
	if randi()%50 < chance:
		scrollName = itemgen.Scroll()
		events.append("Scroll")
		
func itemEvent():
	if getTierInt(x, y) > 1 && randi()%4 == 0:
		cardName = itemgen.ItemTurnedDevice()
		cardType = "Device"
		events.append("getCard")

func Enter():
	gearName = itemgen.Gear(gearType, x, y)
	EnterGeneral()

func enableAreaCollisions(truefalse):
	get_node("roomArea/CollisionShape2D").disabled = !truefalse

