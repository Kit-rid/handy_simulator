extends Button

var target_window: Control

func setup(window: Control):
	target_window = window
	text = window.name
	# Если в окне есть TitleLabel, возьмем текст оттуда
	var title_label = window.find_child("TitleLabel", true, false)
	if title_label and title_label is Label:
		text = title_label.text
	
	# Попробуем добавить стандартную иконку Godot для начала
	icon = load("res://icon.svg")
	expand_icon = true
	
	pressed.connect(_on_pressed)

func _on_pressed():
	if not is_instance_valid(target_window):
		queue_free()
		return
		
	if not target_window.visible:
		target_window.visible = true
		target_window.move_to_front()
	else:
		# Если окно видимо, проверяем, находится ли оно на переднем плане
		var parent = target_window.get_parent()
		if parent:
			var last_index = parent.get_child_count() - 1
			if target_window.get_index() == last_index:
				# Оно уже впереди всех, значит сворачиваем (как в Windows)
				target_window.visible = false
			else:
				# Оно не впереди, выносим на передний план
				target_window.move_to_front()
		else:
			target_window.visible = false
