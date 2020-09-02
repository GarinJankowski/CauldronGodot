extends Node2D

var guy
var Bag

var cardName
var cardType

var ticks = 0
var cost
var purchased = false

var Game

func init(Card, val):
	Game = get_parent().get_parent().Game
	guy = Game.guy
	Bag = guy.Bag
	
	cardName = Card.cardName
	cardType = Card.cardType
	
	cost = val
	get_node("cost/Label").text = str(cost) + "g"
	get_node("Top/cardSprite").set_texture(Card.get_node("Top/cardSprite").texture)
	get_node("Top/cardCost").visible = Card.get_node("Top/cardCost").visible
	get_node("Top/nameText").text = Card.cardName
	get_node("Top/descriptionText").text = Card.cardDescription
	get_node("Top/costText").text = Card.get_node("Top/costText").text
	get_node("Top/costText").visible = Card.get_node("Top/costText").visible
	
	var dynamicFont = Card.dynamicFont
	get_node("Top/nameText").add_font_override("font", dynamicFont)
	
	checkBuyable()

func _process(delta):
	if ticks > 0:
		get_node("Top").position.x += 45
		if ticks == 0:
			get_node("Top").visible = false

func checkBuyable():
	if purchased:
		get_node("cost").modulate = "7c7c7c"
	elif cost > guy.Gold:
		get_node("Top").modulate = "6effffff"
		get_node("cost").modulate = "7c7c7c"
		
func enableAreaCollisions(truefalse):
	get_node("cardArea/cardCollision").disabled = !truefalse

func _on_buttonCard_pressed():
	if cost <= guy.Gold:
		purchased = true
		ticks = 15
		guy.gainGold(-cost)
		enableAreaCollisions(false)
		get_node("buttonCard").disabled = true
		get_parent().get_parent().updateShop()
		
		Bag.addCard(cardName, cardType)

func _on_cardArea_area_entered(area):
	if area.get_name() == "cursorArea" && cost <= guy.Gold:
		get_node("glow").visible = true
		get_node("cost/glow").visible = true

func _on_cardArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_node("glow").visible = false
		get_node("cost/glow").visible = false
