extends Node

var me
var enemy
var textlog
var CombatEvent

var Game

func init(myself, opponent):
	me = myself
	enemy = opponent
	
	Game = get_parent().get_parent().Game
	textlog = Game.textlog

func setCombatEvent(event):
	CombatEvent = event

#roll the dice
func rtd(amount, sides):
	var value = 0
	for i in range(amount):
		value += (randi()%sides)+1
	return value

#functions to edit the numbers
func change(who, type, amount, Card = null, turns = 1):
	if who.hasEffect("Nullify") && (type == "Health" || type == "Mana" || type == "Energy"):
		return
	if type == "Health":
		var pasthealth = who.CurrentHealth
		who.CurrentHealth += amount
		if who.CurrentHealth < 0:
			who.CurrentHealth = 0
		elif who.CurrentHealth > who.convertStat("MHP"):
			who.CurrentHealth = who.convertStat("MHP")
		if who.hasMutation("Mending Flesh") && pasthealth >= int(who.convertStat("MHP")*0.7) && who.CurrentHealth < int(who.convertStat("MHP")*0.7):
			who.triggerMutation("Mending Flesh")
		if amount < 0:
			who.trigger("Frozen")
			if who.hasEffect("Stranglehold (Attacker)"):
				who.addStranglehold(amount, Card)
		who.updateHealth()
		#if CombatEvent != null:
			#CombatEvent.checkDeath()
	elif type == "Mana":
		who.CurrentMana += amount
		if who.CurrentMana < 0:
			who.CurrentMana = 0
		elif who.CurrentMana > who.convertStat("MMP"):
			who.CurrentMana = who.convertStat("MMP")
		if who.isPlayer():
			who.updateMana()
	elif type == "Block":
		who.addBlock(amount, Card, turns)
	elif type == "Shield":
		who.addShield(amount, Card, turns)
	elif type == "Distance":
		if amount < 0 && -amount > who.getEffect("Distance"):
			var enemyamount = amount + who.getEffect("Distance")
			who.addEffect("Distance", amount, -1, Card)
			var tempenemy = me
			if who == me:
				tempenemy = enemy
			tempenemy.addEffect("Distance", enemyamount, -1, Card)
		else:
			who.addEffect("Distance", amount, -1, Card)
	elif type == "Energy" && who.isPlayer():
		who.CurrentEnergy += amount
		checkEnergy()
	elif type == "ExtraTurns" && who.isPlayer():
		var player
		if me.isPlayer():
			player = me
		else:
			player = enemy
			
		if amount > 0:
			for i in amount:
				player.addExtraTurns(1, Card)
			if amount == 1:
				textlog.push("[y]EXTRA TURN")
			else:
				textlog.push("[y]" + str(amount) + " EXTRA TURNS")
		elif amount < 0:
			for i in -amount:
				if player.ExtraTurns() > 0:
					player.addExtraTurns(-1, Card)
				else:
					enemy.addExtraTurns(1, Card)
			if amount == -1:
				textlog.push("[o]TURN LOSS")
			else:
				textlog.push("[o]" + str(-amount) + " TURN LOSSES")
		
func checkEnergy():
	var player
	var opponent
	if me.isPlayer():
		player = me
		opponent = enemy
	elif enemy.isPlayer():
		player = enemy
		opponent = me
	else:
		return
	
	var amount = 0
	while player.CurrentEnergy >= player.MaxEnergy:
		player.addExtraTurns(1)
		player.triggerMutation("Quick Thinker")
		if player.isAlive() && opponent.isAlive():
			amount += 1
		if player.hasEffect("Energized") || player.hasEffect("Stealth") || player.hasEffect("Invisibility"):
			player.CurrentEnergy -= player.MaxEnergy
		else:
			player.CurrentEnergy = 0
	while player.CurrentEnergy <= -20+player.MaxEnergy:
		if player.ExtraTurns() > 0:
			player.addExtraTurns(-1)
		else:
			enemy.addExtraTurns(1)
		if player.isAlive() && opponent.isAlive():
			amount -= 1
		#player.CurrentEnergy += 20-player.MaxEnergy
		player.CurrentEnergy = 0
	
	if amount > 0:
		if amount == 1:
			textlog.push("[y]EXTRA TURN")
		else:
			textlog.push("[y]" + str(amount) + " EXTRA TURNS")
	elif amount < 0:
		if amount == -1:
			textlog.push("[o]TURN LOSS")
		else:
			textlog.push("[o]" + str(-amount) + " TURN LOSSES")
	player.updateEnergy()

func addEffect(target, effectName, value, turns):
	var operators = "+-*/d"
	
	var valueStr = ""
	if typeof(value) == 2:
		valueStr = str(value)
	elif value != "N/A":
		if !" d " in value:
			valueStr = str(me.calculate(value))
		else:
			value = value.split(" ")
			for k in value.size():
				if !(value[k] in operators):
					value[k] = str(me.convertStat(value[k]))
				valueStr += value[k] + " "
			valueStr = valueStr.substr(0, len(valueStr)-1)
	turns = me.calculate(str(turns))
	if turns != 0:
		target.addEffect(effectName, valueStr, turns, null)
	if turns == -1 && "stackable" in Game.scriptgen.EffectScripts[effectName][0]:
		return int(valueStr)
	return turns

#deal damage functions
func calculateDirectDamage(damage, me, enemy, Card):
	if Card != null:
		if Card.cardType == "Attack":
			damage += me.Effects.getAllValues("Sharpen")
			damage += me.valueMutation("Sharp Claws")
			if Card.has("projectile"):
				damage += me.Effects.getAllValues("Swing")
				damage += me.Effects.getAllValues("Fuse")
			if me.hasEffect("Aim"):
				damage *= 2
	damage += me.valueMutation("Frenzy")*damage
	damage += enemy.valueMutation("Frenzy")*damage
	return damage
func dealDirectDamage(damage, Card):
	var dmg
	dmg = directDamage(damage, me, enemy, Card)
	return dmg
func takeDirectDamage(damage, Card):
	return directDamage(damage, me, me, Card)
func directDamage(damage, myself, opponent, Card):
	var calcdmg = calculateDirectDamage(damage, myself, opponent, Card)
	var usedmg = calcdmg
	
	if Card != null:
		if Card.cardType == "Attack":
			myself.tickEffect("Sharpen")
			if Card.has("projectile"):
				myself.tickEffect("Fuse")
			myself.tickEffect("Aim")
		usedmg += myself.valueMutation("Focused Rage", usedmg)
	if opponent.hasEffect("Phase"):
		opponent.increaseEffect("Phase", usedmg)
		usedmg = 0
	if (opponent.hasEffect("Dodge") || opponent.hasEffect("Elude") || opponent.hasEffect("Sense")) && opponent != myself && Card != null:
		usedmg = 0
	
	if opponent.hasEffect("Persist"):
		usedmg /= 2
		myself.tickEffect("Persist")
	if opponent.hasEffect("Parry"):
		usedmg /= 2
	
	if myself.hasMutation("Knockback") && Card != null:
		Card.savedValues["Knockback"] = usedmg
	if opponent.hasMutation("Shock Absorbers") && usedmg > opponent.convertStat("MHP"):
		opponent.triggerMutation("Shock Absorbers")
		
	if opponent.Shield() > 0:
		usedmg = 0
		change(opponent, "Shield", -1)
	elif usedmg > opponent.Block():
		usedmg -= opponent.Block()
		change(opponent, "Block", -opponent.Block())
	else:
		change(opponent, "Block", -usedmg)
		usedmg = 0
	if opponent.hasEffect("Permashield") && usedmg > 0:
		usedmg = 0
		opponent.addEffect("Permashield", -1, -1, Card)
	elif opponent.hasEffect("Permablock"):
		if usedmg > opponent.getEffect("Permablock"):
			usedmg -= opponent.getEffect("Permablock")
			opponent.removeEffect("Permablock")
		else:
			opponent.addEffect("Permablock", -usedmg, -1, Card)
			usedmg = 0
	
	if opponent.Effects.allyBlock(usedmg):
		usedmg = 0
		
	if opponent.hasMutation("Mana Veins"):
		if usedmg > opponent.CurrentMana:
			usedmg -= opponent.CurrentMana
			change(opponent, "Mana", -opponent.CurrentMana)
		else:
			change(opponent, "Mana", -usedmg)
			usedmg = 0
	
	if usedmg > 0:
		change(opponent, "Health", -usedmg)
	
	if Card != null:
		Card.cardProperties.append("Damage Dealt")
	
	return calcdmg
	
func calculateIndirectDamage(damage, me, enemy, Card):
	damage -= enemy.valueMutation("Tough Hide")
	if damage < 0:
		damage = 0
	if (enemy.hasEffect("Dodge") || enemy.hasEffect("Elude") || enemy.hasEffect("Sense")) && enemy != me && Card != null:
		damage = 0
	return damage
func dealIndirectDamage(damage, Card):
	return indirectDamage(damage, me, enemy, Card)
func takeIndirectDamage(damage, Card):
	return indirectDamage(damage, me, me, Card)
func indirectDamage(damage, myself, opponent, Card):
	var calcdmg = calculateIndirectDamage(damage, myself, opponent, Card)
	
	change(opponent, "Health", -calcdmg)
		
	return calcdmg

func directDamageOverTime(value, turns, target, Card):
	if (enemy.hasEffect("Dodge") || enemy.hasEffect("Elude") || enemy.hasEffect("Sense")) && target != me && Card != null:
		turns = 0
	
	Card.addEffect(target, "Take Damage", value, str(turns))
	return turns
	
func indirectDamageOverTime(value, turns, target, Card):
	if (enemy.hasEffect("Dodge") || enemy.hasEffect("Elude") || enemy.hasEffect("Sense")) && target != me && Card != null:
		turns = 0
		
	Card.addEffect(target, "Lose Health", value, str(turns))
	return turns
	
#gain health functions
func calculateHealth(health, me, enemy, Card):
	return health
func gainHealth(health, Card):
	return health(health, me, enemy, Card)
func health(health, myself, opponent, Card):
	var calchp = calculateHealth(health, myself, opponent, Card)
	
	calchp += myself.valueMutation("Hemoglobin")
	if myself.hasEffect("Shatter"):
		calchp = 0
	
	change(myself, "Health", calchp)
		
	return calchp

#gain mana functions
func calculateMana(mana, me, enemy, Card):
	return mana
func gainMana(mana, Card):
	return mana(mana, me, enemy, Card)
func mana(mana, myself, opponent, Card):
	var calcmana = calculateMana(mana, myself, opponent, Card)
	
	change(myself, "Mana", calcmana)
		
	return calcmana
	
#block functions
func calculateBlock(block, me, enemy, Card):
	return block
func gainBlock(block, Card, turns = 1):
	return block(block, me, enemy, Card, turns)
func block(block, myself, opponent, Card, turns = 1):
	var calcblock = calculateBlock(block, myself, opponent, Card)
	
	change(myself, "Block", calcblock, Card, turns)
		
	return calcblock

#shield functions
func calculateShield(shield, me, enemy, Card):
	return shield
func gainShield(shield, Card, turns = 1):
	return shield(shield, me, enemy, Card, turns)
func shield(shield, myself, opponent, Card, turns = 1):
	var calcshield = calculateShield(shield, myself, opponent, Card)
	
	change(myself, "Shield", calcshield, Card, turns)
		
	return calcshield
	
#distance functions
func gainDistance(distance, Card):
	return distance(distance, me, enemy, Card)
func distance(distance, myself, opponent, Card):
	var calcdistance = distance
	if myself.hasEffect("Suspend"):
		calcdistance = 0
	
	change(myself, "Distance", calcdistance, Card)
	
	return calcdistance


#gain energy functions
func calculateEnergy(energy, me, enemy, Card):
	if me.hasEffect("Invisibility") && energy < 0:
		energy = 0
	if (me.hasEffect("Tireless") || me.hasEffect("Sneak")) && energy < 0:
		energy = 0
		
	return energy
func gainEnergy(energy, Card):
	return energy(energy, me, enemy, Card)
func energy(energy, myself, opponent, Card):
	var calcenergy = calculateEnergy(energy, myself, opponent, Card)
	
	change(myself, "Energy", calcenergy)
		
	return calcenergy

func calculateExtraTurns(extraturns, me, enemy, Card):
	return extraturns
func gainExtraTurns(extraturns, Card):
	return extraTurns(extraturns, me, enemy, Card)
func extraTurns(extraturns, myself, opponent, Card):
	var calcet = calculateExtraTurns(extraturns, myself, opponent, Card)
	
	change(myself, "ExtraTurns", calcet, Card)
	
	return calcet

#pierce
func pierce(myself, opponent, Card):
	if !opponent.hasEffect("Unbreakable"):
		loseAllBlock(opponent, myself, Card)
		change(opponent, "Shield", -opponent.Shield())
		opponent.removeEffect("Permashield")
func selfPierce(myself, opponent, Card):
	if !myself.hasEffect("Unbreakable"):
		loseAllBlock(myself, opponent, Card)
		change(myself, "Shield", -myself.Shield())
		myself.removeEffect("Permashield")

#shuffle
func shuffle(myself, opponent, Card):
	opponent.currentCombatDeck.shuffleDeck(Card)
	#opponent.currentCombatDeck.shuffleAddPrint()
	
func selfShuffle(myself, opponent, Card):
	myself.currentCombatDeck.shuffleDeck(Card)

func fill(cardValue, myself, opponent, Card):
	myself.currentCombatDeck.forceFillHand(cardValue)

#loseBlock
func loseAllBlock(myself, opponent, Card):
	change(myself, "Block", -myself.Block())
	myself.removeEffect("Permablock")
