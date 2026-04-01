extends Control

const BASE_CARDS := [
	"bam1", "bam2", "bam3",
	"crack1", "crack2",
	"dot1",
]
const SPECIAL_CARDS := [
	"dragonr", "phoenix", "gemr", "mutation1", "windn", "joker",
]
const MAX_TILES := 12
const TILE_SCENE := preload("res://scene/Tile.tscn")

const STEP_X := 36
const STEP_Y := 50
const Z_OFFSET := 4
const BOARD_OFFSET_X := 60
const BOARD_OFFSET_Y := 20

@onready var board_container: Control = $GamePanel/VBoxContainer/BoardContainer
@onready var status_label: Label = $GamePanel/VBoxContainer/StatusLabel

var tile_db: Dictionary = {}
var tile_nodes: Dictionary = {}

# Note: GameLoop, SetupTiles, TileRules are auto-loaded via class_name

var game_state := {
	"points": 0,
	"end_condition": "",
	"dragon_run": {},
	"phoenix_run": {},
	"temporary_material": "",
	"enabled_modules": GameLoop.MODULE_ORDER.duplicate(),
}

func _ready() -> void:
	_setup_new_round()

func _setup_new_round() -> void:
	tile_db.clear()
	tile_nodes.clear()
	game_state = {
		"points": 0,
		"end_condition": "",
		"dragon_run": {},
		"phoenix_run": {},
		"temporary_material": "",
		"enabled_modules": GameLoop.MODULE_ORDER.duplicate(),
	}
	
	# Clear old tiles
	for child in board_container.get_children():
		child.queue_free()

	var deck := _build_deck(int(MAX_TILES / 2.0))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	game_state["rng"] = rng
	tile_db = SetupTiles.setup_tiles(rng, deck)

	# Load icons
	var icon_map := {}
	for tile_data in tile_db.values():
		var card_id := String(tile_data["card_id"])
		if not icon_map.has(card_id):
			var path := "res://tiles/%s.webp" % card_id
			if ResourceLoader.exists(path):
				icon_map[card_id] = load(path)

	# Create tiles
	for tile in _sorted_tiles(tile_db):
		var tile_id := String(tile["id"])
		var card_id := String(tile["card_id"])

		var tile_node = TILE_SCENE.instantiate() as Tile
		board_container.add_child(tile_node)

		var icon: Texture2D = icon_map.get(card_id)
		tile_node.setup(tile_id, card_id, icon)
		tile_node.position = _to_screen_position(tile)
		tile_node.z_index = int(tile["z"]) * 100 + int(tile["y"])
		tile_node.tile_clicked.connect(_on_tile_pressed)

		tile_nodes[tile_id] = tile_node

	_refresh_tiles_state()
	status_label.text = "已生成可解牌局，当前分数：0"

func _on_tile_pressed(tile_id: String) -> void:
	if not tile_db.has(tile_id):
		return

	var tile: Dictionary = tile_db[tile_id]
	if bool(tile["deleted"]):
		return
	if String(game_state.get("end_condition", "")) != "":
		return

	if not TileRules.is_free(tile_db, tile):
		status_label.text = "该牌当前不可点（被压住或左右都堵住）"
		if tile_nodes.has(tile_id):
			tile_nodes[tile_id].play_invalid_feedback()
		return

	var result := GameLoop.select_tile(tile_db, game_state, tile_id)
	_refresh_tiles_state()
	_status_from_result(result)

func _status_from_result(result: Dictionary) -> void:
	var kind := String(result.get("kind", ""))
	var end_condition := String(game_state.get("end_condition", ""))
	if end_condition == "empty-board":
		status_label.text = "全部消除，过关！总分：%d" % int(game_state["points"])
		return
	if end_condition == "no-pairs":
		status_label.text = "无可消对子，游戏结束。总分：%d" % int(game_state["points"])
		return

	match kind:
		"selected-first":
			status_label.text = "已选择第一张牌"
		"unselected":
			status_label.text = "已取消选择，当前分数：%d" % int(game_state["points"])
		"matched":
			status_label.text = "匹配成功 +%d，当前分数：%d" % [
				int(result.get("points", 0)),
				int(game_state["points"]),
			]
		"mismatch":
			status_label.text = "不匹配，当前分数：%d" % int(game_state["points"])
		_:
			status_label.text = "当前分数：%d" % int(game_state["points"])

func _apply_tile_visual(tile_id: String) -> void:
	if not tile_nodes.has(tile_id) or not tile_db.has(tile_id):
		return

	var tile_node = tile_nodes[tile_id]
	if not is_instance_valid(tile_node):
		return
	var tile: Dictionary = tile_db[tile_id]

	if bool(tile["deleted"]):
		if tile_node.visible:
			tile_node.play_remove()
		return

	tile_node.visible = true

	var free := TileRules.is_free(tile_db, tile)
	tile_node.set_clickable(free)
	tile_node.set_selected(bool(tile["selected"]))

	tile_node.position = _to_screen_position(tile)
	tile_node.z_index = int(tile["z"]) * 100 + int(tile["y"])

func _refresh_tiles_state() -> void:
	for tile_id in tile_nodes.keys():
		_apply_tile_visual(String(tile_id))

func _to_screen_position(tile: Dictionary) -> Vector2:
	var x := int(tile["x"])
	var y := int(tile["y"])
	var z := int(tile["z"])
	return Vector2(
		float(x * STEP_X) + BOARD_OFFSET_X,
		float(y * STEP_Y) - float(z * Z_OFFSET) + BOARD_OFFSET_Y
	)

func _build_deck(pair_count: int) -> Array[Dictionary]:
	var card_ids: Array[String] = []
	if pair_count <= 0:
		return []

	var base_quota := maxi(1, int(floor(pair_count / 2.0)))
	var special_quota := pair_count - base_quota
	if special_quota <= 0:
		special_quota = 1
		base_quota = pair_count - 1

	card_ids.append_array(_fill_quota(BASE_CARDS, base_quota))
	card_ids.append_array(_fill_quota(SPECIAL_CARDS, special_quota))
	card_ids.shuffle()

	var deck: Array[Dictionary] = []
	for i in range(card_ids.size()):
		deck.append({
			"id": str(i),
			"cardId": card_ids[i],
			"material": "bone",
		})
	return deck

func _fill_quota(pool: Array, quota: int) -> Array[String]:
	var result: Array[String] = []
	if quota <= 0 or pool.is_empty():
		return result

	var source: Array = pool.duplicate()
	source.shuffle()
	var index := 0
	while result.size() < quota:
		result.append(String(source[index]))
		index += 1
		if index >= source.size():
			source.shuffle()
			index = 0

	return result

func _sorted_tiles(db: Dictionary) -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	for value in db.values():
		tiles.append(value as Dictionary)

	tiles.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["z"]) != int(b["z"]):
			return int(a["z"]) < int(b["z"])
		if int(a["y"]) != int(b["y"]):
			return int(a["y"]) < int(b["y"])
		return int(a["x"]) < int(b["x"])
	)
	return tiles

func _on_restart_button_pressed() -> void:
	_setup_new_round()

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/gameStar.tscn")
