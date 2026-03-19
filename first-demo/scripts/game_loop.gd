extends RefCounted
class_name GameLoop

const MODULE_DRAGONS := "dragons"
const MODULE_PHOENIXES := "phoenixes"
const MODULE_GEMS := "gems"
const MODULE_MUTATIONS := "mutations"
const MODULE_WINDS := "winds"
const MODULE_JOKERS := "jokers"

const MODULE_ORDER := [
	MODULE_DRAGONS,
	MODULE_PHOENIXES,
	MODULE_GEMS,
	MODULE_MUTATIONS,
	MODULE_WINDS,
	MODULE_JOKERS,
]


static func game_over_condition(tile_db: Dictionary) -> String:
	var alive_count := 0
	for tile in tile_db.values():
		if not bool((tile as Dictionary).get("deleted", false)):
			alive_count += 1

	if alive_count == 0:
		return "empty-board"

	var pairs := get_available_pairs(tile_db)
	if pairs.is_empty():
		return "no-pairs"

	return ""


static func get_available_pairs(tile_db: Dictionary) -> Array:
	var tiles := TileRules.get_free_tiles(tile_db)
	var pairs: Array = []

	for i in range(tiles.size()):
		for j in range(i + 1, tiles.size()):
			var tile1: Dictionary = tiles[i]
			var tile2: Dictionary = tiles[j]
			if not cards_match(String(tile1["card_id"]), String(tile2["card_id"])):
				continue
			pairs.append([tile1, tile2])

	return pairs


static func select_tile(tile_db: Dictionary, game_state: Dictionary, tile_id: String) -> Dictionary:
	if not tile_db.has(tile_id):
		return {"kind": "invalid", "message": "tile not found"}

	var tile: Dictionary = tile_db[tile_id]
	if bool(tile.get("deleted", false)):
		return {"kind": "invalid", "message": "tile already deleted"}

	var first_tile := _find_selected_tile(tile_db)
	if first_tile.is_empty():
		tile["selected"] = true
		tile_db[tile_id] = tile
		return {"kind": "selected-first", "tile_id": tile_id}

	if String(first_tile["id"]) == tile_id:
		tile["selected"] = false
		tile_db[tile_id] = tile
		return {"kind": "unselected", "tile_id": tile_id}

	first_tile["selected"] = false
	tile_db[String(first_tile["id"])] = first_tile

	if cards_match(String(first_tile["card_id"]), String(tile["card_id"])):
		_apply_pre_delete_modules(tile_db, game_state, tile)
		delete_tiles(tile_db, [String(first_tile["id"]), tile_id])
		var points := get_points(first_tile, game_state) + get_points(tile, game_state)
		game_state["points"] = int(game_state.get("points", 0)) + points
		_apply_post_delete_modules(tile_db, game_state, tile)

		var condition := game_over_condition(tile_db)
		if condition != "":
			game_state["end_condition"] = condition

		return {
			"kind": "matched",
			"points": points,
			"total_points": int(game_state["points"]),
			"end_condition": String(game_state.get("end_condition", "")),
		}

	var jumped := _resolve_jumping_tiles(tile_db, first_tile, tile)
	if not jumped:
		tile["selected"] = false
		tile_db[tile_id] = tile

	var condition2 := game_over_condition(tile_db)
	if condition2 != "":
		game_state["end_condition"] = condition2

	return {
		"kind": "mismatch",
		"jumped": jumped,
		"end_condition": String(game_state.get("end_condition", "")),
	}


static func cards_match(card_id1: String, card_id2: String) -> bool:
	if _is_flower(card_id1) and _is_flower(card_id2):
		return true

	if _frog_matches_lotus(card_id1, card_id2) or _frog_matches_lotus(card_id2, card_id1):
		return true

	return card_id1 == card_id2


static func delete_tiles(tile_db: Dictionary, tile_ids: Array[String]) -> void:
	for tile_id in tile_ids:
		if not tile_db.has(tile_id):
			continue
		var tile: Dictionary = tile_db[tile_id]
		tile["deleted"] = true
		tile["selected"] = false
		tile_db[tile_id] = tile


static func get_points(tile: Dictionary, game_state: Dictionary) -> int:
	var card_id := String(tile["card_id"])
	var material := _resolve_material(tile, game_state)
	var card := CardData.get_card_by_id(card_id)
	var card_points := int(card.get("points", 0))
	var base_points := card_points + _get_material_points(material)

	var dragon_combo := int((game_state.get("dragon_run", {}) as Dictionary).get("combo", 0))
	var phoenix_combo := int((game_state.get("phoenix_run", {}) as Dictionary).get("combo", 0))
	var multiplier := maxi(1, dragon_combo + phoenix_combo * 2)
	return base_points * multiplier


static func _get_material_points(material: String) -> int:
	match material:
		"topaz", "quartz", "garnet":
			return 1
		"jade":
			return 2
		"sapphire", "obsidian", "ruby":
			return 24
		"emerald":
			return 48
		_:
			return 0


static func _find_selected_tile(tile_db: Dictionary) -> Dictionary:
	for tile in tile_db.values():
		var t := tile as Dictionary
		if bool(t.get("deleted", false)):
			continue
		if bool(t.get("selected", false)):
			return t
	return {}


static func _frog_matches_lotus(card_id1: String, card_id2: String) -> bool:
	var card1 := CardData.get_card_by_id(card_id1)
	var card2 := CardData.get_card_by_id(card_id2)
	if String(card1.get("suit", "")) != "frog":
		return false
	if String(card2.get("suit", "")) != "lotus":
		return false

	return String(card1.get("rank", "")) == String(card2.get("rank", ""))


static func _is_flower(card_id: String) -> bool:
	var card := CardData.get_card_by_id(card_id)
	return String(card.get("suit", "")) == "flower"


static func _resolve_material(tile: Dictionary, game_state: Dictionary) -> String:
	var temp := String(game_state.get("temporary_material", ""))
	if temp == "":
		return String(tile.get("material", "bone"))

	var evolved := {
		"topaz": "sapphire",
		"garnet": "ruby",
		"jade": "emerald",
		"quartz": "obsidian",
	}
	if String(tile.get("material", "bone")) == "bone":
		return temp
	return String(evolved.get(temp, temp))


static func _is_module_enabled(game_state: Dictionary, module_name: String) -> bool:
	if not game_state.has("enabled_modules"):
		return true
	var enabled = game_state["enabled_modules"]
	if not (enabled is Array):
		return true
	return (enabled as Array).has(module_name)


static func _apply_pre_delete_modules(tile_db: Dictionary, game_state: Dictionary, tile: Dictionary) -> void:
	if _is_module_enabled(game_state, MODULE_DRAGONS):
		ResolveDragons.apply(game_state, tile)
	if _is_module_enabled(game_state, MODULE_PHOENIXES):
		ResolvePhoenixes.apply(game_state, tile)
	if _is_module_enabled(game_state, MODULE_MUTATIONS):
		ResolveMutations.apply(tile_db, tile)


static func _apply_post_delete_modules(tile_db: Dictionary, game_state: Dictionary, tile: Dictionary) -> void:
	if _is_module_enabled(game_state, MODULE_GEMS):
		ResolveGems.apply(game_state, tile)

	if _is_module_enabled(game_state, MODULE_JOKERS):
		var rng: RandomNumberGenerator = game_state.get("rng", null)
		if rng == null:
			rng = RandomNumberGenerator.new()
			rng.randomize()
			game_state["rng"] = rng
		ResolveJokers.apply(tile_db, tile, rng)

	if _is_module_enabled(game_state, MODULE_WINDS):
		ResolveWinds.apply(tile_db, tile)


# 当前阶段先保留跳跃逻辑占位，后续实现 frog/sparrow/lotus 等行为。
static func _resolve_jumping_tiles(_tile_db: Dictionary, _tile1: Dictionary, _tile2: Dictionary) -> bool:
	return false
