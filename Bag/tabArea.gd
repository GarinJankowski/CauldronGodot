extends Area2D

onready var parent = get_parent().get_parent()

func _on_tabArea_area_entered(area):
	if area.get_name() == "cursorArea":
		parent.tabhover = get_parent().name
		if parent.tabhover == "noWeaponTab":
			parent.open(parent.Bag.noWeapon)
		elif parent.tabhover == "noArmorTab":
			parent.open(parent.Bag.noArmor)
		elif parent.tabhover == "noHeadgearTab":
			parent.open(parent.Bag.noHeadgear)

func _on_tabArea_area_exited(area):
	if area.get_name() == "cursorArea":
		parent.tabhover = ""
		parent.close()
