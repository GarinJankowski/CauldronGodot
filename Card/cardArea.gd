extends Area2D

func _on_cardArea_area_entered(area):
	var card = get_parent()
	if area.get_name() == "cursorArea" && card.isUsable():
		get_parent().get_node("glow").visible = true
		get_parent().get_node("Top/nameBack").modulate = "50000000"
		get_parent().get_node("Top/costBack").modulate = "50000000"
		
		for key in card.mods:
			if card.mods[key]:
				card.get_node("Top/modBack/" + key + "back").modulate = "50000000"

func _on_cardArea_area_exited(area):
	if area.get_name() == "cursorArea" && get_parent().handIndex != -1:
		get_parent().get_node("glow").visible = false
		get_parent().get_node("Top/nameBack").modulate = "00000000"
		get_parent().get_node("Top/costBack").modulate = "00000000"
		var card = get_parent()
		for key in card.mods:
			card.get_node("Top/modBack/" + key + "back").modulate = "00000000"
