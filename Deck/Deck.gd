extends Node2D

var holder

var cards = []
var cardsToBeDestroyed = []

var scriptgen

var Game

func init(h):
	Game = get_parent().Game
	holder = h
	scriptgen = Game.scriptgen
	
func addCard(cardName):
	var card = load("res://Card/Card.tscn").instance()
	add_child(card)
	card.init(cardName)
	cards.append(card)

func add(card):
	add_child(card)
	cards.append(card)
	
func removeCard(cardName):
	holder.Bag.destroyBagCard()
	for i in range(len(cards)):
		if cards[i].cardName == cardName:
			var c = cards[i]
			cards.remove(i)
			c.queue_free()
			
func leaveCombat():
	for card in cards:
		card.leaveCombat()
	destroyCards()

func destroy(card):
	if !card in cardsToBeDestroyed:
		cardsToBeDestroyed.append(card)
	
func destroyCards():
	while cardsToBeDestroyed.size() > 0:
		holder.Bag.destroyBagCard(cardsToBeDestroyed[0])
		cards.erase(cardsToBeDestroyed[0])
		holder.Bag.updateBagCards()
		cardsToBeDestroyed.pop_front().queue_free()
			
func remove(card):
	cards.erase(card)

func at(index):
	return cards[index]

func updateDescriptions():
	for card in cards:
		card.updateDescription()

func printDeck():
	for i in range(len(cards)):
		cards[i].printValues()

func size():
	return cards.size()
