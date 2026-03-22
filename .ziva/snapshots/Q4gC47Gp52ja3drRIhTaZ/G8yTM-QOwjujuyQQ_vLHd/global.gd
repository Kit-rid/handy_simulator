extends Node

signal window_opened(window_node: Control)
signal window_closed(window_node: Control)

var sprint_tasks = [
	{
		"id": 1,
		"type": "add_section",
		"section": "hero",
		"layout": "title_button_image",
		"elements": ["title", "button", "image"]
	},
	{
		"id": 2,
		"type": "add_section",
		"section": "catalog",
		"layout": "cards",
		"elements": ["product_card", "price", "button"]
	},
	{
		"id": 3,
		"type": "add_section",
		"section": "footer",
		"layout": "simple",
		"elements": ["text", "button"]
	}
]

func register_window(window: Control):
	window_opened.emit(window)

func unregister_window(window: Control):
	window_closed.emit(window)
