extends Control

# Переменные для перетаскивания
var is_dragging = false
var drag_offset = Vector2.ZERO
var original_size = Vector2(800, 600)
var original_position = Vector2.ZERO
var is_maximized = false

@onready var panel = $Panel
@onready var hbox = $Panel/HBoxContainer
@onready var content = $ColorRect
@onready var title_label = $Panel/TitleLabel

func _ready():
	# Сохраняем оригинальные размеры
	original_size = size
	original_position = position
	
	if Global:
		Global.register_window(self)
	
	if content:
		content.color = Color(0, 0, 0, 1)
	
	_setup_app_ui()
	_resize_children_to_window()
	move_to_front()

func _setup_app_ui():
	# Настройка текстов
	$Panel/TitleLabel.text = "Jira Desktop"
	$Panel/TitleLabel.add_theme_color_override("font_color", Color.WHITE)
	
	# Скрываем ненужные элементы браузера если они остались
	if has_node("ColorRect/NavBar"):
		$ColorRect/NavBar.visible = false
	
	# Инициализируем страницы
	go_to_page("Home")

func _add_task_button(task_data: Dictionary):
	var btn = Button.new()
	btn.text = "- " + task_data.get("title", "Untitled")
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(func(): _show_task_details(task_data))
	$ColorRect/PageContainer/HomeView/SprintListVBox.add_child(btn)

func _show_task_details(task_data: Dictionary):
	# Логика показа деталей
	go_to_page("Details")
	# ... заполнение полей в Details View
	pass

func _exit_tree():
	if Global:
		Global.unregister_window(self)

func _on_max_button():
	if is_maximized:
		size = original_size
		position = original_position
		is_maximized = false
	else:
		original_size = size
		original_position = position
		var viewport_size = get_viewport_rect().size
		position = Vector2.ZERO
		size = viewport_size
		is_maximized = true
	_resize_children_to_window()

func _on_min_button():
	visible = false

func _resize_children_to_window():
	var w = size.x
	var h = size.y
	var title_height = 40.0
	
	if panel:
		panel.size = Vector2(w, title_height)
		panel.position = Vector2.ZERO
		if hbox:
			# Даем hbox возможность определить свой размер по кнопкам
			var hbox_size = hbox.get_combined_minimum_size()
			hbox.position = Vector2(w - hbox_size.x - 10, (title_height - hbox_size.y) / 2)
			hbox.size = hbox_size
	
	if content:
		content.position = Vector2(0, title_height)
		content.size = Vector2(w, h - title_height)

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		move_to_front()
