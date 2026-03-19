extends RefCounted
class_name ResolveWinds

const BIASES := {
	"n": ["y", -2],
	"s": ["y", 2],
	"e": ["x", 2],
	"w": ["x", -2],
}


static func apply(tile_db: Dictionary, tile: Dictionary) -> void:
	var card := CardData.get_card_by_id(String(tile["card_id"]))
	if String(card.get("suit", "")) != "wind":
		return

	var wind := String(card.get("rank", ""))
	if not BIASES.has(wind):
		return

	var axis := String(BIASES[wind][0])
	var bias := int(BIASES[wind][1])
	var highest_level := 0
	for t in tile_db.values():
		highest_level = maxi(highest_level, int((t as Dictionary)["z"]))

	for z in range(1, highest_level + 1):
		var z_tiles: Array[Dictionary] = []
		for t in tile_db.values():
			var td := t as Dictionary
			if bool(td.get("deleted", false)):
				continue
			if int(td["z"]) == z:
				z_tiles.append(td)

		var direction := signi(bias)
		z_tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return direction * (int(b[axis]) - int(a[axis])) < 0
		)

		for z_tile in z_tiles:
			var moved := _get_new_tile(tile_db, z_tile, axis, bias)
			if moved.is_empty():
				continue
			var tile_id := String(z_tile["id"])
			tile_db[tile_id] = moved


static func _get_new_tile(tile_db: Dictionary, tile: Dictionary, axis: String, bias: int) -> Dictionary:
	if bias == 0:
		return {}

	var map = ResponsiveMapData.RESPONSIVE_MAP
	var map_size := {
		"x": TileRules.map_get_width(map),
		"y": TileRules.map_get_height(map),
	}
	var value := int(tile[axis])
	var direction := signi(bias)

	if value == 0 and direction == -1:
		return {}
	if value == int(map_size[axis]) - 1 and direction == 1:
		return {}

	for attempt in range(absi(bias), 0, -1):
		var displacement := attempt * direction
		var new_value := value + displacement

		var new_tile: Dictionary = tile.duplicate(true)
		new_tile[axis] = new_value
		if TileRules.overlaps(tile_db, new_tile, 0) != null:
			continue
		if not TileRules.fully_overlaps(tile_db, new_tile, -1):
			continue
		return new_tile

	return {}
