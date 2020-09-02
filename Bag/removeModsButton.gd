extends TextureButton

func _on_removeModsButton_button_down():
	get_parent().get_node("button_RemoveMods").scale -= Vector2(0.002, 0.002)

func _on_removeModsButton_button_up():
	get_parent().get_node("button_RemoveMods").scale += Vector2(0.002, 0.002)


func _on_removeModsButton_pressed():
	var Bag = get_parent().get_parent().get_parent()
	
	if get_parent().name == "removeModsButtonDeck":
		for key in Bag.bagCardList:
			for bagCard in Bag.bagCardList[key]:
				bagCard.removeAllMods()
	elif get_parent().name == "removeModsButtonGear":
		Bag.noWeapon.removeAllMods()
		Bag.noArmor.removeAllMods()
		Bag.noHeadgear.removeAllMods()
		for key in Bag.bagGearEquipped:
			Bag.bagGearEquipped[key].removeAllMods()
	elif get_parent().name == "removeModsButtonBag":
		for bagGear in Bag.bagGearList:
			bagGear.removeAllMods()
	elif get_parent().name == "removeModsButtonNoWeapon":
		Bag.noWeapon.removeAllMods()
	elif get_parent().name == "removeModsButtonNoArmor":
		Bag.noArmor.removeAllMods()
	elif get_parent().name == "removeModsButtonNoHeadgear":
		Bag.noHeadgear.removeAllMods()
	elif get_parent().name == "removeModsButtonBagGear":
		Bag = get_parent().get_parent().Bag
		get_parent().get_parent().removeAllMods()
	elif get_parent().name == "removeModsButtonBagCard":
		Bag = get_parent().get_parent().Bag
		get_parent().get_parent().removeAllMods()
	
	Bag.checkMods()
