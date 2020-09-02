extends TextureButton

func _pressed():
	var index = get_parent().handIndex
	if index == 0:
		Input.action_press("number_1")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_1")
	elif index == 1:
		Input.action_press("number_2")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_2")
	elif index == 2:
		Input.action_press("number_3")
		yield(get_tree().create_timer(0.001), "timeout")
		Input.action_release("number_3")
