extends Node

class TileState:
	var id: int
	var type: String
	var grid_x: int
	var grid_y: int
	var layer_z: int
	var removed: bool = false
	var selected: bool = false

	func _init(_id: int, _type: String, _grid_x: int, _grid_y: int, _layer_z: int):
		id = _id
		type = _type
		grid_x = _grid_x
		grid_y = _grid_y
		layer_z = _layer_z


@export var tile_scene: PackedScene

@onready var tile_layer: Node2D = $"../TileLayer"

const TILE_W := 64
const TILE_H := 96
const X_SPACING := 70    # 牌间距（横向）
const Y_SPACING := 100   # 牌间距（纵向）
const LAYER_OFFSET := Vector2(8, -10)  # 层间偏移，让上下层明显

# 牌局居中偏移量
# 底层 8 列×6 行，总宽约 8*70=560，总高约 6*100=600
# 屏幕 1280x720，让牌局居中显示
const BOARD_OFFSET := Vector2(350, 100)  # 整体偏移，让牌局在屏幕中央偏左

# 三种基本花色：筒子 (dot)、条子 (bam)、万子 (crack)
const BASE_TYPES := ["dot", "bam", "crack"]
const TILE_VALUES := [1, 2, 3, 4, 5, 6, 7, 8, 9]

var tile_states: Dictionary = {}   # id -> TileState
var tile_nodes: Dictionary = {}    # id -> Tile
var selected_tile_id: int = -1
var next_id: int = 0

# 图标缓存
var icon_map: Dictionary = {}

func _ready() -> void:
	load_icons()
	spawn_random_board()
	refresh_clickable_states()


func load_icons() -> void:
	# 加载三种花色的 1-9 图标
	for suit in BASE_TYPES:
		for val in TILE_VALUES:
			var key := "%s%d" % [suit, val]
			var path := "res://tiles/%s%d.webp" % [suit, val]
			if ResourceLoader.exists(path):
				icon_map[key] = load(path)


func spawn_random_board() -> void:
	clear_board()
	
	# 生成配对的牌：每种花色 × 每个数字 × 2 张 = 54 张牌
	var tile_pairs: Array[Dictionary] = []
	for suit in BASE_TYPES:
		for val in TILE_VALUES:
			var type_key := "%s%d" % [suit, val]
			# 每对牌生成 2 张
			tile_pairs.append({"type": type_key})
			tile_pairs.append({"type": type_key})
	
	# 打乱顺序
	tile_pairs.shuffle()
	
	# 多层布局：3 层
	# 底层 8x6 网格放 24 张，中层 6x4 放 18 张，上层 5x3 放 12 张
	# 使用分散布局，确保边缘有牌可点击
	var layers := [
		{"z": 0, "cols": 8, "rows": 6, "count": 24, "offset_x": 0, "offset_y": 0},
		{"z": 1, "cols": 6, "rows": 4, "count": 18, "offset_x": 1, "offset_y": 1},
		{"z": 2, "cols": 5, "rows": 3, "count": 12, "offset_x": 2, "offset_y": 2},
	]
	
	var pair_index := 0
	for layer in layers:
		var z: int = layer["z"]
		var cols: int = layer["cols"]
		var rows : int = layer["rows"]
		var count : int = layer["count"]
		var off_x : int = layer["offset_x"]
		var off_y : int = layer["offset_y"]
		
		# 生成位置列表，优先选择边缘位置
		var positions: Array[Vector2i] = []
		
		# 先添加边缘位置（第一列和最后一列）
		for y in range(rows):
			positions.append(Vector2i(0 + off_x, y + off_y))  # 左边缘
			positions.append(Vector2i(cols - 1 + off_x, y + off_y))  # 右边缘
		
		# 再添加中间位置
		for x in range(1, cols - 1):
			for y in range(rows):
				positions.append(Vector2i(x + off_x, y + off_y))
		
		# 打乱位置（但边缘位置在前）
		var edge_positions := positions.slice(0, rows * 2)
		var center_positions := positions.slice(rows * 2)
		edge_positions.shuffle()
		center_positions.shuffle()
		positions = edge_positions + center_positions
		
		# 取前 count 个位置放置牌
		for i in range(count):
			if pair_index >= tile_pairs.size():
				break
			var pos := positions[i]
			var entry := tile_pairs[pair_index]
			create_tile(entry["type"], pos.x, pos.y, z)
			pair_index += 1


func clear_board() -> void:
	for child in tile_layer.get_children():
		child.queue_free()

	tile_states.clear()
	tile_nodes.clear()
	selected_tile_id = -1
	next_id = 0


func create_tile(tile_type: String, grid_x: int, grid_y: int, layer_z: int) -> void:
	var tile_id := next_id
	next_id += 1

	var state = TileState.new(tile_id, tile_type, grid_x, grid_y, layer_z)
	tile_states[tile_id] = state

	var tile = tile_scene.instantiate()
	tile_layer.add_child(tile)

	var icon: Texture2D = null
	if icon_map.has(tile_type):
		icon = icon_map[tile_type]

	tile.setup(tile_id, tile_type, icon)
	tile.position = grid_to_world(grid_x, grid_y, layer_z)
	tile.z_index = layer_z * 100 + grid_y
	tile.tile_clicked.connect(_on_tile_clicked)

	tile_nodes[tile_id] = tile


func grid_to_world(grid_x: int, grid_y: int, layer_z: int) -> Vector2:
	return Vector2(
		grid_x * X_SPACING,
		grid_y * Y_SPACING
	) + LAYER_OFFSET * layer_z + BOARD_OFFSET


func _on_tile_clicked(tile_id: int) -> void:
	if not tile_states.has(tile_id):
		return

	var state: TileState = tile_states[tile_id]
	if state.removed:
		return

	var clickable := is_tile_clickable(state)
	if not clickable:
		if tile_nodes.has(tile_id):
			tile_nodes[tile_id].play_invalid_feedback()
		return

	# 第一次选择
	if selected_tile_id == -1:
		selected_tile_id = tile_id
		state.selected = true
		tile_nodes[tile_id].set_selected(true)
		update_ui_status("已选择第一张牌")
		return

	# 点自己 = 取消选中
	if selected_tile_id == tile_id:
		state.selected = false
		tile_nodes[tile_id].set_selected(false)
		selected_tile_id = -1
		update_ui_status("已取消选择")
		return

	var first_state: TileState = tile_states[selected_tile_id]

	# 两张相同 => 消除
	if first_state.type == state.type:
		update_ui_status("匹配成功！")
		remove_pair(selected_tile_id, tile_id)
		selected_tile_id = -1
		refresh_clickable_states()
		check_end_conditions()
	else:
		# 切换选中
		first_state.selected = false
		tile_nodes[selected_tile_id].set_selected(false)

		selected_tile_id = tile_id
		state.selected = true
		tile_nodes[tile_id].set_selected(true)
		update_ui_status("牌型不匹配，已切换选择")


func remove_pair(id_a: int, id_b: int) -> void:
	var a: TileState = tile_states[id_a]
	var b: TileState = tile_states[id_b]

	a.removed = true
	b.removed = true
	a.selected = false
	b.selected = false

	if tile_nodes.has(id_a):
		tile_nodes[id_a].set_selected(false)
		tile_nodes[id_a].play_remove()
	if tile_nodes.has(id_b):
		tile_nodes[id_b].set_selected(false)
		tile_nodes[id_b].play_remove()
	
	# 更新分数
	var score := get_removed_count() * 10
	update_ui_score(score)


func refresh_clickable_states() -> void:
	for id in tile_states.keys():
		var state: TileState = tile_states[id]
		if state.removed:
			continue

		var clickable := is_tile_clickable(state)
		if tile_nodes.has(id):
			tile_nodes[id].set_clickable(clickable)


func is_tile_clickable(state: TileState) -> bool:
	if state.removed:
		return false

	# 被上层牌覆盖则不可点击
	if is_covered(state):
		return false

	# 左右至少有一侧空闲才能点击（没有相邻的牌）
	return is_left_free(state) or is_right_free(state)


func is_covered(state: TileState) -> bool:
	for other_id in tile_states.keys():
		var other: TileState = tile_states[other_id]
		if other.removed:
			continue
		if other.id == state.id:
			continue

		if other.layer_z <= state.layer_z:
			continue

		if overlaps_xy(state, other):
			return true

	return false


func overlaps_xy(a: TileState, b: TileState) -> bool:
	# 同一格视为覆盖
	var dx = abs(a.grid_x - b.grid_x)
	var dy = abs(a.grid_y - b.grid_y)

	return dx <= 0 and dy <= 0


func is_left_free(state: TileState) -> bool:
	# 检查左侧是否有相邻的牌（同一层，同一行，左边一格）
	for other_id in tile_states.keys():
		var other: TileState = tile_states[other_id]
		if other.removed:
			continue
		if other.id == state.id:
			continue

		if other.layer_z != state.layer_z:
			continue

		# 左边一格有牌，说明左边不空闲
		if other.grid_y == state.grid_y and other.grid_x == state.grid_x - 1:
			return false

	return true


func is_right_free(state: TileState) -> bool:
	# 检查右侧是否有相邻的牌（同一层，同一行，右边一格）
	for other_id in tile_states.keys():
		var other: TileState = tile_states[other_id]
		if other.removed:
			continue
		if other.id == state.id:
			continue

		if other.layer_z != state.layer_z:
			continue

		# 右边一格有牌，说明右边不空闲
		if other.grid_y == state.grid_y and other.grid_x == state.grid_x + 1:
			return false

	return true


func check_end_conditions_print() -> void:
	if is_board_cleared():
		print("胜利：棋盘清空")
		return

	if not has_any_valid_match():
		print("失败：当前无可配对")


func is_board_cleared() -> bool:
	for id in tile_states.keys():
		var state: TileState = tile_states[id]
		if not state.removed:
			return false
	return true


func has_any_valid_match() -> bool:
	var clickable_tiles: Array[TileState] = []

	for id in tile_states.keys():
		var state: TileState = tile_states[id]
		if state.removed:
			continue
		if is_tile_clickable(state):
			clickable_tiles.append(state)

	for i in range(clickable_tiles.size()):
		for j in range(i + 1, clickable_tiles.size()):
			if clickable_tiles[i].type == clickable_tiles[j].type:
				return true

	return false


# UI 信号处理
func _on_restart_pressed() -> void:
	spawn_random_board()
	refresh_clickable_states()
	update_ui_status("请选择两张相同牌进行消除")
	update_ui_score(0)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/gameStar.tscn")


func update_ui_status(msg: String) -> void:
	var label := get_node_or_null("UI/TopBar/HBoxContainer/StatusLabel") as Label
	if label:
		label.text = msg


func update_ui_score(score: int) -> void:
	var label := get_node_or_null("UI/TopBar/HBoxContainer/ScoreLabel") as Label
	if label:
		label.text = "分数：%d" % score


func check_end_conditions() -> void:
	if is_board_cleared():
		var score := get_removed_count() * 10
		update_ui_status("胜利：棋盘清空！总分：%d" % score)
		return

	if not has_any_valid_match():
		var score := get_removed_count() * 10
		update_ui_status("失败：无可消对子。总分：%d" % score)


func get_removed_count() -> int:
	var count := 0
	for state in tile_states.values():
		if state.removed:
			count += 1
	return count
