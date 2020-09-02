extends Node2D

var myself

#stores all affects in a dictionary of arrays for searching/retrieval
var effectList = {}
#these two are for keeping the order
var goodList = []
var badList = []
var singleList = {
	"Good": goodList,
	"Bad": badList
}

var effectPreload = preload("res://Effects/Effect.tscn")

#hasActive
#hasAllies
#tickAllies
#get

var Game

func init(me):
	myself = me
	Game = me.Game
	if myself.isPlayer():
		position = Vector2(448, 180)
	else:
		position = Vector2(512, 149)

func removeEffects(goodbad):
	for effect in singleList[goodbad]:
		effectList.erase(effect.effectName)
		effect.remove()
	singleList[goodbad].clear()
	
func fixRetainedEffects():
	for key in effectList:
		for effect in effectList[key]:
			effect.Card = null
			effect.scriptObject.Card = null
			effect.Combat = myself.currentCombat
			effect.scriptObject.Combat = myself.currentCombat

#if the effect is stackable, add it to the existing one
#if it is unstackable, permanent, and not an ally, just tick the effect
#otherwise, create a new effect
func addEffect(effectName, value, turns, Card):
	var effectProperties = Game.scriptgen.EffectScripts[effectName][0]
	if effectName in effectList && "replaceable" in effectProperties:
		effectList[effectName][0].updateVariables(value, turns, Card)
	elif effectName in effectList && "stackable" in effectProperties:
		effectList[effectName][0].add(value, Card)
	elif effectName in effectList && "permanent" in effectProperties && !"active" in effectProperties && !"ally" in effectProperties:
		tick(effectName)
	elif (str(value).begins_with("-") || str(value) == "0") && !"stat" in effectProperties && !"Bad" in effectProperties:
		return
	else:
		var effect = effectPreload.instance()
		add_child(effect)
		if effectName in effectList:
			effectList[effectName].append(effect)
		else:
			effectList[effectName] = [effect]
		effect.init(effectName, value, turns, Card)
		#inserts the effect to the correct list in the correct position based off its priority
		var list
		var priority = effect.priority
		var index = 0
		if effect.good:
			list = goodList
		else:
			list = badList
		if priority == -1:
			index = list.size()
		else:
			for eff in list:
				if eff.priority == -1 || priority < eff.priority:
					break
				else:
					index += 1
		list.insert(index, effect)
		effect.setPos(index)
		updatePositions()
		if !effect.shouldExist():
			removeEffect(null, effect)

func removeEffect(effectName, effect = null):
	if effectName == null:
		effectName = effect.effectName
	if effectName in effectList:
		if effect != null:
			effectList[effectName].erase(effect)
			if effect.good:
				goodList.erase(effect)
			else:
				badList.erase(effect)
			effect.remove()
			if effectList[effectName].empty():
				effectList.erase(effectName)
		else:
			var chain = effectList[effectName]
			var list
			if chain[0].good:
				list = goodList
			else:
				list = badList
			for eff in chain:
				list.erase(eff)
				eff.remove()
			effectList.erase(effectName)
	updatePositions()

#moves all effects to their correct positions on the Affected plate
func updatePositions():
	for i in goodList.size():
		goodList[i].movePos(i)
	for i in badList.size():
		badList[i].movePos(i)

#make the effects get removed mid-check and update their existence dynamically
func turn(goodbad = ""):
	var list
	var checklist
	if goodbad == "Good":
		checklist = goodList.duplicate()
		list = goodList
	elif goodbad == "Bad":
		checklist = badList.duplicate()
		list = badList
		
	for effect in checklist:
		effect.takeTurn()
		if !effect.shouldExist():
			removeEffect(null, effect)

#triggers all effects of the effectName
func trigger(effectName):
	if has(effectName):
		for effect in effectList[effectName]:
			effect.triggerFunction()

#ticks all effects of the effectName
func tick(effectName):
	if has(effectName):
		for effect in effectList[effectName]:
			effect.tick()

func hasActive(goodbad):
	for effect in singleList[goodbad]:
		if effect.active:
			return true
	return false

func has(effectName):
	if effectName in effectList:
		var effect = effectList[effectName][0]
		if !effect.delay:
			return true
		else:
			effect.delay = false
	return false

func hasAlly():
	for key in effectList:
		if effectList[key][0].has("ally"):
			return true
	return false

func get(effectName, effect = null):
	if effectName in effectList:
		var efflist = effectList[effectName]
		if effect != null:
			for eff in efflist:
				if eff == effect:
					return eff
		else:
			return efflist[0]
	return false

func getValue(effectName, effect = null):
	if effectName in effectList:
		var efflist = effectList[effectName]
		if effect != null:
			for eff in efflist:
				if eff == effect:
					return eff.value
		else:
			return efflist[0].value
	return 0
	
func getEffect(effectName):
	if effectName in effectList:
		return effectList[effectName][0]
		
func tickAllies():
	for key in effectList:
		if effectList[key][0].has("ally"):
			for effect in effectList[key]:
				effect.tick()
				
func allyBlock(damage):
	for key in singleList:
		for effect in singleList[key]:
			if effect.has("ally"):
				effect.add(-damage)
				return true
	return false

func mostRecentCharacterRecording():
	var recordings = []
#	for effect in effectListGood:
#		if effect.effectName == "Breakpoint":
#			recordings.append(effect)
	
	if recordings.size() == 0:
		return
	var mostrecent = recordings[0]
	for record in recordings:
		if record.value < mostrecent.value && record.value > 1:
			mostrecent = record
		elif record.value <= 1 && record.value > mostrecent.value:
			mostrecent = record
	mostrecent.tick()
	return mostrecent

func getRecording():
	var goodarray = []
#	for effect in effectListGood:
#		goodarray.append(effect.getRecording())
#	var badarray = []
#	for effect in effectListBad:
#		badarray.append(effect.getRecording())
#	return [goodarray, badarray]
	pass

func applyRecording(recording):
#	for effect in effectListGood:
#		effect.remove()
#	effectListGood.clear()
#	for effect in effectListBad:
#		effect.remove()
#	effectListBad.clear()
	
	var goodarray = recording[0]
	var badarray = recording[1]
#
#	for i in goodarray.size():
#		var effect = effectPreload.instance()
#		add_child(effect)
#		effectListGood.append(effect)
#		effect.applyRecording(goodarray[i])
#		effect.setPos(i)
#	for i in badarray.size():
#		var effect = effectPreload.instance()
#		add_child(effect)
#		effectListBad.append(effect)
#		effect.applyRecording(badarray[i])
#		effect.setPos(i)
#
#	updatePositions("Good")
#	updatePositions("Bad")
	pass

