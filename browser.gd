extends Control

# Переменные для перетаскивания
var is_dragging = false
var drag_offset = Vector2.ZERO
var original_size = Vector2(800, 600)
var original_position = Vector2.ZERO
var is_maximized = false

func _ready():
	# Автоматически находим кнопки
	_find_and_connect_buttons()
	
	# Устанавливаем размеры, если они не заданы
	if size.x < 100 or size.y < 100:
		size = Vector2(800, 600)
	
	# Сохраняем оригинальные размеры
	original_size = size
	original_position = position
	
	# Подгоняем дочерние элементы под размер окна
	_resize_children_to_window()
	
	# Делаем окно перетаскиваемым за панель
	if has_node("Panel"):
		$Panel.gui_input.connect(_on_panel_gui_input)
		# Также делаем перетаскивание за саму панель
		$Panel.mouse_filter = Control.MOUSE_FILTER_STOP
		# Делаем перетаскивание за верхнюю часть панели (заголовок)
		$Panel.custom_minimum_size = Vector2(size.x, 40)
	else:
		# Если нет Panel, делаем перетаскивание за все окно
		gui_input.connect(_on_window_gui_input)
	
	# Убеждаемся, что кнопки не блокируют перетаскивание, но работают сами
	if has_node("Panel/HBoxContainer"):
		var hbox = $Panel/HBoxContainer
		for child in hbox.get_children():
			if child is Button:
				child.mouse_filter = Control.MOUSE_FILTER_STOP
				# Кнопки должны останавливать события, чтобы не мешать перетаскиванию

func _find_and_connect_buttons():
	# Ищем кнопки по имени
	var close_btn = _find_button("CloseButton")
	var max_btn = _find_button("MaxButton")
	var min_btn = _find_button("MinButton")
	
	# Подключаем кнопки если они существуют
	if close_btn and close_btn is Button:
		close_btn.pressed.connect(_on_close_button)
	if max_btn and max_btn is Button:
		max_btn.pressed.connect(_on_max_button)
	if min_btn and min_btn is Button:
		min_btn.pressed.connect(_on_min_button)
	
	# Если кнопок нет - создаем панель управления
	if not close_btn and not max_btn and not min_btn:
		_create_title_bar()

func _find_button(button_name: String) -> Button:
	# Рекурсивно ищем кнопку по имени
	return _find_node_recursive(self, button_name) as Button

func _find_node_recursive(node: Node, node_name: String) -> Node:
	# Рекурсивный поиск узла
	if node.name == node_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, node_name)
		if result:
			return result
	
	return null

func _create_title_bar():
	# Создаем панель управления если ее нет
	var title_bar = Panel.new()
	title_bar.name = "TitleBar"
	title_bar.size = Vector2(size.x, 40)
	title_bar.position = Vector2(0, 0)
	add_child(title_bar)
	move_child(title_bar, 0)  # Перемещаем наверх
	
	# Заголовок
	var title = Label.new()
	title.text = "Браузер"
	title.position = Vector2(10, 10)
	title_bar.add_child(title)
	
	# Кнопка закрытия
	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "X"
	close_btn.position = Vector2(size.x - 40, 5)
	close_btn.size = Vector2(30, 30)
	title_bar.add_child(close_btn)
	close_btn.pressed.connect(_on_close_button)
	
	# Делаем перетаскиваемым за title_bar
	title_bar.gui_input.connect(_on_panel_gui_input)

func _on_close_button():
	queue_free()

func _on_max_button():
	if is_maximized:
		# Восстанавливаем из развёрнутого состояния
		size = original_size
		position = original_position
		_resize_children_to_window()
		is_maximized = false
	else:
		# Разворачиваем на весь экран
		original_size = size
		original_position = position
		var viewport_size = get_viewport_rect().size
		position = Vector2.ZERO
		size = viewport_size
		_resize_children_to_window()
		is_maximized = true

# Подгоняем размеры Panel и ColorRect под текущий размер окна
func _resize_children_to_window():
	var w = size.x
	var h = size.y
	var title_height = 40.0
	
	# Panel — только верхняя полоса (заголовок), чтобы кнопки всегда были видны
	if has_node("Panel"):
		$Panel.size = Vector2(w, title_height)
		$Panel.position = Vector2.ZERO
		if has_node("Panel/HBoxContainer"):
			var hbox = $Panel/HBoxContainer
			hbox.top_level = false
			var hw = hbox.size.x
			if hw <= 0:
				hw = 90.0  # запасная ширина трёх кнопок
			hbox.position = Vector2(w - hw - 16, 8)
	# Контент под заголовком
	if has_node("ColorRect"):
		$ColorRect.position = Vector2(0, title_height)
		$ColorRect.size = Vector2(w, h - title_height)

func _on_min_button():
	# Ищем любую Content область для скрытия
	var content = _find_node_recursive(self, "ColorRect")
	if not content:
		content = _find_node_recursive(self, "Content")
	if not content:
		content = _find_node_recursive(self, "BrowserContent")
	
	if content and content is Node:
		content.visible = !content.visible
	else:
		# Если нет контента, скрываем все кроме панели управления
		for child in get_children():
			if child.name != "TitleBar" and child.name != "Panel":
				child.visible = !child.visible

func _on_panel_gui_input(event):
	# Проверяем, не кликнули ли по кнопке
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = event.position
		# Проверяем, не попали ли в область кнопок
		if has_node("Panel/HBoxContainer"):
			var hbox = $Panel/HBoxContainer
			var hbox_rect = Rect2(hbox.position, hbox.size)
			if hbox_rect.has_point(mouse_pos):
				# Кликнули по кнопкам - не обрабатываем перетаскивание
				return
	_handle_drag_event(event)

func _on_window_gui_input(event):
	_handle_drag_event(event)

func _input(event):
	# Альтернативная обработка перетаскивания, если gui_input не срабатывает
	if is_dragging:
		if event is InputEventMouseMotion:
			var mouse_global = get_global_mouse_position()
			global_position = mouse_global - drag_offset
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false

func _handle_drag_event(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			# Используем координаты события для более точного определения смещения
			if event is InputEventMouseButton:
				var local_pos = event.position
				# Получаем глобальную позицию мыши
				var mouse_global = get_global_mouse_position()
				drag_offset = mouse_global - global_position
			else:
				drag_offset = get_global_mouse_position() - global_position
			# Поднимаем окно наверх при клике
			z_index = 100
		else:
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		# Используем глобальные координаты мыши для перетаскивания
		var mouse_global = get_global_mouse_position()
		global_position = mouse_global - drag_offset

# Дополнительно: возможность изменения размера
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Клик по окну - поднимаем наверх
		z_index = 100
