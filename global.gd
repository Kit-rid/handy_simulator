extends Node

signal window_opened(window_node: Control)
signal window_closed(window_node: Control)

var sprint_tasks: Array[Dictionary] = [
	{
		"id": 1,
		"title": "Настроить Taskbar",
		"priority": "High",
		"assignee": "Alex",
		"description": "Сделать панель задач как в Windows с кликабельными иконками.",
		"status": "Done"
	},
	{
		"id": 2,
		"title": "Навигация в Jira",
		"priority": "Medium",
		"assignee": "Mila",
		"description": "Добавить кнопки назад/вперед и истории переходов между страницами.",
		"status": "In Progress"
	},
	{
		"id": 3,
		"title": "Темная тема Jira",
		"priority": "Low",
		"assignee": "Nikita",
		"description": "Сделать черный фон и белый текст в интерфейсе.",
		"status": "Done"
	}
]

var site_sections: Array[Dictionary] = [
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

func register_window(window: Control) -> void:
	window_opened.emit(window)

func unregister_window(window: Control) -> void:
	window_closed.emit(window)
