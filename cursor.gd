extends Node2D

onready var cursorSprite = get_node("cursorSprite")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _process(delta):
	position = get_global_mouse_position()
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		cursorSprite.rotation = -0.08
	else:
		cursorSprite.rotation = 0
