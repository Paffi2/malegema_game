extends RefCounted
class_name ResolveGems


static func apply(game_state: Dictionary, tile: Dictionary) -> void:
	var card_id := String(tile["card_id"])
	var card := CardData.get_card_by_id(card_id)
	if String(card.get("suit", "")) != "gem":
		game_state["temporary_material"] = ""
		return

	var color := ""
	var colors = card.get("colors", [])
	if colors is Array and (colors as Array).size() > 0:
		color = String((colors as Array)[0])

	match color:
		"r":
			game_state["temporary_material"] = "garnet"
		"g":
			game_state["temporary_material"] = "jade"
		"b":
			game_state["temporary_material"] = "topaz"
		"k":
			game_state["temporary_material"] = "quartz"
		_:
			game_state["temporary_material"] = ""
