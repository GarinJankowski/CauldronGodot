extends Node2D

var guy
var map
var textlog
var scriptgen

var bodyMutationPreload = preload("res://Body/bodyMutation.tscn")

var ticks = 8

var mutationList = {}
var positiveList = []
var negativeList = []
var singleList = {
	"Positive": positiveList,
	"Negative": negativeList
}

var bodyMutationList = {}
var bodyPositiveList = []
var bodyNegativeList = []
var bodySingleList = {
	"Positive": bodyPositiveList,
	"Negative": bodyNegativeList
}
var open = false

var selectedBodyMutation

var guynode
var backnode

var backstep = Vector2(0, 0)
var backstepy = 150

var leftnode
var rightnode
var sidestepx = -47.5
var leftStart
var leftDest
var rightStart
var rightDest

var backposStart
var backposDest

var mainButton

var leftCanScroll = false
var rightCanScroll = false
var bodyMutationsOnScreen = 6.0
var positiveBodyScrollValue = bodyMutationsOnScreen
var negativeBodyScrollValue = bodyMutationsOnScreen
var bodyMutationHeight = 86.0

var leftScrollButtonStepx = 0
var rightScrollButtonStepx = 0
var leftScrollButtonStartx
var leftScrollButtonTicks = 0
var rightScrollButtonStartx
var rightScrollButtonTicks = 0

var Game

func init():
	Game = get_parent().Game
	guy = Game.guy
	map = Game.map
	textlog = Game.textlog
	scriptgen = Game.scriptgen
	
	nodeSetup()

func nodeSetup():
	guynode = guy.get_node("Control")
	
	backnode = get_node("back")
	backposStart = backnode.position
	backposDest = backposStart
	
	backnode.visible = false
	
	leftnode = get_node("positive")
	leftStart = leftnode.position.x
	leftDest = leftStart
	
	rightnode = get_node("negative")
	rightStart = rightnode.position.x
	rightDest = rightStart
	
	leftnode.visible = false
	rightnode.visible = false
	
	mainButton = get_parent().Bag.get_node("bodyButtonMain/buttonBody")
	
	leftScrollButtonStartx = get_node("positive/pageDownButton").position.x
	rightScrollButtonStartx = get_node("negative/pageDownButton").position.x

func moveNodes():
	if backnode.position != backposDest:
		backnode.position += backstep
		if backnode.position == backposStart:
			backnode.visible = false
	if leftnode.position.x != leftDest:
		leftnode.position.x += sidestepx
		if leftnode.position.x == leftStart:
			leftnode.visible = false
	if rightnode.position.x != rightDest:
		rightnode.position.x -= sidestepx
		if rightnode.position.x == rightStart:
			rightnode.visible = false
			
	if leftScrollButtonTicks > 0:
		leftScrollButtonTicks -= 1
		get_node("positive/pageUpButton").position.x += leftScrollButtonStepx
		get_node("positive/pageDownButton").position.x += leftScrollButtonStepx
		if leftScrollButtonTicks == 0:
			if !leftCanScroll:
				get_node("positive/pageUpButton").visible = false
				get_node("positive/pageDownButton").visible = false
				get_node("positive/pageUpButton").position.x = leftScrollButtonStartx
				get_node("positive/pageDownButton").position.x = leftScrollButtonStartx
	if rightScrollButtonTicks > 0:
		rightScrollButtonTicks -= 1
		get_node("negative/pageUpButton").position.x += rightScrollButtonStepx
		get_node("negative/pageDownButton").position.x += rightScrollButtonStepx
		if rightScrollButtonTicks == 0:
			if !rightCanScroll:
				get_node("negative/pageUpButton").visible = false
				get_node("negative/pageDownButton").visible = false
				get_node("negative/pageUpButton").position.x = rightScrollButtonStartx
				get_node("negative/pageDownButton").position.x = rightScrollButtonStartx

func _process(delta):
	if !open && Input.is_action_just_pressed("body"):
		if guy.Bag.open:
			guy.Bag.close()
		open()
		if guy.inMenu:
			mainButton.disabled = true
			get_parent().Bag.mainButton.disabled = true
	elif open && (Input.is_action_just_pressed("body") || Input.is_action_just_pressed("ui_cancel")):
		close()
		if !guy.inMenu:
			mainButton.disabled = false
			get_parent().Bag.mainButton.disabled = false
	
	moveNodes()

func _input(event):
	if open && (leftCanScroll || rightCanScroll) && event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			bodyScrollUp(true, -1, 1)
			bodyScrollUp(false, -1, 1)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			bodyScrollUp(true, 1, 1)
			bodyScrollUp(false, 1, 1)

func addMutation(mutationName):
	if mutationName in mutationList:
		bodyMutationList[mutationName].incrementMutation()
		mutationList[mutationName].multiplier += 1
		mutationList[mutationName].init()
	else:
		var positive = scriptgen.MutationScripts[mutationName][0]["positive"]
		var scriptObject = Reference.new()
		scriptObject.set_script(scriptgen.MutationScripts[mutationName][1])
		scriptObject.init(guy)
		
		var bodyMut = bodyMutationPreload.instance()
		bodyMut.Body = self
		get_node(positive.to_lower() + "/bodyMutations").add_child(bodyMut)
		bodyMut.init(mutationName, bodySingleList[positive].size())
		
		singleList[positive].append(scriptObject)
		bodySingleList[positive].append(bodyMut)
		mutationList[mutationName] = scriptObject
		bodyMutationList[mutationName] = bodyMut
		updateBodyMutationNode(positive)
		#if positive && mutationList.size() == 1:
		selectMutation(bodyMut)
	guy.updateUI()
	
func start(positive):
	for mut in singleList[positive]:
		mut.startFunction()
	
func trigger(mutationName, Card = null, amount = 0):
	if has(mutationName):
		var Combat
		if Card != null:
			Combat = Card.Combat
		mutationList[mutationName].triggerFunction(Combat, amount)
		return true
	return false
	
func value(mutationName, amount = 0):
	if has(mutationName):
		return mutationList[mutationName].valueFunction(amount)
	return 0

func has(mutationName):
	if mutationName in mutationList:
		return true
	return false

func updateBodyMutationNode(positive):
	if bodySingleList[positive].size() > 6:
		get_node(positive.to_lower() + "/bodyMutations").positive.y = 0
	else:
		get_node(positive.to_lower() + "/bodyMutations").position.y = 265 - bodySingleList[positive].size()*40

func selectMutation(bodyMut):
	if selectedBodyMutation != null:
		selectedBodyMutation.deselect()
	selectedBodyMutation = bodyMut
	selectedBodyMutation.select()

func open():
	z_index = 29
	guynode.z_index = 30
	open = true
	guy.inMenu = true
	mainButton.disabled = true
	
	backnode.visible = true
	leftnode.visible = true
	rightnode.visible = true
	
	guy.step = Vector2(0, -guy.stepy)
	guy.nodePosDest = guy.nodePosStart + guy.step*ticks
	
	backstep = Vector2(0, -backstepy)
	backposDest = backposStart + backstep*ticks/2
	
	sidestepx *= -1
	leftDest = leftStart + sidestepx*ticks
	rightDest = rightStart - sidestepx*ticks
	
	map.currentEvent.disableButtons()
	Game.tileTooltip(false)
	yield(get_tree().create_timer(0.2), "timeout")
	enableAreaCollisions(true)
	
func close():
	enableAreaCollisions(false)
	z_index = 28
	open = false
	guy.inMenu = false
	mainButton.disabled = false
	
	guy.step = Vector2(0, guy.stepy)
	guy.nodePosDest = guy.nodePosStart
	
	backstep = Vector2(0, backstepy)
	backposDest = backposStart
	
	sidestepx *= -1
	leftDest = leftStart
	rightDest = rightStart
	
	map.currentEvent.enableButtons()

func bodyScrollUp(positive, updown, amount):
	if positive == "Positive" && amount > 0 && ((updown == 1 && positiveBodyScrollValue <= bodyPositiveList.size() && bodyPositiveList.size() > bodyMutationsOnScreen) || (updown == -1 && positiveBodyScrollValue > bodyMutationsOnScreen)):
		var scroll = bodyMutationHeight*updown
		get_node("positive/bodyMutations").position.y -= scroll
		positiveBodyScrollValue += scroll/bodyMutationHeight
		bodyScrollUp(positive, updown, amount-1)
	elif positive == "Negative" && amount > 0 && ((updown == 1 && negativeBodyScrollValue <= bodyNegativeList.size() && bodyNegativeList.size() > bodyMutationsOnScreen) || (updown == -1 && negativeBodyScrollValue > bodyMutationsOnScreen)):
		var scroll = bodyMutationHeight*updown
		get_node("negative/bodyMutations").position.y -= scroll
		negativeBodyScrollValue += scroll/bodyMutationHeight
		bodyScrollUp(positive, updown, amount-1)
		
		
#Interaction Things
func enableAreaCollisions(truefalse):
	for bodyMut in bodyPositiveList:
		bodyMut.enableAreaCollisions(truefalse)
	for bodyMut in bodyNegativeList:
		bodyMut.enableAreaCollisions(truefalse)

func _on_buttonBodyMenu_button_down():
	get_node("back/bodyButtonMenu/button_Body").scale -= Vector2(0.003, 0.003)

func _on_buttonBodyMenu_button_up():
	get_node("back/bodyButtonMenu/button_Body").scale += Vector2(0.003, 0.003)

func _on_buttonBodyMenu_pressed():
	Input.action_press("body")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("body")


func _on_buttonBagMenu_button_down():
	get_node("back/bagButtonMenu/button_Bag").scale -= Vector2(0.003, 0.003)

func _on_buttonBagMenu_button_up():
	get_node("back/bagButtonMenu/button_Bag").scale += Vector2(0.003, 0.003)

func _on_buttonBagMenu_pressed():
	Input.action_press("bag")
	yield(get_tree().create_timer(0.001), "timeout")
	Input.action_release("bag")

func _on_leftScrollArea_area_entered(area):
	if area.get_name() == "cursorArea" && bodyPositiveList.size() > 6:
		leftCanScroll = true
		get_node("positive/pageUpButton").visible = true
		get_node("positive/pageDownButton").visible = true
		leftScrollButtonTicks = 4
		leftScrollButtonStepx = 10

func _on_leftScrollArea_area_exited(area):
	if area.get_name() == "cursorArea" && bodyPositiveList.size() > 6:
		leftCanScroll = false
		leftScrollButtonTicks = 4
		leftScrollButtonStepx = -10
		
func _on_rightScrollArea_area_entered(area):
	if area.get_name() == "cursorArea" && bodyNegativeList.size() > 6:
		rightCanScroll = true
		get_node("negative/pageUpButton").visible = true
		get_node("negative/pageDownButton").visible = true
		rightScrollButtonTicks = 4
		rightScrollButtonStepx = -10

func _on_rightScrollArea_area_exited(area):
	if area.get_name() == "cursorArea" && bodyNegativeList.size() > 6:
		rightCanScroll = false
		rightScrollButtonTicks = 4
		rightScrollButtonStepx = 10


func _on_leftbutton_ScrollPageUp_pressed():
	bodyScrollUp(true, -1, bodyMutationsOnScreen)

func _on_leftbutton_ScrollPageDown_pressed():
	bodyScrollUp(true, 1, bodyMutationsOnScreen)

func _on_rightbutton_ScrollPageUp_pressed():
	bodyScrollUp(false, -1, bodyMutationsOnScreen)

func _on_rightbutton_ScrollPageDown_pressed():
	bodyScrollUp(false, 1, bodyMutationsOnScreen)


func _on_leftbutton_ScrollPageUp_button_down():
	get_node("positive/pageUpButton/scrollPageButton").scale -= Vector2(0.003, 0.003)

func _on_leftbutton_ScrollPageUp_button_up():
	get_node("positive/pageUpButton/scrollPageButton").scale += Vector2(0.003, 0.003)

func _on_leftbutton_ScrollPageDown_button_down():
	get_node("positive/pageDownButton/scrollPageButton").scale -= Vector2(0.003, 0.003)

func _on_leftbutton_ScrollPageDown_button_up():
	get_node("positive/pageDownButton/scrollPageButton").scale += Vector2(0.003, 0.003)

func _on_rightbutton_ScrollPageUp_button_down():
	get_node("negative/pageUpButton/scrollPageButton").scale -= Vector2(0.003, 0.003)

func _on_rightbutton_ScrollPageUp_button_up():
	get_node("negative/pageUpButton/scrollPageButton").scale += Vector2(0.003, 0.003)

func _on_rightbutton_ScrollPageDown_button_down():
	get_node("negative/pageDownButton/scrollPageButton").scale -= Vector2(0.003, 0.003)

func _on_rightbutton_ScrollPageDown_button_up():
	get_node("negative/pageDownButton/scrollPageButton").scale += Vector2(0.003, 0.003)
