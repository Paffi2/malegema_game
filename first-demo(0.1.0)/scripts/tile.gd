class_name Tile
extends TextureButton

signal tile_clicked(tile_id: String)

var tile_id_str: String = ""
var tile_type: String = ""

var is_selected: bool = false

func set_selected(value: bool) -> void:
	is_selected = value
	_update_visual_state()
var is_clickable: bool = true
var is_removed: bool = false

const TILE_SIZE := Vector2(64, 96)

func _ready() -> void:
	custom_minimum_size = TILE_SIZE
	stretch_mode = TextureButton.STRETCH_KEEP_CENTERED
	ignore_texture_size = true
	
	pressed.connect(_on_pressed)
	_update_visual_state()

func setup(id: String, type: String, icon_texture: Texture2D = null) -> void:
	tile_id_str = id
	tile_type = type
	
	# Create normal texture (white card)
	var img = Image.create(int(TILE_SIZE.x), int(TILE_SIZE.y), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.95, 0.95, 0.97))
	# Add border
	for x in range(int(TILE_SIZE.x)):
		for y in range(int(TILE_SIZE.y)):
			if x < 2 or x >= int(TILE_SIZE.x) - 2 or y < 2 or y >= int(TILE_SIZE.y) - 2:
				img.set_pixel(x, y, Color(0.5, 0.5, 0.55))
	var tex_normal = ImageTexture.create_from_image(img)
	
	# Create selected texture (yellow highlight)
	var img_sel = Image.create(int(TILE_SIZE.x), int(TILE_SIZE.y), false, Image.FORMAT_RGBA8)
	img_sel.fill(Color(1, 0.85, 0.4))
	for x in range(int(TILE_SIZE.x)):
		for y in range(int(TILE_SIZE.y)):
			if x < 3 or x >= int(TILE_SIZE.x) - 3 or y < 3 or y >= int(TILE_SIZE.y) - 3:
				img_sel.set_pixel(x, y, Color(0.9, 0.6, 0.1))
	var tex_selected = ImageTexture.create_from_image(img_sel)
	
	# Create disabled texture (gray)
	var img_dis = Image.create(int(TILE_SIZE.x), int(TILE_SIZE.y), false, Image.FORMAT_RGBA8)
	img_dis.fill(Color(0.6, 0.6, 0.62))
	for x in range(int(TILE_SIZE.x)):
		for y in range(int(TILE_SIZE.y)):
			if x < 2 or x >= int(TILE_SIZE.x) - 2 or y < 2 or y >= int(TILE_SIZE.y) - 2:
				img_dis.set_pixel(x, y, Color(0.4, 0.4, 0.45))
	var tex_disabled = ImageTexture.create_from_image(img_dis)
	
	# Create hover texture (light yellow)
	var img_hover = Image.create(int(TILE_SIZE.x), int(TILE_SIZE.y), false, Image.FORMAT_RGBA8)
	img_hover.fill(Color(1, 0.9, 0.6))
	for x in range(int(TILE_SIZE.x)):
		for y in range(int(TILE_SIZE.y)):
			if x < 2 or x >= int(TILE_SIZE.x) - 2 or y < 2 or y >= int(TILE_SIZE.y) - 2:
				img_hover.set_pixel(x, y, Color(0.8, 0.7, 0.3))
	var tex_hover = ImageTexture.create_from_image(img_hover)
	
	texture_normal = tex_normal
	texture_pressed = tex_selected
	texture_hover = tex_hover
	texture_disabled = tex_disabled
	
	# Add icon as child - smaller size (35% of tile)
	if icon_texture:
		var icon = TextureRect.new()
		icon.name = "Icon"
		icon.texture = icon_texture
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Scale to fit within 45% of tile size
		var max_icon_size = TILE_SIZE * 0.75
		var tex_size = icon_texture.get_size()
		var scale_factor = min(max_icon_size.x / tex_size.x, max_icon_size.y / tex_size.y)
		icon.custom_minimum_size = tex_size * scale_factor
		icon.size = tex_size * scale_factor
		icon.position = (TILE_SIZE - icon.size) / 2
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(icon)

func _update_visual_state() -> void:
	if is_selected:
		# Use pressed texture and scale up
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		button_pressed = true
	else:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2.ONE, 0.08)
		button_pressed = false

func set_clickable(value: bool) -> void:
	is_clickable = value
	disabled = not value

func play_remove() -> void:
	is_removed = true
	var tween := create_tween()
	tween.parallel().tween_property(self, "scale", Vector2(0.4, 0.4), 0.18)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tween.finished.connect(queue_free)

func play_invalid_feedback() -> void:
	var origin := position
	var tween := create_tween()
	tween.tween_property(self, "position", origin + Vector2(-5, 0), 0.04)
	tween.tween_property(self, "position", origin + Vector2(5, 0), 0.04)
	tween.tween_property(self, "position", origin + Vector2(-5, 0), 0.04)
	tween.tween_property(self, "position", origin + Vector2(5, 0), 0.04)
	tween.tween_property(self, "position", origin, 0.04)

func _on_pressed() -> void:
	if is_removed:
		return
	if not is_clickable:
		play_invalid_feedback()
		return
	tile_clicked.emit(tile_id_str)
