extends Control

var is_dragging = false
var drag_offset = Vector2.ZERO
var drag_start_pos = Vector2.ZERO
const DRAG_THRESHOLD = 5.0

func _ready():
	if has_node("TextureButton"):
		$TextureButton.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_start_pos = event.global_position
			drag_offset = event.global_position - global_position
		else:
			if is_dragging:
				var drag_dist = (event.global_position - drag_start_pos).length()
				if drag_dist < DRAG_THRESHOLD:
					_open_browser()
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = event.global_position - drag_offset

func _open_browser():
	print("Открываю браузер...")
	
	var windows_layer = get_tree().current_scene.get_node_or_null("WindowsLayer")
	
	if windows_layer:
		for child in windows_layer.get_children():
			if child.name == "Browser":
				print("Браузер уже открыт!")
				child.move_to_front()
				return
	
	var browser_scene = load("res://Browser.tscn")
	if not browser_scene:
		printerr("ОШИБКА: Не удалось загрузить Browser.tscn")
		return
	
	var browser_window = browser_scene.instantiate()
	browser_window.name = "Browser"
	browser_window.position = Vector2(100, 100)
	
	if windows_layer:
		windows_layer.add_child(browser_window)
	else:
		get_tree().current_scene.add_child(browser_window)
