extends "res://Events/Event.gd"

var Body

var positiveMutations = []
var negativeMutations = []

var mutindex

var mutationPreload = preload("res://Body/Mutation.tscn")

var chosePositive = false

func init2(r):
	init(r)
	
	Body = guy.Body
	
	gainMutationLevel()
	positiveMutations = itemgen.PositiveMutations()
	negativeMutations = itemgen.NegativeMutations()
	mutationEvent("Positive")

func _process(delta):
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("number_1") || Input.is_action_just_pressed("ui_left"):
			if chosePositive:
				chooseMutation("Negative", 0)
				end2()
			else:
				chosePositive = true
				chooseMutation("Positive", 0)
				mutationEvent("Negative")
		elif Input.is_action_just_pressed("number_2") || Input.is_action_just_pressed("ui_up"):
			if chosePositive:
				chooseMutation("Negative", 1)
				end2()
			else:
				chosePositive = true
				chooseMutation("Positive", 1)
				mutationEvent("Negative")
		elif Input.is_action_just_pressed("number_3") || Input.is_action_just_pressed("ui_right"):
			if chosePositive:
				chooseMutation("Negative", 2)
				end2()
			else:
				chosePositive = true
				chooseMutation("Positive", 2)
				mutationEvent("Negative")

func gainMutationLevel():
	guy.addStat("Mutation Level", 1)
	textlog.push("[P]You gain 1 Mutation.")
	textlog.push("[P]You feel your body changing...")

func chooseMutation(positive, index):
	var mutlist
	var color
	if positive == "Positive":
		mutlist = positiveMutations
	elif positive == "Negative":
		mutlist = negativeMutations
	
	var mutname = mutlist[index].mutationName
	#grants the mutation to the player
	Body.addMutation(mutname)
	mutlist[index].end(true)
	#returns the leftover mutations to the itemgen to be generated later
	mutlist.remove(index)
	for i in mutlist.size():
		mutlist[i].end(false)
		mutlist[i] = mutlist[i].mutationName
	itemgen.MutationLeftovers(mutlist, positive)
	
	var text = Game.scriptgen.MutationScripts[mutname][0]["mutationLog"]
#	var numchars = 1
#	if text.substr(0, 1) == "{":
#		numchars += 1
#	var firstchar = text.substr(0, numchars)
#	text.erase(0, numchars)
	if positive == "Positive":
		text = "[p]..." + text + "..."
	elif positive == "Negative":
		text = "[h]...and " + text + "."
	textlog.push(text)
			
func end2():
	end()		

func mutationEvent(positive):
	var mutlist
	if positive == "Positive":
		mutlist = positiveMutations
	else:
		mutlist = negativeMutations
	var newlist = []
	for i in mutlist.size():
		var mutation = mutationPreload.instance()
		add_child(mutation)
		newlist.append(mutation)
		mutation.init(mutlist[i], i)

	if positive == "Positive":
		positiveMutations = newlist
	elif positive == "Negative":
		negativeMutations = newlist
	
func disableButtons():
	for mut in positiveMutations:
		if typeof(mut) != TYPE_STRING:
			mut.disableButton()
	for mut in negativeMutations:
		if typeof(mut) != TYPE_STRING:
			mut.disableButton()
	
func enableButtons():
	for mut in positiveMutations:
		if typeof(mut) != TYPE_STRING:
			mut.enableButton()
	for mut in negativeMutations:
		if typeof(mut) != TYPE_STRING:
			mut.enableButton()
