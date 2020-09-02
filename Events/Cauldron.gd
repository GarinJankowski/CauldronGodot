extends "res://Events/Event.gd"

var Body

var positiveMutations = []
var negativeMutations = []

var posMutationList = []
var negMutationList = []

var mutindex

var mutationPreload = preload("res://Body/Mutation.tscn")

var chosePositive = false

func init2(r):
	init(r)
	
	Body = guy.Body
	
	gainMutationLevel()
	generateMutations()
	eventPositiveMutations()

func _process(delta):
	if !guy.inMenu && !close:
		if Input.is_action_just_pressed("number_1") || Input.is_action_just_pressed("ui_left"):
			if chosePositive:
				chooseMutation(false, 0)
				end2()
			else:
				chosePositive = true
				chooseMutation(true, 0)
				eventNegativeMutations()
		elif Input.is_action_just_pressed("number_2") || Input.is_action_just_pressed("ui_up"):
			if chosePositive:
				chooseMutation(false, 1)
				end2()
			else:
				chosePositive = true
				chooseMutation(true, 1)
				eventNegativeMutations()
		elif Input.is_action_just_pressed("number_3") || Input.is_action_just_pressed("ui_right"):
			if chosePositive:
				chooseMutation(false, 2)
				end2()
			else:
				chosePositive = true
				chooseMutation(true, 2)
				eventNegativeMutations()

func gainMutationLevel():
	guy.addStat("Mutation Level", 1)
	textlog.push("[p]Your Mutation Level rises.")

func chooseMutation(positive, i):
	var mut
	mutindex = i
	var line
	if positive:
		mut = positiveMutations[i]
		for m in positiveMutations.size():
			if m != i:
				Body.positiveMutationGenerationBackup.append(positiveMutations[m])
		line = "[P]"
	else:
		mut = negativeMutations[i]
		for m in negativeMutations.size():
			if m != i:
				Body.negativeMutationGenerationBackup.append(negativeMutations[m])
		line = "[h]"
	
	Body.addMutation(positive, mut)
	textlog.push("You recieve " + line + mut[0] + "[n].")
			
func end2():
	for i in negMutationList.size():
		if i == mutindex:
			negMutationList[i].end(true)
		else:
			negMutationList[i].end(false)
	end()		

func eventPositiveMutations():
	for i in positiveMutations.size():
		var mutation = mutationPreload.instance()
		add_child(mutation)
		posMutationList.append(mutation)
		mutation.init(positiveMutations[i][0], positiveMutations[i][1], true, Body, i)

func eventNegativeMutations():
	for i in posMutationList.size():
		if i == mutindex:
			posMutationList[i].end(true)
		else:
			posMutationList[i].end(false)
	
	for i in negativeMutations.size():
		var mutation = mutationPreload.instance()
		add_child(mutation)
		negMutationList.append(mutation)
		mutation.init(negativeMutations[i][0], negativeMutations[i][1], false, Body, i)


func generateMutations():
	for i in 3:
		generateMutation()

func generateMutation():
	if Body.positiveMutationGeneration.size() == 0:
		if Body.positiveMutationGenerationBackup.size() == 0:
			Body.generationSetup("Positive")
		else:
			while Body.positiveMutationGenerationBackup.size() > 0:
				Body.positiveMutationGeneration.append(Body.positiveMutationGenerationBackup.pop_back())
	
	var pindex = randi()%Body.positiveMutationGeneration.size()
	positiveMutations.append(Body.positiveMutationGeneration[pindex])
	Body.positiveMutationGeneration.remove(pindex)
	
	if Body.negativeMutationGeneration.size() == 0:
		if Body.negativeMutationGenerationBackup.size() == 0:
			Body.generationSetup("Negative")
		else:
			while Body.negativeMutationGenerationBackup.size() > 0:
				Body.negativeMutationGeneration.append(Body.negativeMutationGenerationBackup.pop_back())
	
	var nindex = randi()%Body.negativeMutationGeneration.size()
	negativeMutations.append(Body.negativeMutationGeneration[nindex])
	Body.negativeMutationGeneration.remove(nindex)
	
func disableButtons():
	pass
	
func enableButtons():
	pass
