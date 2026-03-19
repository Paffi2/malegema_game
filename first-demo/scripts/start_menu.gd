extends Control

@onready var help_popup: PopupPanel = $HelpPopup
@onready var settings_popup: PopupPanel = $SettingsPopup
@onready var status_label: Label = $MainPanel/VBoxContainer/StatusLabel
@onready var music_slider: HSlider = $SettingsPopup/MarginContainer/VBoxContainer/MusicRow/MusicSlider
@onready var fullscreen_checkbox: CheckBox = $SettingsPopup/MarginContainer/VBoxContainer/FullscreenCheck

func _ready() -> void:
	music_slider.value = 70.0
	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _on_start_button_pressed() -> void:
	status_label.text = "进入最小可玩局..."
	get_tree().change_scene_to_file("res://scene/board.tscn")

func _on_help_button_pressed() -> void:
	help_popup.popup_centered()

func _on_settings_button_pressed() -> void:
	settings_popup.popup_centered()

func _on_close_help_pressed() -> void:
	help_popup.hide()

func _on_close_settings_pressed() -> void:
	settings_popup.hide()

func _on_music_slider_value_changed(value: float) -> void:
	# 占位音量逻辑，可替换为 AudioServer 总线音量。
	print("Music volume:", value)

func _on_fullscreen_check_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
