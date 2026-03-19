extends RefCounted
class_name ResolveMutations

const MUTATION_RANKS := {
	"mutation1": ["crack", "bam"],
	"mutation2": ["dot", "crack"],
	"mutation3": ["bam", "dot"],
}

const MUTATION_MATERIALS := {
	"r": ["bone", "garnet", "ruby"],
	"g": ["bone", "jade", "emerald"],
	"b": ["bone", "topaz", "sapphire"],
}


static func apply(tile_db: Dictionary, tile: Dictionary) -> void:
	var card_id := String(tile["card_id"])
	if not MUTATION_RANKS.has(card_id):
		return

	var suits: Array = MUTATION_RANKS[card_id]
	var a_suit := String(suits[0])
	var b_suit := String(suits[1])

	var a_tiles: Array = []
	var b_tiles: Array = []
	for tile_id in tile_db.keys():
		var t: Dictionary = tile_db[tile_id]
		if bool(t.get("deleted", false)):
			continue
		var suit := String(CardData.get_card_by_id(String(t["card_id"])).get("suit", ""))
		if suit == a_suit:
			a_tiles.append(String(tile_id))
		elif suit == b_suit:
			b_tiles.append(String(tile_id))

	_change_suits(tile_db, a_tiles, a_suit, b_suit)
	_change_suits(tile_db, b_tiles, b_suit, a_suit)


static func _change_suits(tile_db: Dictionary, ids: Array, from_suit: String, to_suit: String) -> void:
	for tile_id_variant in ids:
		var tile_id := String(tile_id_variant)
		var tile: Dictionary = tile_db[tile_id]
		var old_card_id := String(tile["card_id"])
		var new_card_id := old_card_id.replace(from_suit, to_suit)

		var old_card := CardData.get_card_by_id(old_card_id)
		var old_colors = old_card.get("colors", [])
		if not (old_colors is Array) or (old_colors as Array).is_empty():
			tile["card_id"] = new_card_id
			tile_db[tile_id] = tile
			continue

		var old_color := String((old_colors as Array)[0])
		if not MUTATION_MATERIALS.has(old_color):
			tile["card_id"] = new_card_id
			tile_db[tile_id] = tile
			continue

		var order: Array = MUTATION_MATERIALS[old_color]
		var current_material := String(tile.get("material", "bone"))
		var idx := order.find(current_material)

		var new_material := current_material
		var new_card := CardData.get_card_by_id(new_card_id)
		var new_colors = new_card.get("colors", [])
		if idx >= 0 and new_colors is Array and not (new_colors as Array).is_empty():
			var new_color := String((new_colors as Array)[0])
			if MUTATION_MATERIALS.has(new_color):
				var new_order: Array = MUTATION_MATERIALS[new_color]
				if idx < new_order.size():
					new_material = String(new_order[idx])

		tile["card_id"] = new_card_id
		tile["material"] = new_material
		tile_db[tile_id] = tile
