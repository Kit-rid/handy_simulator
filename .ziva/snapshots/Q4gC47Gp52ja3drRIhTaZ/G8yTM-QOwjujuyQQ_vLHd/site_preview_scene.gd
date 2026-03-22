extends Control

@onready var blocks_container = $ScrollContainer/VBoxContainer
const SITE_BLOCK_SCENE = preload("res://SiteBlock.tscn")

func _ready():
	_build_site()
	
	# Подключаем кнопку закрытия если она есть
	if has_node("Panel/HBoxContainer/CloseButton"):
		$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)

func _build_site():
	# Очистка контейнера перед сборкой
	for child in blocks_container.get_children():
		child.queue_free()
	
	# Сборка блоков из Global.sprint_tasks
	# Используем Global (с большой буквы) так как мы добавили class_name
	for task in Global.sprint_tasks:
		if task.get("type") == "add_section":
			var block = SITE_BLOCK_SCENE.instantiate()
			blocks_container.add_child(block)
			block.setup(
				task.get("section", "unknown"),
				task.get("layout", "default"),
				task.get("elements", [])
			)
