extends Button
class_name OpenSiteButton

func _ready() -> void:
	text = "Посмотреть сайт"
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	if not Global:
		push_warning("Global autoload not found. Cannot generate site.")
		return

	var generator: SiteGenerator = SiteGenerator.new()
	generator.generate_from_tasks(Global.site_sections)
	generator.open_in_browser()
