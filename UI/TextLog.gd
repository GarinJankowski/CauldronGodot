extends Node2D

onready var text = get_node("Label")
#var normal = "[color=#d4ccc5]"
var normal = "[color=#b5aa9f]"
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
var pink = "[color=#ff3bef]"
var darkhotpink = "[color=#dc00aa]"
var scroll = "[color=#ccbf74]"
var white = "[color=#ffffff]"
#this ones a bit too dark maybe
var brown = "[color=#786957]"

var colors = {
	"n": normal,
	"b": bronze,
	"r": red,
	"o": orange,
	"G": gold,
	"y": yellow,
	"g": green,
	"l": lightblue,
	"d": darkblue,
	"i": indigo,
	"m": magenta,
	"P": lightpink,
	"p": pink,
	"h": darkhotpink,
	"s": scroll,
	"w": white,
	"B": brown
}

var textQueue = []

func init():
	pass

#takes a line, adds the color string for each [n] format, and immediately pushes it to the log
func push(line):
	var finalline = normal
	finalline += "\n"
	
	finalline += translate(line)
	
	#text.bbcode_text += "[center]"
	text.bbcode_text += finalline

#adds a line to the log queue
func queue(line):
	textQueue.append(line)
	checkQueue()
	
#reserves a spot in the queue, specifically used for Card logs
#things often occur in between the playing of a card and the pushing of its log
#having reserved spots keeps the order of things, so the card's log still gets pushed before the logs of things happening in between
func reserve(cardName):
	textQueue.append("RESERVED" + cardName)
	checkQueue()

#cancels the most recent reservation (highest index) of the card name
#used right before ALTERNATE ghost cards are played, since the original card log would never be fulfilled
func cancel(cardName):
	var lookingfor = "RESERVED" + cardName
	for i in range(textQueue.size()-1, -1, -1):
		if textQueue[i] == lookingfor:
			textQueue.remove(i)
			checkQueue()
			return

#fulfills the earliest reserved spot with the same card name, replacing the reserved spot with the new log
func fulfill(line, cardName):
	var lookingfor = "RESERVED" + cardName
	for i in textQueue.size():
		if textQueue[i] == lookingfor:
			textQueue[i] = line
			checkQueue()
			return


#keeps pushing the front of the queue until the front is a reserved spot
func checkQueue():
	while !textQueue.empty() && !textQueue[0].begins_with("RESERVED"):
		push(textQueue.pop_front())	

#replaces the single-char color symbols with the actual color that is required for the rich text
#(actual colors and their keys are located in the "colors" dictionary up top)
func translate(line):
	var finalline = normal
	
	var i = 0
	while i < len(line):
		if line[i] == "[" && i+2 < len(line) && line[i+2] == "]":
			var cindex = line[i+1]
			finalline += colors[cindex]
			i += 2
		else:
			finalline += line[i]
		i += 1
	return finalline
