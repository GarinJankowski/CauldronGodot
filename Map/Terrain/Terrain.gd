extends Node2D

var x
var y
var z = 0
var terrain
var spritepath = "N/A"
var spriteTexture
var fogged = false
var tempFogged = false

var map
var guy
var Game

func init(px, py, terr):
	Game = get_parent().Game
	map = Game.map
	guy = Game.guy
	
	x = px
	y = py
	terrain = terr
	
	var sprite = get_node("Sprite")
	sprite.scale = Vector2(0.055, 0.055)
	
	if terrain == "Hills":
		fogged = true
		tempFogged = true
		get_node("fogSprite").set_texture(preload("res://Map/Terrain/Terrain Icons/terrain_Hills.png"))
		get_node("fogSprite").visible = true
		get_node("fogSprite").scale = Vector2(0.055, 0.055)
		
	makeSprite()
	
	
func Enter():
	map.currentTerrain = self
	map.get_node("Terrain/terrainIcon").set_texture(load(spritepath + ".png"))
	map.get_node("Terrain/terrainLabel").text = terrain
	pass

func changeTerrain(terr):
	terrain = terr
	makeSprite()

func makeSprite():
	var sprite = get_node("Sprite")
	if terrain == "City":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_City"
		z = 4
	elif terrain == "Hills":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Hills"
		z = 7
	elif terrain == "Forest":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Forest"
		z = 3
	elif terrain == "Sea":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Sea"
		z = 2
	elif terrain == "Desert":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Lava"
		z = 1
	elif terrain == "Treasure":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Treasure"
		z = 6
	elif terrain == "Wasteland":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Wasteland"
		z = 5
	elif terrain == "Field":
		spritepath = "res://Map/Terrain/Terrain Icons/terrain_Field"
		z = 2
	spritepath = "res://Map/Terrain/Terrain Icons/terrain_" + terrain
		
	if spritepath != "N/A":
		sprite.z_index = z
		sprite.set_texture(load(spritepath + ".png"))
		
	spriteTexture = get_node("Sprite").texture
	
func unfog():
	if terrain == "Hills":
		get_node("fogSprite").visible = false
		fogged = false
	
func roomClear():
	get_node("Sprite").z_index = 12
	get_node("Sprite").set_texture(preload("res://Map/Terrain/Terrain Icons/terrainCLEAR.png"))

func fog(on):
	if terrain == "Hills" && fogged:
		get_node("fogSprite").visible = on
		tempFogged = on
