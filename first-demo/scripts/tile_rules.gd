extends RefCounted
class_name TileRules


static func coord(position: Dictionary) -> String:
	return "%d,%d,%d" % [int(position["x"]), int(position["y"]), int(position["z"])]


static func map_get(map: Array, x: int, y: int, z: int):
	if x < 0 or y < 0 or z < 0:
		return null
	if z >= map.size():
		return null

	var level: Array = map[z]
	if y >= level.size():
		return null

	var row: Array = level[y]
	if x >= row.size():
		return null

	var value = row[x]
	if value == null:
		return null

	return str(value)


static func map_get_width(map: Array) -> int:
	if map.is_empty():
		return 0
	if (map[0] as Array).is_empty():
		return 0
	return (map[0] as Array)[0].size()


static func map_get_height(map: Array) -> int:
	if map.is_empty():
		return 0
	return (map[0] as Array).size()


static func map_get_levels(map: Array) -> int:
	return map.size()


static func overlaps(tile_db: Dictionary, position: Dictionary, z_offset: int):
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			var tile = _find_tile(tile_db, position, dx, dy, z_offset)
			if tile != null:
				return tile
	return null


static func fully_overlaps(tile_db: Dictionary, position: Dictionary, z_offset: int) -> bool:
	var left = _find_tile(tile_db, position, -1, 0, z_offset)
	var right = _find_tile(tile_db, position, 1, 0, z_offset)
	var top = _find_tile(tile_db, position, 0, -1, z_offset)
	var bottom = _find_tile(tile_db, position, 0, 1, z_offset)
	var top_left = _find_tile(tile_db, position, -1, -1, z_offset)
	var top_right = _find_tile(tile_db, position, 1, -1, z_offset)
	var bottom_left = _find_tile(tile_db, position, -1, 1, z_offset)
	var bottom_right = _find_tile(tile_db, position, 1, 1, z_offset)
	var center = _find_tile(tile_db, position, 0, 0, z_offset)

	return bool(
		center
		or (left and right)
		or (top and bottom)
		or (top_left and bottom_right)
		or (top_right and bottom_left)
		or (top_left and top_right and bottom_left)
		or (top_left and top_right and bottom_right)
		or (top_left and bottom_left and bottom_right)
		or (top_right and bottom_left and bottom_right)
		or (top_left and top_right and bottom_left and bottom_right)
	)


static func is_free(tile_db: Dictionary, tile: Dictionary) -> bool:
	if bool(tile.get("deleted", false)):
		return false
	if overlaps(tile_db, tile, 1):
		return false

	var material := String(tile.get("material", "bone"))
	if material == "topaz" or material == "sapphire":
		return true

	var freedoms = _get_freedoms(tile_db, tile)
	return bool(freedoms["left"] or freedoms["right"])


static func get_free_tiles(tile_db: Dictionary) -> Array[Dictionary]:
	var free_tiles: Array[Dictionary] = []
	for tile in tile_db.values():
		var tile_dict := tile as Dictionary
		if bool(tile_dict.get("deleted", false)):
			continue
		if is_free(tile_db, tile_dict):
			free_tiles.append(tile_dict)

	return free_tiles


static func _get_freedoms(tile_db: Dictionary, position: Dictionary) -> Dictionary:
	var has_left = _find_tile(tile_db, position, -2, -1, 0) or _find_tile(tile_db, position, -2, 0, 0) or _find_tile(tile_db, position, -2, 1, 0)
	var has_right = _find_tile(tile_db, position, 2, -1, 0) or _find_tile(tile_db, position, 2, 0, 0) or _find_tile(tile_db, position, 2, 1, 0)
	var has_top = _find_tile(tile_db, position, -1, -2, 0) or _find_tile(tile_db, position, 0, -2, 0) or _find_tile(tile_db, position, 1, -2, 0)
	var has_bottom = _find_tile(tile_db, position, -1, 2, 0) or _find_tile(tile_db, position, 0, 2, 0) or _find_tile(tile_db, position, 1, 2, 0)

	return {
		"left": not bool(has_left),
		"right": not bool(has_right),
		"top": not bool(has_top),
		"bottom": not bool(has_bottom),
	}


static func _find_tile(tile_db: Dictionary, position: Dictionary, dx: int, dy: int, dz: int):
	var tx := int(position["x"]) + dx
	var ty := int(position["y"]) + dy
	var tz := int(position["z"]) + dz

	for tile_id in tile_db.keys():
		var tile: Dictionary = tile_db[tile_id]
		if bool(tile.get("deleted", false)):
			continue
		if int(tile["x"]) == tx and int(tile["y"]) == ty and int(tile["z"]) == tz:
			return tile

	return null
