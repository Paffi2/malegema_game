extends RefCounted
class_name ResolveDragons


static func apply(game_state: Dictionary, tile: Dictionary) -> void:
	var card_id := String(tile["card_id"])
	var card := CardData.get_card_by_id(card_id)
	if String(card.get("suit", "")) != "dragon":
		_reset_or_keep(game_state, false, "")
		return

	var color := String(card.get("rank", ""))
	if not game_state.has("dragon_run") or (game_state["dragon_run"] as Dictionary).is_empty():
		game_state["dragon_run"] = {"color": color, "combo": 1}
		return

	var run: Dictionary = game_state["dragon_run"]
	if String(run.get("color", "")) != color:
		game_state["dragon_run"] = {"color": color, "combo": 1}
		return

	var combo := int(run.get("combo", 0))
	if combo >= 10:
		game_state["dragon_run"] = {}
	else:
		run["combo"] = combo + 1
		game_state["dragon_run"] = run


static func _reset_or_keep(game_state: Dictionary, is_dragon: bool, color: String) -> void:
	if not game_state.has("dragon_run"):
		game_state["dragon_run"] = {}
	if is_dragon:
		game_state["dragon_run"] = {"color": color, "combo": 1}
	else:
		game_state["dragon_run"] = {}
