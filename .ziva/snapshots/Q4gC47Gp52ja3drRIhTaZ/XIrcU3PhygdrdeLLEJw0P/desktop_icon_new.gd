extends Control
class_name DesktopIcon

@export var app_name: String = "App"
@export var app_scene_path: String = ""
@export var icon_texture: Texture2D

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var drag_start_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD: float = 5.0

func _ready() -> void:
	if has_node("TextureButton/Label"):
		$TextureButton/Label.text = app_name
	if icon_texture and has_node("TextureButton"):
		$TextureButton.texture_normal = icon_texture

	if has_node("TextureButton"):
		$TextureButton.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_pos = event.global_position
			drag_offset = event.global_position - global_position
		else:
			if is_dragging:
				var drag_dist: float = (event.global_position - drag_start_pos).length()
				if drag_dist < DRAG_THRESHOLD:
					_open_app()
			is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		global_position = event.global_position - drag_offset

func _open_app() -> void:
	if app_scene_path.is_empty():
		return

	var windows_layer: Node = get_tree().current_scene.get_node_or_null("WindowsLayer")
	var scene: PackedScene = load(app_scene_path)
	if not scene:
		printerr("ОШИБКА: Не удалось загрузить " + app_scene_path)
		return

	var window: Node = scene.instantiate()
	if window is Node2D:
		window.position = Vector2(150 + randf() * 40.0, 100 + randf() * 40.0)
	elif window is Control:
		window.position = Vector2(150 + randf() * 40.0, 100 + randf() * 40.0)

	if windows_layer:
		windows_layer.add_child(window)
	else:
		get_tree().current_scene.add_child(window)
