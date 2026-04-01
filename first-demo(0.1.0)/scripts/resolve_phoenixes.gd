extends RefCounted
class_name ResolvePhoenixes


static func apply(game_state: Dictionary, tile: Dictionary) -> void:
	var card_id := String(tile["card_id"])
	var card := CardData.get_card_by_id(card_id)
	var suit := String(card.get("suit", ""))
	if not game_state.has("phoenix_run"):
		game_state["phoenix_run"] = {}

	var run: Dictionary = game_state["phoenix_run"]
	if run.is_empty():
		if suit == "phoenix" and _can_start(game_state):
			game_state["phoenix_run"] = {"number": -1, "combo": 1}
		return

	var current_number := int(run.get("number", -1))
	var rank_number := _parse_rank_number(card_id)
	if rank_number == -1:
		if suit == "phoenix" and _can_start(game_state):
			game_state["phoenix_run"] = {"number": -1, "combo": 1}
		else:
			game_state["phoenix_run"] = {}
		return

	if current_number != -1 and rank_number != _next_number(current_number):
		if suit == "phoenix" and _can_start(game_state):
			game_state["phoenix_run"] = {"number": -1, "combo": 1}
		else:
			game_state["phoenix_run"] = {}
		return

	var combo := int(run.get("combo", 0))
	if combo >= 10:
		game_state["phoenix_run"] = {}
	else:
		run["combo"] = combo + 1
		run["number"] = rank_number
		game_state["phoenix_run"] = run


static func _can_start(game_state: Dictionary) -> bool:
	var dragon: Dictionary = game_state.get("dragon_run", {}) as Dictionary
	return dragon.is_empty()


static func _parse_rank_number(card_id: String) -> int:
	var card := CardData.get_card_by_id(card_id)
	var rank_str := String(card.get("rank", ""))
	if rank_str == "":
		return -1
	if not rank_str.is_valid_int():
		return -1
	return int(rank_str)


static func _next_number(number: int) -> int:
	if number == 9:
		return 1
	return number + 1
