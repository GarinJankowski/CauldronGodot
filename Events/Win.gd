extends "res://Events/Event.gd"

func init2(r):
	init(r)

func _process(delta):
	if Input.is_action_just_pressed("ui_accept") || Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
