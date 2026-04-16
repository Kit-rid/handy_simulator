extends Button

var target_window: Control

func setup(window: Control):
	target_window = window
	text = window.name
	var title_label = window.find_child("TitleLabel", true, false)
	if title_label and title_label is Label:
		text = title_label.text
	
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
		var parent = target_window.get_parent()
		if parent:
			var last_index = parent.get_child_count() - 1
			if target_window.get_index() == last_index:
				target_window.visible = false
			else:
				target_window.move_to_front()
		else:
			target_window.visible = false
