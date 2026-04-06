extends Control
class_name StartMenu

const MAIN_SCENE_PATH: String = "res://Main.tscn"

@onready var background: ColorRect = $Background
@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var vbox: VBoxContainer = $CenterContainer/Panel/VBox
@onready var title_label: Label = $CenterContainer/Panel/VBox/Title
@onready var subtitle_label: Label = $CenterContainer/Panel/VBox/Subtitle
@onready var start_button: Button = $CenterContainer/Panel/VBox/StartButton
@onready var exit_button: Button = $CenterContainer/Panel/VBox/ExitButton
@onready var footer_hint: Label = $FooterHint

func _ready() -> void:
	_setup_layout()
	_apply_theme()
	_connect_signals()

func _setup_layout() -> void:
	vbox.custom_minimum_size = Vector2(460, 0)
	vbox.add_theme_constant_override("separation", 14)

	footer_hint.offset_left = 24
	footer_hint.offset_right = -24
	footer_hint.offset_top = -46
	footer_hint.offset_bottom = -16
	footer_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	start_button.custom_minimum_size = Vector2(0, 52)
	exit_button.custom_minimum_size = Vector2(0, 52)

func _apply_theme() -> void:
	title_label.text = "Project Desktop Simulator"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	title_label.add_theme_font_size_override("font_size", 40)

	subtitle_label.text = "Управление задачами, мессенджер и генерация сайта"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_color_override("font_color", Color(0.75, 0.84, 1.0, 1.0))
	subtitle_label.add_theme_font_size_override("font_size", 18)

	start_button.text = "Начать игру"
	exit_button.text = "Выход"
	footer_hint.text = "Подсказка: фон меню настраивается в файле res://ui/menu_background.gdshader"
	footer_hint.add_theme_color_override("font_color", Color(0.72, 0.79, 0.92, 1.0))

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.09, 0.15, 0.78)
	panel_style.border_color = Color(0.27, 0.51, 0.95, 0.9)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 14
	panel_style.corner_radius_top_right = 14
	panel_style.corner_radius_bottom_left = 14
	panel_style.corner_radius_bottom_right = 14
	panel.add_theme_stylebox_override("panel", panel_style)

	_style_button(start_button, Color(0.16, 0.56, 0.98, 1.0), Color(0.24, 0.63, 1.0, 1.0), Color(0.14, 0.45, 0.85, 1.0))
	_style_button(exit_button, Color(0.29, 0.33, 0.43, 1.0), Color(0.38, 0.43, 0.55, 1.0), Color(0.22, 0.27, 0.36, 1.0))

func _style_button(button: Button, normal_color: Color, hover_color: Color, pressed_color: Color) -> void:
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)
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
