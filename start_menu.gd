extends Control
class_name StartMenu

const MAIN_SCENE_PATH: String = "res://Main.tscn"

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var vbox: VBoxContainer = $CenterContainer/Panel/VBox
@onready var start_button: Button = $CenterContainer/Panel/VBox/StartButton
@onready var exit_button: Button = $CenterContainer/Panel/VBox/ExitButton

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_setup_layout()
	_apply_theme()
	_connect_signals()

func _setup_layout() -> void:
	vbox.custom_minimum_size = Vector2(420, 0)
	vbox.add_theme_constant_override("separation", 12)

	start_button.custom_minimum_size = Vector2(0, 56)
	exit_button.custom_minimum_size = Vector2(0, 56)

func _apply_theme() -> void:
	start_button.text = "Начать игру"
	exit_button.text = "Выход"

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.15, 0.78)
	panel_style.border_color = Color(0.103, 0.195, 0.363, 0.9)
	panel_style.border_width_left = 6
	panel_style.border_width_top = 6
	panel_style.border_width_right = 6
	panel_style.border_width_bottom = 6
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", panel_style)

	_style_button(start_button, Color(0.16, 0.56, 0.98, 1.0), Color(0.24, 0.63, 1.0, 1.0), Color(0.14, 0.45, 0.85, 1.0))
	_style_button(exit_button, Color(0.29, 0.33, 0.43, 1.0), Color(0.38, 0.43, 0.55, 1.0), Color(0.22, 0.27, 0.36, 1.0))

func _style_button(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_stylebox_override("normal", _make_button_style(normal_color))
	button.add_theme_stylebox_override("hover", _make_button_style(hover_color))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed_color))

func _make_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_exit_pressed() -> void:
	get_tree().quit()
