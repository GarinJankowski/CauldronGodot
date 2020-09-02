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
func change(who, type, amount, Card = null):
	if who.hasEffect("Nullify") && (type == "CurrentHealth" || type == "Mana" || type == "Energy"):
		return
	if type == "CurrentHealth":
		who.CurrentHealth += amount
		if who.CurrentHealth < 0:
			who.CurrentHealth = 0
		elif who.CurrentHealth > who.MaxHealth + who.tempMaxHealth:
			who.CurrentHealth = who.MaxHealth + who.tempMaxHealth
		if who.hasEffect("Stranglehold (Attacker)") && amount < 0:
			who.addStranglehold(amount, Card)
		who.updateHealth()
		#if CombatEvent != null:
			#CombatEvent.checkDeath()
	elif type == "Mana":
		who.CurrentMana += amount
		if who.CurrentMana < 0:
			who.CurrentMana = 0
		elif who.CurrentMana > who.MaxMana + who.tempMaxMana:
			who.CurrentMana = who.MaxMana + who.tempMaxMana
		if who.isPlayer():
			who.updateMana()
	elif type == "Block":
		who.addBlock(amount, Card)
	elif type == "Shield":
		who.addShield(amount, Card)
	elif type == "Energy" && who.isPlayer():
		who.CurrentEnergy += amount
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

#deal damage functions
func calculateDirectDamage(damage, me, enemy, Card):
	if me.hasEffect("Augment") && Card != null && Card.cardType == "Attack":
		damage += me.getEffect("Augment")
	if enemy.hasEffect("Persist"):
		damage /= 2
		me.tickEffect("Persist")
	if me.hasEffect("Curse"):
		damage = 0
		me.tickEffect("Curse")
	if enemy.hasEffect("Dodge") && enemy != me && Card != null:
		damage = 0
	if enemy.hasEffect("Elude") && enemy != me && Card != null:
		damage = 0
	if enemy.Shield() > 0:
		damage = 0
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
	
	if me.hasEffect("Augment") && Card != null && Card.cardType == "Attack":
		me.tickEffect("Augment")
		me.removeEffect("Augment")
		
	if opponent.Shield() > 0:
		change(opponent, "Shield", -1)
	elif(usedmg > opponent.Block()):
		usedmg -= opponent.Block()
		change(opponent, "Block", -opponent.Block())
	else:
		change(opponent, "Block", -usedmg)
		usedmg = 0
	
	if opponent.Effects.allyBlock(usedmg):
		usedmg = 0
	
	if usedmg > 0:
		change(opponent, "CurrentHealth", -usedmg)
	
	if Card != null:
		Card.cardProperties.append("Damage Dealt")
	
	return calcdmg
	
func calculateIndirectDamage(damage, me, enemy, Card):
	return damage
func dealIndirectDamage(damage, Card):
	return indirectDamage(damage, me, enemy, Card)
func takeIndirectDamage(damage, Card):
	return indirectDamage(damage, me, me, Card)
func indirectDamage(damage, myself, opponent, Card):
	var calcdmg = calculateIndirectDamage(damage, myself, opponent, Card)
	
	change(opponent, "CurrentHealth", -calcdmg)
		
	return calcdmg

func directDamageOverTime(value, turns, target, Card):
	if target.hasEffect("Dodge") && target != me && Card != null:
		turns = 0
	if target.hasEffect("Elude") && target != me && Card != null:
		turns = 0
	
	Card.addEffect(target, "Take Damage", value, str(turns))
	return turns
	
func indirectDamageOverTime(value, turns, target, Card):
	if target.hasEffect("Dodge") && target != me && Card != null:
		turns = 0
	if target.hasEffect("Elude") && target != me && Card != null:
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
	
	change(myself, "CurrentHealth", calchp)
		
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
func gainBlock(block, Card):
	return block(block, me, enemy, Card)
func block(block, myself, opponent, Card):
	var calcblock = calculateBlock(block, myself, opponent, Card)
	
	change(myself, "Block", calcblock, Card)
		
	return calcblock

#shield functions
func calculateShield(shield, me, enemy, Card):
	return shield
func gainShield(shield, Card):
	return shield(shield, me, enemy, Card)
func shield(shield, myself, opponent, Card):
	var calcshield = calculateShield(shield, myself, opponent, Card)
	
	change(myself, "Shield", calcshield, Card)
		
	return calcshield

#gain energy functions
func calculateEnergy(energy, me, enemy, Card):
	if me.hasEffect("Weightless") && Card != null:
		energy *= 2
		me.addEffect("Weightless", -1, "Good")
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
func selfPierce(myself, opponent, Card):
	if !myself.hasEffect("Unbreakable"):
		loseAllBlock(myself, opponent, Card)
		change(myself, "Shield", -myself.Shield())

#shuffle
func shuffle(myself, opponent, Card):
	opponent.currentCombatDeck.shuffleDeck(Card)
	#opponent.currentCombatDeck.shuffleAddPrint()

func fill(cardValue, myself, opponent, Card):
	myself.currentCombatDeck.forceFillHand(cardValue)

#loseBlock
func loseAllBlock(myself, opponent, Card):
	change(myself, "Block", -myself.Block())