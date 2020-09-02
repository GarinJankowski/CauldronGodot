extends Node2D

onready var text = get_node("Label")
var normal = "[color=#d4ccc5]"
var bronze = "[color=#c28e15]"
var red = "[color=#d90000]"
var orange = "[color=#e84900]"
var gold = "[color=#d4c600]"
var yellow = "[color=#f1f50c]"
var green = "[color=#14e018]"
var lightblue = "[color=#5d94c7]"
var darkblue = "[color=#2e3cff]"
var indigo = "[color=#7033ff]"
var magenta = "[color=#cb0ff5]"
var lightpink = "[color=#fd7bff]"
var pink = "[color=#f800ff]"
var darkhotpink = "[color=#dc00aa]"
var scroll = "[color=#ccbf74]"
var white = "[color=#ffffff]"

func init():
	pass

#takes a line, adds the color string for each [n] format, and adds it too the log
func push(line):
	var finalline = normal
	finalline += "\n"
	
	finalline += translate(line)
	
	#text.bbcode_text += "[center]"
	text.bbcode_text += finalline

func translate(line):
	var finalline = normal
	
	var i = 0
	while i < len(line):
		if line[i] == "[" && i+2 < len(line) && line[i+2] == "]":
			var color = line[i+1]
			if color == "n":
				finalline += normal
			elif color == "b":
				finalline += bronze
			elif color == "r":
				finalline += red
			elif color == "o":
				finalline += orange
			elif color == "G":
				finalline += gold
			elif color == "y":
				finalline += yellow
			elif color == "g":
				finalline += green
			elif color == "l":
				finalline += lightblue
			elif color == "d":
				finalline += darkblue
			elif color == "i":
				finalline += indigo
			elif color == "m":
				finalline += magenta
			elif color == "P":
				finalline += lightpink
			elif color == "p":
				finalline += pink
			elif color == "h":
				finalline += darkhotpink
			elif color == "s":
				finalline += scroll
			elif color == "w":
				finalline += white
			i += 2
		else:
			finalline += line[i]
		i += 1
	return finalline
