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

func removeEffects(goodbad, property = null):
	var efflist = singleList[goodbad]
	if property != null:
		for effect in efflist:
			if effect.has(property):
				removeEffect(null, effect)
	else:
		for effect in efflist:
			var effName = effect.effectName
			effectList[effName].remove(0)
			if effectList[effName].size() == 0:
				effectList.erase(effect.effectName)
			effect.remove()
		efflist.clear()
		
func fixRetainedEffects():
	for key in effectList:
		for effect in effectList[key]:
			effect.Card = null
			effect.scriptObject.Card = null
			effect.myself = myself
			effect.Combat = myself.currentCombat
			if effect.Combat == null:
				effect.scriptObject.opponent = null
			else:
				effect.scriptObject.opponent = myself.currentCombat.enemy
			effect.scriptObject.myself = myself
			effect.scriptObject.Combat = myself.currentCombat

#if the effect is stackable, add it to the existing one
#if it is unstackable, permanent, and not an ally, just tick the effect
#otherwise, create a new effect
func addEffect(effectName, value, turns, Card):
	var effectProperties = Game.scriptgen.EffectScripts[effectName][0]
	if myself.hasEffect("Shatter") && "Good" in effectProperties && value > 0:
		return
	if effectName in effectList && "replaceable" in effectProperties:
		effectList[effectName][0].updateVariables(value, turns, Card)
	elif effectName in effectList && "stackable" in effectProperties:
		if "permanent" in effectProperties:
			effectList[effectName][0].add(value, Card)
		else:
			#if the effect is stackable, has a duration, and one already exists, then make a check
			#if there is an effect of the same type with the same duration, just add the value to it
			#otherwise, create a new effect and sort by nondecreasing duration
			if int(value) > 0:
				var effList = effectList[effectName]
				var i = effList.size()
				while i > 0 && turns <= effList[i-1].turns:
					if turns == effList[i-1].turns:
						effList[i-1].add(value, Card)
						i = -1
						break
					else:
						i -= 1
				if i > -1:
					var effect = effectPreload.instance()
					add_child(effect)
					effectList[effectName].insert(i, effect)
					effect.init(effectName, value, turns, Card)
					var list = badList
					if effect.good:
						list = goodList
					var index = effList[0].index+i
					list.insert(index, effect)
					effect.setPos(index)
					updatePositions()
					if !effect.shouldExist():
						removeEffect(null, effect)
			#if the value is less than zero,
			#add that value to the total of the effects,
			#erasing any effects that reach zero and moving on to the next effect (in order of duration, nondecreasing)
			elif value < 0:
				value *= -1
				var effList = effectList[effectName]
				while value > 0 && effectName in effectList:
					if value < effList[0].value:
						effList[0].add(-value, null)
						value = 0
					else:
						value -= effList[0].value
						effList[0].tick()
						removeEffect(null, effList[0])
				return value
			return 0
	elif effectName in effectList && "permanent" in effectProperties && !"active" in effectProperties && !"ally" in effectProperties:
		tick(effectName)
	elif (str(value).begins_with("-") || str(value) == "0") && !"zero" in effectProperties && !"stat" in effectProperties && !"Bad" in effectProperties:
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
			
func increaseEffect(effectName, value):
	if has(effectName):
		for effect in effectList[effectName]:
			effect.add(value)

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
		var efflist = effectList[effectName].duplicate()
		for effect in efflist:
			effect.triggerFunction()
		return true
	return false

#ticks all effects of the effectName
func tick(effectName):
	if has(effectName):
		for effect in effectList[effectName]:
			effect.tick()

func hasActive(goodbad):
	for effect in singleList[goodbad]:
		if effect.active && (!effect.cycle || effect.scriptObject.cycleCounter == effect.scriptObject.cycle):
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
		elif efflist[0].has("stackable"):
			var value = 0
			for eff in efflist:
				value += int(eff.value)
			return value
		else:
			return efflist[0].value
	return 0
	
func getAllValues(effectName):
	var val = 0
	if effectName in effectList:
		for eff in effectList[effectName]:
			val += int(eff.value)
	return val
	
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
	if "Record" in effectList:
		var record = effectList["Record"][0]
		record.tick()
		return record
	return false

func getRecording():
	var goodarray = []
	var badarray = []
	for effect in goodList:
		goodarray.append(effect.getRecording())
	for effect in badList:
		badarray.append(effect.getRecording())
	return [goodarray, badarray]

func applyRecording(recording):
	effectList.clear()
	for effect in goodList:
		effect.remove()
	goodList.clear()
	for effect in badList:
		effect.remove()
	badList.clear()
	
	var goodarray = recording[0]
	var badarray = recording[1]
	
	for i in goodarray.size():
		var effect = effectPreload.instance()
		add_child(effect)
		goodList.append(effect)
		effect.applyRecording(goodarray[i])
		var effname = effect.effectName
		if !effname in effectList:
			effectList[effname] = []
		effectList[effname].append(effect)
		effect.setPos(i)
	for i in badarray.size():
		var effect = effectPreload.instance()
		add_child(effect)
		badList.append(effect)
		effect.applyRecording(badarray[i])
		var effname = effect.effectName
		if !effname in effectList:
			effectList[effname] = []
		effectList[effname].append(effect)
		effect.setPos(i)

