extends PanelContainer

@onready var type_label = $VBoxContainer/BlockTypeLabel
@onready var layout_label = $VBoxContainer/LayoutLabel
@onready var elements_container = $VBoxContainer/ElementsContainer

const ELEMENT_SCENE = preload("res://SiteElement.tscn")

func setup(section_type: String, layout_type: String, elements: Array):
	if not is_node_ready(): await ready
	
	type_label.text = "[ SECTION: " + section_type.to_upper() + " ]"
	layout_label.text = "Layout: " + layout_type.capitalize()
	
	type_label.add_theme_color_override("font_color", Color.CYAN)
	layout_label.add_theme_color_override("font_color", Color.GRAY)
	
	# Очистка контейнера элементов
	for child in elements_container.get_children():
		child.queue_free()
	
	# Добавление элементов
	for element_type in elements:
		var el = ELEMENT_SCENE.instantiate()
		elements_container.add_child(el)
		el.setup(element_type)
