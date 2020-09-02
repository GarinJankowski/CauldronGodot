extends TextureButton

func _on_modButton_pressed():
	var Bag = get_parent().get_parent().get_parent().get_parent()
	if !Bag.guy.inCombat:
		Bag.applyMod(get_parent().name)

func _on_modButtonCard_pressed():
	var Bag = get_parent().get_parent().get_parent().get_parent().Bag
	if !Bag.guy.inCombat:
		Bag.removeMod(get_parent().name)

func _on_modArea_area_entered(area):
	if area.get_name() == "cursorArea":
		var Bag = get_parent().get_parent().get_parent().get_parent()
		if Bag.getMod(get_parent().name) > 0:
			Bag.Game.runeTooltip(true, get_parent().name)
		get_parent().get_node("mod/button_Mod").scale += Vector2(0.05, 0.05)
		if get_parent().get_parent().name == "forgeButtonsCard" && (get_parent().name == "Link" || get_parent().name == "Stay"):
			get_parent().get_node("mod/text").rect_scale += Vector2(0.3, 0.3)

func _on_modArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_parent().get_parent().get_parent().get_parent().get_parent().Game.runeTooltip(false)
		get_parent().get_node("mod/button_Mod").scale -= Vector2(0.05, 0.05)
		if get_parent().get_parent().name == "forgeButtonsCard" && (get_parent().name == "Link" || get_parent().name == "Stay"):
			get_parent().get_node("mod/text").rect_scale -= Vector2(0.3, 0.3)

func _on_modAreaDisplay_area_entered(area):
	if area.get_name() == "cursorArea":
		var display = get_parent().get_parent().get_parent().get_parent()
		if display.Card.hasMod(get_parent().name):
			display.Game.runeTooltip(true, get_parent().name)
		get_parent().get_node("mod/button_Mod").scale += Vector2(0.05, 0.05)
		if get_parent().get_parent().name == "forgeButtonsCard" && (get_parent().name == "Link" || get_parent().name == "Stay"):
			get_parent().get_node("mod/text").rect_scale += Vector2(0.3, 0.3)

func _on_modAreaDisplay_area_exited(area):
	if area.get_name() == "cursorArea":
		get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().get_parent().Game.runeTooltip(false)
		get_parent().get_node("mod/button_Mod").scale -= Vector2(0.05, 0.05)
		if get_parent().get_parent().name == "forgeButtonsCard" && (get_parent().name == "Link" || get_parent().name == "Stay"):
			get_parent().get_node("mod/text").rect_scale -= Vector2(0.3, 0.3)
