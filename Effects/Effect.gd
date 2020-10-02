extends Node2D

var effectName
var Card
var Combat
var myself

var effectProperties
var good
var active
var priority = -1
var everyOther = false
var delay = false

var value
var turns

var scriptObject

var displayName
var displayTurns

var EffectsList

var specialValue = false

var index = 0
var init = false
var maxeffects = 6
var startpos = Vector2(-92, -55)
var layerstep = Vector2(-33, 12)
var dest = Vector2(0, 0)

onready var ticknode = get_node("tick")
var tickdestx
var tickstepx = 1

var stepx = 11
var stepy = 12

var Game

func init(ename, v, t, c):
	EffectsList = get_parent()
	myself = EffectsList.myself
	Game = EffectsList.Game
	effectName = ename
	Card = c
	if c == null || c.myself != myself:
		Combat = myself.currentCombat
	else:
		Combat = Card.Combat.duplicate()
		add_child(Combat)
		Combat.init(Card.Combat.me, Card.Combat.enemy)
	
	value = v
	turns = t
	
	scriptObject = Reference.new()
	var effectInfo = Game.scriptgen.EffectScripts[ename]
	effectProperties = effectInfo[0].duplicate()
	scriptObject.set_script(effectInfo[1])
	scriptObject.init(self)
	initVariables()
	
	setDisplayName()
	setDisplayTurns()
	var newtxt = (str(value)).replace(" ", "")
	if newtxt == "0" && !"zero" in effectProperties:
		newtxt = ""
	if effectName == "Trick":
		newtxt = "x" + newtxt
	get_node("tick/amount").text = newtxt
	
	if effectName == "Focus":
		setValue(turns)
	elif effectName == "Record":
		get_node("tick/amount").modulate = "000000"
	elif effectName == "You":
		specialValue = []
	
	if !myself.isPlayer():
		maxeffects = 3
	if !good:
		get_node("tick/amount").rect_position.x = 9
		startpos.x *= -1
		layerstep.x *= -1
		position.x = startpos.x
		get_node("effectArea").position.x = 27
		dest.x = position.x
		position.x -= stepx*4
		tickstepx *= -1
	else:
		position.x = startpos.x
		dest.x = position.x
		position.x += stepx*4
		stepx *= -1
	tickdestx =  ticknode.position.x
	get_node("tick/effectSprite").set_texture(load("res://Effects/effectSprites/effect_" + effectName + ".png"))

func _process(delta):
	if position.x != dest.x:
		position.x += stepx
	if position.y != dest.y:
		position.y += stepy
	if ticknode.position.x != tickdestx:
		ticknode.position.x += tickstepx

func initVariables():
	if "Good" in effectProperties:
		good = true
		effectProperties.erase("Good")
	else:
		good = false
		effectProperties.erase("Bad")
		
	if "active" in effectProperties:
		active = true
		effectProperties.erase("active")
	else:
		active = false
	
	for prop in effectProperties:
		if prop.begins_with("priority"):
			priority = int(prop.split(" ")[1])
	
	if "delay" in effectProperties:
		effectProperties.erase("delay")
		delay = true

func updateVariables(val, trn, cd):
	if Card != null:
		Card = cd
		Combat = Card.Combat.duplicate()
		add_child(Combat)
		Combat.init(Combat.me, Combat.enemy)
	value = val
	turns = trn
	tick()

func turnFunction():
	scriptObject.turnFunction()

func triggerFunction():
	tick()
	scriptObject.triggerFunction()

func endFunction():
	tick()
	scriptObject.endFunction()

func takeTurn():
	if active:
		if "everyOther" in effectProperties && everyOther:
			everyOther = false
		else:
			turnFunction()
			everyOther = true
	if turns > 0:
		turns -= 1
		setDisplayTurns()
		if effectName == "Focus":
			setValue(turns)

func has(prop):
	if prop in effectProperties:
		return true
	return false

func setText(txt):
	var newtxt = txt.replace(" ", "")
	if newtxt != get_node("tick/amount").text && effectName != "Record":
		tick()
	if effectName == "Trick":
		newtxt = "x" + newtxt
	get_node("tick/amount").text = newtxt
	if !shouldExist():
		EffectsList.removeEffect(null, self)

func remove():
	if has("end function"):
		endFunction()
	stepx *= -1
	if good:
		dest.x += abs(stepx*5)
	else:
		dest.x -= abs(stepx*5)
	balanceSteps()
	yield(get_tree().create_timer(0.2), "timeout")
	queue_free()

func tick():
	tickdestx = 0
	ticknode.position.x = -tickstepx*15

func update():
	setText(str(value))

func add(val, cd = null):
	value = int(value) + int(val)
	if cd != null:
		Card = cd
		Combat = Card.Combat.duplicate()
	setText(str(value))

func addTurns(val):
	turns += val
	setDisplayTurns()

func setValue(val):
	value = val
	setText(str(value))

func equals(eff):
	if eff == effectName:
		return true
	return false

func setPos(pos):
	setDestination(pos)
	position = dest
	if !init:
		init = true
		position.x = startpos.x - stepx*4

func movePos(pos):
	setDestination(pos)
	stepy = abs(stepy)
	if dest.y < position.y:
		stepy *= -1

func setDestination(pos):
	index = pos
	var column = 0
	var row = pos
	
	while row >= maxeffects - (column+2)%2:
		row -= maxeffects - (column+2)%2
		column += 1
	
	var desty = startpos.y + row*layerstep.y*2
	if (column+2)%2 == 1:
		desty += layerstep.y
	z_index = -column
	dest = Vector2(startpos.x + layerstep.x*column, desty)
	balanceSteps()
	
func balanceSteps():
	stepx = abs(stepx)
	stepy = abs(stepy)
	if dest.x < position.x:
		stepx *= -1
	if dest.y < position.y:
		stepy *= -1

func shouldExist():
	#rewrite this
	if (value is int && value <= 0 && (!"zero" in effectProperties && (good || !has("stat")))) || turns == 0:
		return false
	return true

func setDisplayName():
	var dn = effectName
	if has("ally"):
		dn += " (Ally)"
	displayName = dn
	
func setDisplayTurns():
	var dt = " turns left"
	if turns == -1:
		dt = ""
	else:
		if turns == 1:
			dt = " turn left"
		dt = "(" + str(turns) + dt + ")"
	displayTurns = dt

func setBreakpoint():
	setValue(0)
	var recordArray = []
	specialValue = recordArray
	recordArray.append(myself.currentCombatEvent.getRecording())
	recordArray.append([])

func getRecording():
	var valarray = [
		effectProperties,
		Combat,
		myself,
		delay,
		specialValue
	]
	return [effectName, value, turns, Card, valarray]
	
func applyRecording(recording):
	init(recording[0], recording[1], recording[2], recording[3])
	
	var valarray = recording[4]
	effectProperties = valarray[0]
	Combat = valarray[1]
	myself = valarray[2]
	delay = valarray[3]
	specialValue = valarray[4]

func calculate(string):
	var finalnum = 0
	var negative = false
	if string.begins_with("-"):
		string.erase(0, 1)
		negative = true
	var infix = str(string).split(" ")
	var postfix = []
	
	var second = false
	while !infix.empty():
		if second:
			postfix.append(infix[1])
			infix.remove(1)
			second = false
		else:
			postfix.append(infix[0])
			infix.remove(0)
			second = true
	
	var stack = []
	var operators = "+-*/d"
	
	for i in range(len(postfix)):
		if postfix[i] in operators:
			var a = int(myself.convertStat(stack.pop_back(), Card, self))
			var b = int(myself.convertStat(stack.pop_back(), Card, self))
			var op = postfix[i]
			if op == '+':
				stack.push_back(str(a + b))
			elif op == '-':
				stack.push_back(str(b - a))
			elif op == '*':
				stack.push_back(str(a * b))
			elif op == '/':
				stack.push_back(str(b / a))
			elif op == 'd':
				stack.push_back(str(Game.rtd(b, a)))
		else:
			stack.push_back(postfix[i])
	finalnum = int(myself.convertStat(stack.pop_back(), Card, self))
	if negative:
		finalnum *= -1
	return finalnum

func _on_effectArea_area_entered(area):
	if area.get_name() == "cursorArea":
		Game.effectTooltip(true, self)

func _on_effectArea_area_exited(area):
	if area.get_name() == "cursorArea":
		Game.effectTooltip(false)
