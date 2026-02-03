extends Control

# Переменные для перетаскивания ярлыка
var is_dragging_icon = false
var drag_offset_icon = Vector2.ZERO
var last_click_time = 0.0
var double_click_delay = 0.4  # Задержка для двойного клика в секундах
var mouse_pressed_pos = Vector2.ZERO
var has_moved = false

func _ready():
	# Подключаем обработчик событий мыши для двойного клика и перетаскивания
	$TextureButton.gui_input.connect(_on_texture_button_gui_input)
	# Также делаем сам Control перетаскиваемым
	gui_input.connect(_on_control_gui_input)

func _process(_delta):
	# Ярлык двигается только пока зажата ЛКМ — сбрасываем перетаскивание, если кнопку отпустили
	if is_dragging_icon and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		is_dragging_icon = false
		has_moved = false
		mouse_pressed_pos = Vector2.ZERO

func _on_texture_button_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed_pos = get_global_mouse_position()
			has_moved = false
			drag_offset_icon = mouse_pressed_pos - global_position
		else:
			# Отпустили кнопку
			if not has_moved:
				# Это был клик, а не перетаскивание
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < double_click_delay:
					# Двойной клик - открываем браузер
					_open_browser()
					last_click_time = 0.0
				else:
					last_click_time = current_time
			is_dragging_icon = false
			has_moved = false
	
	if event is InputEventMouseMotion:
		if is_dragging_icon or (mouse_pressed_pos != Vector2.ZERO and (get_global_mouse_position() - mouse_pressed_pos).length() > 5):
			# Начали перетаскивание
			is_dragging_icon = true
			has_moved = true
			global_position = get_global_mouse_position() - drag_offset_icon

func _on_control_gui_input(event: InputEvent):
	# Обработка перетаскивания за область ярлыка (не только кнопка)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed_pos = get_global_mouse_position()
			has_moved = false
			drag_offset_icon = mouse_pressed_pos - global_position
		else:
			if not has_moved:
				# Это был клик
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_click_time < double_click_delay:
					_open_browser()
					last_click_time = 0.0
				else:
					last_click_time = current_time
			is_dragging_icon = false
			has_moved = false
	
	if event is InputEventMouseMotion:
		if is_dragging_icon or (mouse_pressed_pos != Vector2.ZERO and (get_global_mouse_position() - mouse_pressed_pos).length() > 5):
			is_dragging_icon = true
			has_moved = true
			global_position = get_global_mouse_position() - drag_offset_icon

func _input(event):
	# Отпустили ЛКМ в любом месте — сразу прекращаем перетаскивание
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging_icon = false
		has_moved = false
		mouse_pressed_pos = Vector2.ZERO
		return
	# Движение мыши — двигаем ярлык только если идёт перетаскивание И кнопка ещё зажата
	if is_dragging_icon and event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			global_position = get_global_mouse_position() - drag_offset_icon
		else:
			is_dragging_icon = false

func _open_browser():
	print("Открываю браузер...")
	
	# Проверяем, не открыт ли уже браузер
	var main_scene = get_tree().root.get_child(0)  # Получаем корневую сцену (Main.tscn)
	var windows_layer = main_scene.get_node_or_null("WindowsLayer")
	
	if windows_layer:
		# Проверяем, есть ли уже открытое окно браузера
		for child in windows_layer.get_children():
			if child.name == "Browser" or child.name.begins_with("Browser"):
				print("Браузер уже открыт!")
				# Поднимаем существующее окно наверх
				child.z_index = 100
				return
	
	# Загружаем сцену браузера
	var browser_scene = load("res://Browser.tscn")
	if browser_scene == null:
		print("ОШИБКА: Не удалось загрузить сцену Browser.tscn")
		return
	
	# Создаем экземпляр сцены
	var browser_window = browser_scene.instantiate()
	if browser_window == null:
		print("ОШИБКА: Не удалось создать экземпляр сцены браузера")
		return
	
	# Устанавливаем имя для идентификации
	browser_window.name = "Browser"
	
	if windows_layer == null:
		print("ОШИБКА: Не найден WindowsLayer в основной сцене")
		# Добавляем в корень как запасной вариант
		get_tree().root.add_child(browser_window)
	else:
		# Добавляем окно браузера в WindowsLayer
		windows_layer.add_child(browser_window)
		print("✓ Браузер добавлен в WindowsLayer")
	
	# Устанавливаем начальную позицию окна
	browser_window.position = Vector2(100, 100)
	
	print("✓ Браузер открыт!")
