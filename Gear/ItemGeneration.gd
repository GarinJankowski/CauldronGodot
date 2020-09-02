extends Node

var guy
var map

var weaponGenerationTier1 = []
var weaponGenerationTier2 = []
var weaponGenerationTier3 = []

var armorGenerationTier1 = []
var armorGenerationTier2 = []
var armorGenerationTier3 = []

var headgearGenerationTier1 = []
var headgearGenerationTier2 = []
var headgearGenerationTier3 = []

var gearGenerationTier1 = {
	"Weapon": weaponGenerationTier1,
	"Armor": armorGenerationTier1
}

var gearGenerationTier2 = {
	"Weapon": weaponGenerationTier2,
	"Armor": armorGenerationTier2,
	"Headgear": headgearGenerationTier2
}

var gearGenerationTier3 = {
	"Weapon": weaponGenerationTier3,
	"Armor": armorGenerationTier3,
	"Headgear": headgearGenerationTier3
}

var gearGeneration = [gearGenerationTier1, gearGenerationTier2, gearGenerationTier3]

var deviceGenerationTier1 = []
var deviceGenerationTier2 = []
var deviceGenerationTier3 = []

var deviceGeneration = [deviceGenerationTier1, deviceGenerationTier2, deviceGenerationTier3]

var itemGeneration = []
var itemTurnedDeviceGeneration = []

var itemTurnedDevicePickupGeneration = []

var shopGearChances = {
	"Weapon": 5,
	"Armor": 5,
	"Headgear": 5
}

var scrollChances = {
	"Teleportation": 30,
	"Healing": 25,
	"Sight": 35,
	"Time": 12,
}

var Game

func init():
	Game = get_parent().Game
	guy = Game.guy
	map = Game.map
	gearGenerationSetup("", 0)
	deviceGenerationSetup(0)
	itemGenerationSetup("")
	
func deviceGenerationSetup(tier):
	var itemFile = File.new()
	itemFile.open("res://Card/Card Sheet.txt", itemFile.READ)
	while not itemFile.eof_reached():
		var values = str(itemFile.get_line()).replace("\"", "").split("\t")
		if values[0] == "":
			continue
		if values[1].begins_with("Device"):
			var devicetier = int(values[1].split(" ")[1])
			if tier == devicetier || tier == 0:
				deviceGeneration[devicetier-1].append(values[0])
	itemFile.close()
	
func itemGenerationSetup(devices):
	var itemFile = File.new()
	itemFile.open("res://Card/Card Sheet.txt", itemFile.READ)
	while not itemFile.eof_reached():
		var values = str(itemFile.get_line()).replace("\"", "").split("\t")
		if values[0] == "":
			continue
		if values[1] == "Item":
			if devices != "Device":
				itemGeneration.append(values[0])
			if devices != "Item":
				itemTurnedDeviceGeneration.append(values[0])
			if devices != "Device" && devices != "Item":
				itemTurnedDevicePickupGeneration.append(values[0])
	itemFile.close()

func gearGenerationSetup(type, tier):
	var gearFile = File.new()
	gearFile.open("res://Gear/Gear Sheet.txt", gearFile.READ)
	while not gearFile.eof_reached():
		var values = str(gearFile.get_line()).replace("\"", "").split("\t")
		if values[0] == "":
			continue
		if values[1] == "Weapon" && (type == "Weapon" || type == ""):
			if int(values[3]) == 1 && (tier == 1 || tier == 0):
				weaponGenerationTier1.append(values[0])
			elif int(values[3]) == 2 && (tier == 2 || tier == 0):
				weaponGenerationTier2.append(values[0])
			elif int(values[3]) == 3 && (tier == 3 || tier == 0):
				weaponGenerationTier3.append(values[0])
		elif values[1] == "Armor" && (type == "Armor" || type == ""):
			if int(values[3]) == 1 && (tier == 1 || tier == 0):
				armorGenerationTier1.append(values[0])
			elif int(values[3]) == 2 && (tier == 2 || tier == 0):
				armorGenerationTier2.append(values[0])
			elif int(values[3]) == 3 && (tier == 3 || tier == 0):
				armorGenerationTier3.append(values[0])
		elif values[1] == "Headgear" && (type == "Headgear" || type == ""):
			if int(values[3]) == 2 && (tier == 2 || tier == 0):
				headgearGenerationTier2.append(values[0])
			elif int(values[3]) == 3 && (tier == 3 || tier == 0):
				headgearGenerationTier3.append(values[0])
	gearFile.close()

func ShopItem():
	if itemGeneration.size() == 0:
		itemGenerationSetup("Item")
	
	var index = randi()%itemGeneration.size()
	var itemName = itemGeneration[index]
	itemGeneration.remove(index)
	return itemName

func ShopItemTurnedDevice():
	if itemTurnedDeviceGeneration.size() == 0:
		itemGenerationSetup("Device")
	
	var index = randi()%itemTurnedDeviceGeneration.size()
	var itemName = itemTurnedDeviceGeneration[index]
	itemTurnedDeviceGeneration.remove(index)
	return itemName
	
func ItemTurnedDevice():
	return itemTurnedDevicePickupGeneration[randi()%itemTurnedDevicePickupGeneration.size()]
	
func ShopDevice(x, y):
	var deviceName
	var rand = randi()%100
	var tiers = {
		'B': [70, 25],
		'C': [40, 50],
		'D': [0, 65],
		'E': [0, 40],
		'F': [0, 0]
	}
	
	var percentages = tiers[map.getTier(x, y)]
	var tier = 2
	for i in percentages.size():
		if rand < percentages[i]:
			tier = i
			break
	var list = deviceGeneration[tier]
	if list.size() == 0:
		deviceGenerationSetup(tier + 1)
	var index = randi()%list.size()
	deviceName = list[index]
	list.remove(index)
	return [deviceName, tier + 1]

func Gear(gearType, x, y):
	var gearName
	var rand = randi()%100
	var tiers = {
		'A': [95, 100],
		'B': [15-(x+y), 95],
		'C': [10-(x+y), 85],
		'D': [0, 60],
		'E': [0, 40],
		'F': [0, 0]
	}
	
	var percentages = tiers[map.getTier(x, y)]
	var tier = 2
	for i in percentages.size():
		if rand < percentages[i]:
			tier = i
			break
	if gearType == "Headgear" && tier == 0:
		tier = 1
	var list = gearGeneration[tier][gearType]
	if list.size() == 0:
		gearGenerationSetup(gearType, tier + 1)
	var index = randi()%list.size()
	gearName = list[index]
	list.remove(index)
	
	return gearName

func ShopGear(x, y):
	var gearName
	var rand = randi()%100
	var tiers = {
		'B': 100,
		'C': 80,
		'D': 50,
		'E': 0,
		'F': 0
	}
	
	var refill = true
	for key in shopGearChances:
		if shopGearChances[key] > 1:
			refill = false
	if refill:
		for key in shopGearChances:
			shopGearChances[key] = 5
	
	var chance1 = shopGearChances["Weapon"]
	var chance2 = shopGearChances["Armor"] + chance1
	var chance3 = shopGearChances["Headgear"] + chance2
	
	var randtype = randi()%chance3
	var gearType
	if randtype < chance1:
		gearType = "Weapon"
	elif randtype < chance2:
		gearType = "Armor"
	else:
		gearType = "Headgear"
	
	shopGearChances[gearType] -= 3
	if shopGearChances[gearType] < 1:
		shopGearChances[gearType] = 1
	
	var tier = 2
	if rand < tiers[map.getTier(x, y)]:
		tier = 1
	var list = gearGeneration[tier][gearType]
	if list.size() == 0:
		gearGenerationSetup(gearType, tier + 1)
	gearName = list[randi()%list.size()]
	
	return [gearName, gearType, tier+1, list]

func Scroll():
	var scrollName
	
	var refill = true
	for key in scrollChances:
		if scrollChances[key] > 3:
			refill = false
	if refill:
		scrollChances["Teleportation"] = 30
		scrollChances["Healing"] = 25
		scrollChances["Sight"] = 35
		scrollChances["Time"] = 12
	
	var chance1 = scrollChances["Teleportation"]
	var chance2 = scrollChances["Healing"] + chance1
	var chance3 = scrollChances["Sight"] + chance2
	var chance4 = scrollChances["Time"] + chance3
	
	var rand = randi()%chance4
	
	var type
	if rand < chance1:
		type = "Teleportation"
	elif rand < chance2:
		type = "Healing"
	elif rand < chance3:
		type = "Sight"
	else:
		type = "Time"
		
	scrollName = "Scroll of " + type
	scrollChances[type] -= 6
	if scrollChances[type] < 3:
		scrollChances[type] = 3
		
	return scrollName
	
func Runes(runesarray):
	var numrunes = 1 + randi()%5/2
	
	for i in numrunes:
		Rune(runesarray, numrunes)
	
	return numrunes

func Rune(runes, numrunes):
	var uncommon = 20
	var rare = 4
	
	var rand = randi()%100
	if rand < rare:
		runes.append("Void")
	elif rand < uncommon:
		var chance = randi()%10
		if chance < 3:
			runes.append("Copy")
		elif chance < 6:
			runes.append("Stay")
		else:
			runes.append("Push")
	else:
		var chance = randi()%4
		if chance == 0:
			runes.append("Flow")
		elif chance == 1:
			runes.append("Burn")
		else:
			runes.append("Link")
			
func Gold(x, y):
	return randi()%3 + 1 + (x + y)/8
