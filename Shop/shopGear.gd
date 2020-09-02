extends Node2D

var guy
var gearName
var gearType
var removeList
var Bag

var ticks = 0
var cost
var purchased = false
var bagfullmessage = false

var Game

func init(gn, gt, val, list):
	Game = get_parent().get_parent().Game
	gearName = gn
	gearType = gt
	guy = Game.guy
	Bag = guy.Bag
	cost = val
	removeList = list
	
	get_node("cost/Label").text = str(cost) + "g"
	get_node("Top/gearType").set_texture(load("res://UI/Gear/" + gearType.to_lower() + "Icon.png"))
	get_node("Top/Label").text = gearName
	
	checkBuyable()

func _process(delta):
	if ticks > 0:
		get_node("Top").position.x += 45
		if ticks == 0:
			get_node("Top").visible = false

func checkBuyable():
	if purchased:
		get_node("cost").modulate = "7c7c7c"
	elif cost > guy.Gold:
		get_node("Top").modulate = "7c7c7c"
		get_node("cost").modulate = "7c7c7c"

func enableAreaCollisions(truefalse):
	get_node("cardArea/cardCollision").disabled = !truefalse

func _on_buttonCard_pressed():
	if cost <= guy.Gold:
		if len(guy.Bag.bagGearList) < guy.Bag.maxsize:
			guy.Bag.addGear(gearName)
			
			ticks = 15
			guy.gainGold(-cost)
			enableAreaCollisions(false)
			get_node("buttonCard").disabled = true
			get_parent().get_parent().updateShop()
			purchased = true
			
			var gearstr = ""
			if gearType == "Weapon":
				gearstr = "[b]"
			elif gearType == "Armor":
				gearstr = "[l]"
			elif gearType == "Headgear":
				gearstr = "[i]"
			gearstr += gearName + "[n]"
			guy.textlog.push("[G]You purchase the " + gearstr + "[G] and put it in your bag.")
		elif !bagfullmessage:
			guy.textlog.push("[r]Your bag is full.")
			bagfullmessage = true

func _on_cardArea_area_entered(area):
	if area.get_name() == "cursorArea" && cost <= guy.Gold:
		get_node("glow").visible = true
		get_node("cost/glow").visible = true

func _on_cardArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("glow").visible = false
		get_node("cost/glow").visible = false
