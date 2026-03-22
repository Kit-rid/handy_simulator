extends HBoxContainer

@onready var icon_rect: TextureRect = $Icon
@onready var name_label: Label = $ElementName

var element_icons = {
	"title": "res://icon.svg",
	"text": "res://icon.svg",
	"button": "res://icon.svg",
	"image": "res://icon.svg",
	"product_card": "res://icon.svg",
	"price": "res://icon.svg"
}

func setup(element_type: String):
	if not is_node_ready(): await ready
	name_label.text = element_type.capitalize()
	name_label.add_theme_color_override("font_color", Color.WHITE)
	
	var path = element_icons.get(element_type, "res://icon.svg")
	icon_rect.texture = load(path)
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
