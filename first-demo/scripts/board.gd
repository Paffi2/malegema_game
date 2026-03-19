extends Control

# 最小可玩局仅使用基础牌型，后续可替换为完整发牌逻辑。
const BASE_CARDS := [
	"bam1",
	"bam2",
	"bam3",
	"crack1",
	"crack2",
	"dot1",
]
const SPECIAL_CARDS := [
	"dragonr",
	"phoenix",
	"gemr",
	"mutation1",
	"windn",
	"joker",
]
const MAX_TILES := 12
const TILE_SIZE := Vector2(88, 48)
const STEP_X := 24
const STEP_Y := 18
const Z_OFFSET := 6

@onready var board_layer: Control = $RootPanel/MarginContainer/VBoxContainer/BoardLayer
@onready var status_label: Label = $RootPanel/MarginContainer/VBoxContainer/StatusLabel

var tile_db: Dictionary = {}
var tile_buttons: Dictionary = {}
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
	# 重开时清空状态与旧按钮，重新生成随机牌面。
	tile_db.clear()
	tile_buttons.clear()
	game_state = {
		"points": 0,
		"end_condition": "",
		"dragon_run": {},
		"phoenix_run": {},
		"temporary_material": "",
		"enabled_modules": GameLoop.MODULE_ORDER.duplicate(),
	}
	for child in board_layer.get_children():
		child.queue_free()

	var deck := _build_deck(int(MAX_TILES / 2.0))
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	game_state["rng"] = rng
	tile_db = SetupTiles.setup_tiles(rng, deck)

	for tile in _sorted_tiles(tile_db):
		var tile_id := String(tile["id"])
		var card_id := String(tile["card_id"])
		var card_data := CardData.get_card_by_id(card_id)

		var tile_button := Button.new()
		# 先显示 cardId，属性细节通过 tooltip 供调试校验。
		tile_button.text = card_id
		tile_button.tooltip_text = "id=%s x=%d y=%d z=%d\nsuit=%s rank=%s colors=%s points=%d" % [
			tile_id,
			tile["x"],
			tile["y"],
			tile["z"],
			card_data.get("suit", ""),
			card_data.get("rank", ""),
			str(card_data.get("colors", [])),
			int(card_data.get("points", 0)),
		]
		tile_button.custom_minimum_size = TILE_SIZE
		tile_button.focus_mode = Control.FOCUS_NONE
		tile_button.position = _to_screen_position(tile)
		tile_button.z_index = int(tile["z"]) * 10 + int(tile["y"])
		tile_button.pressed.connect(_on_tile_pressed.bind(tile_id))
		board_layer.add_child(tile_button)
		tile_buttons[tile_id] = tile_button

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
		return

	var result := GameLoop.select_tile(tile_db, game_state, tile_id)
	_refresh_tiles_state()
	_status_from_result(result)


func _apply_tile_visual(tile_id: String) -> void:
	if not tile_buttons.has(tile_id) or not tile_db.has(tile_id):
		return
	var button: Button = tile_buttons[tile_id]
	var tile: Dictionary = tile_db[tile_id]
	_sync_button_from_tile(button, tile)
	if bool(tile["deleted"]):
		button.visible = false
		return
	button.visible = true

	var free := TileRules.is_free(tile_db, tile)
	button.disabled = not free
	if bool(tile["selected"]):
		button.modulate = Color(1.0, 0.95, 0.55)
	elif free:
		button.modulate = Color(1, 1, 1)
	else:
		button.modulate = Color(0.7, 0.7, 0.7)


func _sync_button_from_tile(button: Button, tile: Dictionary) -> void:
	var card_id := String(tile["card_id"])
	var card_data := CardData.get_card_by_id(card_id)
	button.text = card_id
	button.position = _to_screen_position(tile)
	button.z_index = int(tile["z"]) * 10 + int(tile["y"])
	button.tooltip_text = "id=%s x=%d y=%d z=%d\nsuit=%s rank=%s colors=%s points=%d" % [
		String(tile["id"]),
		int(tile["x"]),
		int(tile["y"]),
		int(tile["z"]),
		card_data.get("suit", ""),
		card_data.get("rank", ""),
		str(card_data.get("colors", [])),
		int(card_data.get("points", 0)),
	]


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


func _refresh_tiles_state() -> void:
	for tile_id in tile_buttons.keys():
		_apply_tile_visual(String(tile_id))


func _to_screen_position(tile: Dictionary) -> Vector2:
	var x := int(tile["x"])
	var y := int(tile["y"])
	var z := int(tile["z"])
	return Vector2(float(x * STEP_X), float(y * STEP_Y - z * Z_OFFSET))


func _build_deck(pair_count: int) -> Array[Dictionary]:
	var card_ids: Array[String] = []
	if pair_count <= 0:
		return []

	# 保证两类牌都出现：至少 1 组基础牌 + 1 组特殊牌。
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
