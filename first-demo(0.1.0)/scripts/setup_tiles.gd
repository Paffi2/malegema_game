extends RefCounted
class_name SetupTiles


# 复现 whatajong setupTiles.ts：
# 1) 用 dummy 牌在布局中反复抽取可消对。
# 2) 若无法清空则重试。
# 3) 将真实牌对按逆序回填，得到可解局面。
static func setup_tiles(rng: RandomNumberGenerator, deck: Array[Dictionary]) -> Dictionary:
	var tile_db: Dictionary = {}
	var map: Array = ResponsiveMapData.get_limited_map(deck.size() * 2)

	for z in range(TileRules.map_get_levels(map)):
		for y in range(TileRules.map_get_height(map)):
			for x in range(TileRules.map_get_width(map)):
				var tile_id = TileRules.map_get(map, x, y, z)
				var prev_id = TileRules.map_get(map, x - 1, y, z)
				var above_id = TileRules.map_get(map, x, y - 1, z)
				var same_as_prev = prev_id != null and prev_id == tile_id
				var same_as_above = above_id != null and above_id == tile_id

				if tile_id != null and not same_as_prev and not same_as_above:
					tile_db[tile_id] = {
						"id": tile_id,
						"card_id": "bam1",
						"material": "bone",
						"x": x,
						"y": y,
						"z": z,
						"deleted": false,
						"selected": false,
					}

	var pick_order: Array[Dictionary] = []

	while true:
		var free_tiles := TileRules.get_free_tiles(tile_db)
		if free_tiles.size() <= 1:
			break

		while free_tiles.size() > 1:
			var idx1 := int(floor(rng.randf() * free_tiles.size()))
			var tile1: Dictionary = free_tiles[idx1]
			free_tiles.remove_at(idx1)

			var idx2 := int(floor(rng.randf() * free_tiles.size()))
			var tile2: Dictionary = free_tiles[idx2]
			free_tiles.remove_at(idx2)

			tile_db.erase(tile1["id"])
			tile_db.erase(tile2["id"])
			pick_order.append(tile1)
			pick_order.append(tile2)

	if tile_db.size() > 0:
		return setup_tiles(rng, deck)

	var pairs: Array = []
	for deck_tile in deck:
		pairs.append([deck_tile, deck_tile])
	var shuffled_pairs: Array = _shuffle_array(pairs, rng)

	var result: Dictionary = {}
	for i in range(0, pick_order.size(), 2):
		var tile1: Dictionary = pick_order[pick_order.size() - 1 - i]
		var tile2: Dictionary = pick_order[pick_order.size() - 2 - i]

		var pair: Array = shuffled_pairs[int(i / 2.0)]
		var deck_tile1: Dictionary = pair[0]
		var deck_tile2: Dictionary = pair[1]

		var id1 = TileRules.map_get(map, int(tile1["x"]), int(tile1["y"]), int(tile1["z"]))
		var id2 = TileRules.map_get(map, int(tile2["x"]), int(tile2["y"]), int(tile2["z"]))

		result[id1] = {
			"id": id1,
			"card_id": String(deck_tile1["cardId"]),
			"material": String(deck_tile1.get("material", "bone")),
			"x": int(tile1["x"]),
			"y": int(tile1["y"]),
			"z": int(tile1["z"]),
			"deleted": false,
			"selected": false,
		}
		result[id2] = {
			"id": id2,
			"card_id": String(deck_tile2["cardId"]),
			"material": String(deck_tile2.get("material", "bone")),
			"x": int(tile2["x"]),
			"y": int(tile2["y"]),
			"z": int(tile2["z"]),
			"deleted": false,
			"selected": false,
		}

	return result


static func _shuffle_array(input: Array, rng: RandomNumberGenerator) -> Array:
	var arr: Array = input.duplicate(true)
	for i in range(arr.size() - 1, 0, -1):
		var j := int(floor(rng.randf() * float(i + 1)))
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
	return arr
