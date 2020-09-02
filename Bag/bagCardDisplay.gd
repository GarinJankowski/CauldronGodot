extends Node2D

var Bag

var bagGearNodes = []

var startx
var endx

var stepx
var destx

var tabstartx
var tabendx
var tabstepx

var destweapon
var destarmor
var destheadgear

var stepweapon = 0
var steparmor = 0
var stepheadgear = 0

var tabhover = ""

var currentBack = "1"
var currentNode
var closeNode

onready var back = get_node("back")
onready var weapontab = get_node("noWeaponTab")
onready var armortab = get_node("noArmorTab")
onready var headgeartab = get_node("noHeadgearTab")

var Game

func init():
	Game = get_parent().get_parent().get_parent().Game
	Bag = Game.guy.Bag
	
	endx = back.position.x
	startx = 325
	back.position.x = startx
	back.visible = false
	destx = startx
	
	tabstartx = weapontab.position.x
	destweapon = tabstartx
	destarmor = tabstartx
	destheadgear = tabstartx
	tabendx = 0
	tabstepx = 10
	
	stepx = 72

func _process(delta):
	if back.position.x != destx:
		back.position.x += stepx
		if back.position.x == startx:
			back.visible = false
	if weapontab.position.x != destweapon:
		weapontab.position.x += stepweapon
		if weapontab.position.x == tabstartx:
			weapontab.visible = false
	if armortab.position.x != destarmor:
		armortab.position.x += steparmor
		if armortab.position.x == tabstartx:
			armortab.visible = false
	if headgeartab.position.x != destheadgear:
		headgeartab.position.x += stepheadgear
		if headgeartab.position.x == tabstartx:
			headgeartab.visible = false

func _input(event):
	if Bag.open && tabhover != "" && Input.is_action_just_released("RMB"):
		if tabhover == "noWeaponTab":
			Bag.noWeapon.removeAllMods()
		elif tabhover == "noArmorTab":
			Bag.noArmor.removeAllMods()
		elif tabhover == "noHeadgearTab":
			Bag.noHeadgear.removeAllMods()
		checkTabs()
		
func addBagCards(bagGear):
	var bagGearNode = Node2D.new()
	bagGearNode.set_name(bagGear.to_string())
	bagGearNode.visible = false
	bagGearNode.position = Vector2(10, -382)
	back.add_child(bagGearNode)
	bagGearNodes.append(bagGearNode)
	
	for i in bagGear.sideBagCardList.size():
		bagGearNode.add_child(bagGear.sideBagCardList[i])
		bagGear.sideBagCardList[i].position.y = i*40

func getBagGearNode(bagGear):
	for node in bagGearNodes:
		if node.name == bagGear.to_string().replace(":", ""):
			return node

func open(bagGear):
	for node in bagGearNodes:
		node.visible = false
	destx = endx
	stepx = -abs(stepx)
	back.visible = true
	currentNode = getBagGearNode(bagGear)
	currentNode.visible = true

func close():
	closeNode = currentNode
	destx = startx
	stepx = abs(stepx)

func checkTabs():
	if Bag.noWeapon.checkMods() && Bag.bagGearEquipped["Weapon"] != Bag.noWeapon:
		destweapon = tabendx
		weapontab.visible = true
		stepweapon = -tabstepx
		get_node("noWeaponTab/tabArea/CollisionShape2D").disabled = false
	else:
		destweapon = tabstartx
		stepweapon = tabstepx
		get_node("noWeaponTab/tabArea/CollisionShape2D").disabled = true
		
	if Bag.noArmor.checkMods() && Bag.bagGearEquipped["Armor"] != Bag.noArmor:
		destarmor = tabendx
		armortab.visible = true
		steparmor = -tabstepx
		get_node("noArmorTab/tabArea/CollisionShape2D").disabled = false
	else:
		destarmor = tabstartx
		steparmor = tabstepx
		get_node("noArmorTab/tabArea/CollisionShape2D").disabled = true
		
	if Bag.noHeadgear.checkMods() && Bag.bagGearEquipped["Headgear"] != Bag.noHeadgear:
		destheadgear = tabendx
		headgeartab.visible = true
		stepheadgear = -tabstepx
		get_node("noHeadgearTab/tabArea/CollisionShape2D").disabled = false
	else:
		destheadgear = tabstartx
		stepheadgear = tabstepx
		get_node("noHeadgearTab/tabArea/CollisionShape2D").disabled = true

func _on_tabArea_area_entered(area):
	if area.get_name() == "cursorArea":
		tabhover = get_parent().name
		if tabhover == "noWeaponTab":
			open(Bag.noWeapon)
		elif tabhover == "noArmorTab":
			open(Bag.noArmor)
		elif tabhover == "noHeadgearTab":
			open(Bag.noHeadgear)
		print_debug(tabhover)

func _on_tabArea_area_exited(area):
	if area.get_name() == "cursorArea":
		tabhover = ""
		close()
