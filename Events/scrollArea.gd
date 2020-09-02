extends Area2D

func _on_scrollArea_area_entered(area):
	if area.get_name() == "cursorArea":
		get_parent().get_node("glow").visible = true
		if get_parent().name == "sight" || get_parent().name == "time":
			get_parent().get_parent().map.showScrollIndicator(true)

func _on_scrollArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_parent().get_node("glow").visible = false
		if get_parent().name == "sight" || get_parent().name == "time":
			get_parent().get_parent().map.showScrollIndicator(false)
