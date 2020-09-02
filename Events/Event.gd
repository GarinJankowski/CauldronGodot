extends Node2D

var guy
var map
var room
var textlog
var itemgen

var close = false

var Game

func init(r):
	Game = get_parent().Game
	guy = Game.guy
	map = Game.map
	room = r
	itemgen = Game.itemgen
	textlog = Game.textlog
	map.setCurrentEvent(self)

func end():
	room.nextEvent()
	close = true
