extends Control

@export var app_name: String = "App"
@export var app_scene_path: String = ""

var is_dragging = false
var drag_offset = Vector2.ZERO
var drag_start_pos = Vector2.ZERO
const DRAG_THRESHOLD = 5.0

func _ready():
	if has_node("TextureButton/Label"):
		$TextureButton/Label.text = app_name
	
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
					_open_app()
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = event.global_position - drag_offset

func _open_app():
	if app_scene_path == "" or app_scene_path == null:
		return
		
	var windows_layer = get_tree().current_scene.get_node_or_null("WindowsLayer")
	var scene = load(app_scene_path)
	if scene:
		var window = scene.instantiate()
		window.position = Vector2(150 + randf()*40, 100 + randf()*40)
		if windows_layer:
			windows_layer.add_child(window)
		else:
			get_tree().current_scene.add_child(window)


# Переменные для перетаскивания ярлыка
var is_dragging = false
var drag_offset = Vector2.ZERO
var drag_start_pos = Vector2.ZERO
const DRAG_THRESHOLD = 5.0

@export var app_name: String = "App"
@export var app_scene_path: String = ""
@export var icon_texture: Texture2D

func _ready():
	$TextureButton/Label.text = app_name
	if icon_texture:
		$TextureButton.texture_normal = icon_texture
		
	# Подключаем обработчик событий мыши к кнопке
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
					_open_app()
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = event.global_position - drag_offset

func _open_app():
	print("Открываю " + app_name + "...")
	
	var windows_layer = get_tree().current_scene.get_node_or_null("WindowsLayer")
	
	var app_scene = load(app_scene_path)
	if not app_scene:
		printerr("ОШИБКА: Не удалось загрузить " + app_scene_path)
		return
	
	var app_window = app_scene.instantiate()
	app_window.position = Vector2(100 + randf()*50, 100 + randf()*50)
	
	if windows_layer:
		windows_layer.add_child(app_window)
	else:
		get_tree().current_scene.add_child(app_window)
