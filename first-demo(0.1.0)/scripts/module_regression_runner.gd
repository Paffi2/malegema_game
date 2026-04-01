extends SceneTree

const FIXED_SEED := 20260319
const MAX_STEPS := 2000
const PAIR_COUNT := 24


func _init() -> void:
	var all_passed := true
	var stage_results: Array[Dictionary] = []

	for i in range(GameLoop.MODULE_ORDER.size()):
		var enabled_modules: Array = GameLoop.MODULE_ORDER.slice(0, i + 1)
		var result := _run_single_stage(enabled_modules)
		stage_results.append(result)
		if not bool(result.get("passed", false)):
			all_passed = false

	for result_variant in stage_results:
		var result: Dictionary = result_variant
		print(_format_result_line(result))

	if all_passed:
		print("module regression: PASS")
		quit(0)
	else:
		print("module regression: FAIL")
		quit(1)


func _run_single_stage(enabled_modules: Array) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = FIXED_SEED

	var deck := _build_seed_deck(PAIR_COUNT)
	var tile_db := SetupTiles.setup_tiles(rng, deck)
	var game_state: Dictionary = {
		"points": 0,
		"end_condition": "",
		"dragon_run": {},
		"phoenix_run": {},
		"temporary_material": "",
		"enabled_modules": enabled_modules.duplicate(),
		"rng": rng,
	}

	var steps := 0
	var fail_reason := ""

	while steps < MAX_STEPS:
		var end_condition := String(game_state.get("end_condition", ""))
		if end_condition != "":
			break

		var pairs: Array = GameLoop.get_available_pairs(tile_db)
		if pairs.is_empty():
			game_state["end_condition"] = GameLoop.game_over_condition(tile_db)
			break

		var pair := _pick_pair_deterministic(pairs)
		if pair.is_empty():
			fail_reason = "pair-pick-failed"
			break

		var tile1: Dictionary = pair[0]
		var tile2: Dictionary = pair[1]
		var before_alive := _alive_count(tile_db)

		var r1 := GameLoop.select_tile(tile_db, game_state, String(tile1["id"]))
		if String(r1.get("kind", "")) == "invalid":
			fail_reason = "first-select-invalid"
			break

		var r2 := GameLoop.select_tile(tile_db, game_state, String(tile2["id"]))
		if String(r2.get("kind", "")) != "matched":
			fail_reason = "second-select-not-matched"
			break

		var after_alive := _alive_count(tile_db)
		if after_alive > before_alive:
			fail_reason = "alive-count-increased"
			break

		steps += 1

	var condition := String(game_state.get("end_condition", ""))
	if condition == "":
		condition = GameLoop.game_over_condition(tile_db)

	var passed := fail_reason == "" and (condition == "empty-board" or condition == "no-pairs")
	if fail_reason == "" and not passed:
		fail_reason = "invalid-end-condition"

	return {
		"passed": passed,
		"modules": enabled_modules.duplicate(),
		"steps": steps,
		"points": int(game_state.get("points", 0)),
		"end_condition": condition,
		"fail_reason": fail_reason,
	}


func _build_seed_deck(pair_count: int) -> Array[Dictionary]:
	var seed_cards: Array[String] = [
		"dragonr",
		"phoenix",
		"gemr",
		"mutation1",
		"windn",
		"joker",
		"bam1",
		"bam2",
		"bam3",
		"crack1",
		"crack2",
		"dot1",
	]

	var card_ids: Array[String] = []
	while card_ids.size() < pair_count:
		for card_id in seed_cards:
			card_ids.append(card_id)
			if card_ids.size() >= pair_count:
				break

	var deck: Array[Dictionary] = []
	for i in range(card_ids.size()):
		deck.append({
			"id": str(i),
			"cardId": card_ids[i],
			"material": "bone",
		})
	return deck


func _pick_pair_deterministic(pairs: Array) -> Array:
	var best_pair: Array = []
	var best_key := ""

	for pair_variant in pairs:
		var pair := pair_variant as Array
		if pair.size() < 2:
			continue
		var tile1: Dictionary = pair[0]
		var tile2: Dictionary = pair[1]
		var id1 := String(tile1["id"])
		var id2 := String(tile2["id"])
		var low := id1 if id1 < id2 else id2
		var high := id2 if id1 < id2 else id1
		var key := low + ":" + high

		if best_key == "" or key < best_key:
			best_key = key
			best_pair = [tile1, tile2]

	return best_pair


func _alive_count(tile_db: Dictionary) -> int:
	var count := 0
	for value in tile_db.values():
		var tile := value as Dictionary
		if not bool(tile.get("deleted", false)):
			count += 1
	return count


func _format_result_line(result: Dictionary) -> String:
	var modules := result.get("modules", [])
	var passed := bool(result.get("passed", false))
	var status := "PASS" if passed else "FAIL"
	return "%s modules=%s steps=%d points=%d end=%s reason=%s" % [
		status,
		str(modules),
		int(result.get("steps", 0)),
		int(result.get("points", 0)),
		String(result.get("end_condition", "")),
		String(result.get("fail_reason", "")),
	]
