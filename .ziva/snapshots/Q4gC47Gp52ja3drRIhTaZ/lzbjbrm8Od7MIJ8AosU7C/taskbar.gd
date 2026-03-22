extends CanvasLayer
class_name Taskbar

@onready var container: HBoxContainer = $Panel/HBoxContainer
const ICON_SCENE: PackedScene = preload("res://TaskbarIcon.tscn")

func _ready() -> void:
	if Global:
		Global.window_opened.connect(_on_window_opened)
		Global.window_closed.connect(_on_window_closed)

func _on_window_opened(window: Control) -> void:
	var icon := ICON_SCENE.instantiate()
	container.add_child(icon)
	icon.setup(window)

func _on_window_closed(window: Control) -> void:
	for icon in container.get_children():
		if icon.target_window == window:
			icon.queue_free()
