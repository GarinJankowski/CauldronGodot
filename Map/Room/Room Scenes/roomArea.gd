extends Area2D

func _on_roomArea_area_entered(area):
	var room = get_parent().get_parent()
	if area.get_name() == "cursorArea" && !room.guy.Bag.open && !room.guy.Body.open:
		room.Game.tileTooltip(true, room, room.terrain)

func _on_roomArea_area_exited(area):
	if area.get_name() == "cursorArea":
		get_parent().get_parent().Game.tileTooltip(false)
