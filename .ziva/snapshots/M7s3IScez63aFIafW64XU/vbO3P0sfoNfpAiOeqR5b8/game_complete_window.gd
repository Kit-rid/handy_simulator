extends Control
class_name GameCompleteWindow

const MAIN_SCENE_PATH: String = "res://Main.tscn"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.03, 0.04, 0.06, 0.92)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 360)
	center.add_child(panel)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.18, 1.0)
	panel_style.border_color = Color(0.2, 0.6, 1.0, 1.0)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎉 Поздравляем!"
	title.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 40)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Вы выполнили все квесты и завершили игру."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle.horizontal_alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.90, 1.0, 1.0))
	subtitle.add_theme_font_size_override("font_size", 22)
	vbox.add_child(subtitle)

	var buttons_row := HBoxContainer.new()
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_row.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons_row)

	var restart_button := Button.new()
	restart_button.text = "Начать заново"
	restart_button.custom_minimum_size = Vector2(260, 48)
	restart_button.add_theme_color_override("font_color", Color.WHITE)
	restart_button.pressed.connect(_on_restart_pressed)
	buttons_row.add_child(restart_button)

	var close_button := Button.new()
	close_button.text = "Закрыть"
	close_button.custom_minimum_size = Vector2(180, 48)
	close_button.add_theme_color_override("font_color", Color.WHITE)
	close_button.pressed.connect(queue_free)
	buttons_row.add_child(close_button)

func _on_restart_pressed() -> void:
	if Global:
		Global.restart_game_state()
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)
