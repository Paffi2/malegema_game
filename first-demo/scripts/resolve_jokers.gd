extends RefCounted
class_name ResolveJokers


static func apply(tile_db: Dictionary, trigger_tile: Dictionary, rng: RandomNumberGenerator) -> void:
	var card := CardData.get_card_by_id(String(trigger_tile["card_id"]))
	if String(card.get("suit", "")) != "joker":
		return

	var current_tiles := _alive_tiles(tile_db)
	if current_tiles.size() <= 1:
		return

	var pick_order := _build_pick_order(current_tiles, rng)
	if pick_order.is_empty():
		return

	var pairs := _build_card_pairs(current_tiles)
	if pairs.is_empty() or pairs.size() * 2 != current_tiles.size():
		return

	var shuffled_pairs := _shuffle_array(pairs, rng)

	for i in range(0, pick_order.size(), 2):
		var tile1: Dictionary = pick_order[pick_order.size() - 1 - i]
		var tile2: Dictionary = pick_order[pick_order.size() - 2 - i]
		var pair: Array = shuffled_pairs[int(i / 2.0)]
		var source1: Dictionary = pair[0]
		var source2: Dictionary = pair[1]

		_assign_to_position(tile_db, String(tile1["id"]), source1)
		_assign_to_position(tile_db, String(tile2["id"]), source2)


static func _alive_tiles(tile_db: Dictionary) -> Array[Dictionary]:
	var alive: Array[Dictionary] = []
	for value in tile_db.values():
		var tile := value as Dictionary
		if bool(tile.get("deleted", false)):
			continue
		alive.append(tile.duplicate(true))
	return alive


static func _build_pick_order(current_tiles: Array[Dictionary], rng: RandomNumberGenerator) -> Array[Dictionary]:
	var new_tile_db: Dictionary = {}
	for tile in current_tiles:
		var id := String(tile["id"])
		new_tile_db[id] = {
			"id": id,
			"card_id": "bam1",
			"material": "bone",
			"x": int(tile["x"]),
			"y": int(tile["y"]),
			"z": int(tile["z"]),
			"deleted": false,
			"selected": false,
		}

	var pick_order: Array[Dictionary] = []
	while true:
		var free_tiles := TileRules.get_free_tiles(new_tile_db)
		if free_tiles.size() <= 1:
			break

		while free_tiles.size() > 1:
			var idx1 := int(floor(rng.randf() * free_tiles.size()))
			var tile1: Dictionary = free_tiles[idx1]
			free_tiles.remove_at(idx1)

			var idx2 := int(floor(rng.randf() * free_tiles.size()))
			var tile2: Dictionary = free_tiles[idx2]
			free_tiles.remove_at(idx2)

			new_tile_db.erase(String(tile1["id"]))
			new_tile_db.erase(String(tile2["id"]))
			pick_order.append(tile1)
			pick_order.append(tile2)

	if new_tile_db.size() > 0:
		return _build_pick_order(current_tiles, rng)

	return pick_order


static func _build_card_pairs(current_tiles: Array[Dictionary]) -> Array:
	var pairs: Array = []
	var used_ids: Dictionary = {}

	for i in range(current_tiles.size()):
		var tile1: Dictionary = current_tiles[i]
		var id1 := String(tile1["id"])
		if used_ids.has(id1):
			continue

		for j in range(i + 1, current_tiles.size()):
			var tile2: Dictionary = current_tiles[j]
			var id2 := String(tile2["id"])
			if used_ids.has(id2):
				continue
			if not _cards_match(String(tile1["card_id"]), String(tile2["card_id"])):
				continue

			pairs.append([tile1, tile2])
			used_ids[id1] = true
			used_ids[id2] = true
			break

	return pairs


static func _assign_to_position(tile_db: Dictionary, target_id: String, source_tile: Dictionary) -> void:
	if not tile_db.has(target_id):
		return
	var target: Dictionary = tile_db[target_id]
	target["card_id"] = String(source_tile["card_id"])
	target["material"] = String(source_tile.get("material", "bone"))
	target["deleted"] = false
	target["selected"] = false
	tile_db[target_id] = target


static func _cards_match(card_id1: String, card_id2: String) -> bool:
	if _is_flower(card_id1) and _is_flower(card_id2):
		return true

	if _frog_matches_lotus(card_id1, card_id2) or _frog_matches_lotus(card_id2, card_id1):
		return true

	return card_id1 == card_id2


static func _is_flower(card_id: String) -> bool:
	var card := CardData.get_card_by_id(card_id)
	return String(card.get("suit", "")) == "flower"


static func _frog_matches_lotus(card_id1: String, card_id2: String) -> bool:
	var card1 := CardData.get_card_by_id(card_id1)
	var card2 := CardData.get_card_by_id(card_id2)
	if String(card1.get("suit", "")) != "frog":
		return false
	if String(card2.get("suit", "")) != "lotus":
		return false
	return String(card1.get("rank", "")) == String(card2.get("rank", ""))


static func _shuffle_array(input: Array, rng: RandomNumberGenerator) -> Array:
	var arr: Array = input.duplicate(true)
	for i in range(arr.size() - 1, 0, -1):
		var j := int(floor(rng.randf() * float(i + 1)))
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr
