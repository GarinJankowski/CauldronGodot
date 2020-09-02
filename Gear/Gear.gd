extends Node2D

var gearName
var gearType
var cards = []
var stats = []
var gearDescription

var equipped = false

var scriptgen
var Game

func init(gname):
	Game = get_parent().Game
	var scriptgen = Game.scriptgen
	var gearFile = File.new()
	gearFile.open("res://Gear/Gear Sheet.txt", gearFile.READ)
	while not gearFile.eof_reached():
		var line = str(gearFile.get_line())
		if line.begins_with(gname):
			setValuesFromString(line)
			break
	gearFile.close()

func setValuesFromString(gearString):
	gearString = gearString.replace("\"", "")
	
	var values = gearString.split("\t")
	gearName = values[0]
	gearType = values[1]
	var cardstring = values[2].split(", ")
	for i in range(cardstring.size()):
		var amountlength = 1
		if cardstring[i][len(cardstring[i])-3] != "(":
			amountlength = 2
		var count = cardstring[i].substr(len(cardstring[i])-amountlength-1, amountlength)
		for j in int(count):
			var card = load("res://Card/Card.tscn").instance()
			add_child(card)
			card.init(cardstring[i].substr(0, len(cardstring[i])-4))
			cards.append(card)
	
	stats = values[3]
	gearDescription = values[4]
	
func putOn(deck):
	if !equipped:
		equipped = true
		for i in range(len(cards)):
			deck.add(cards[i])
	
func takeOff(deck):
	if equipped:
		equipped = false
		for i in range(len(cards)):
			deck.remove(cards[i])

func printValues():
	print_debug(gearName)
	print_debug(gearType)
	print_debug(cards)
	print_debug(stats)
	print_debug(gearDescription)
