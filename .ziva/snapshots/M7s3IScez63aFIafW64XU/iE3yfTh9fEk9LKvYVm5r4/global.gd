extends Node

signal window_opened(window_node: Control)
signal window_closed(window_node: Control)
signal boss_quests_accepted
func register_window(window: Control) -> void:
	window_opened.emit(window)

func unregister_window(window: Control) -> void:
	window_closed.emit(window)

var boss_quests_unlocked: bool = false

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

var site_sections: Array[Dictionary] = []

func _ready() -> void:
	_reset_generated_site_files()



func accept_boss_quests() -> void:
	if boss_quests_unlocked:
		return
	boss_quests_unlocked = true
	boss_quests_accepted.emit()

func _reset_generated_site_files() -> void:
	var generator := SiteGenerator.new()
	var clean_html: String = generator.generate_html([])
	var clean_css: String = generator.generate_css([])
	generator.save_site(clean_html, clean_css)
