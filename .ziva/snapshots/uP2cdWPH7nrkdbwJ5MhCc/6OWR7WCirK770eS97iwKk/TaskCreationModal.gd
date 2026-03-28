extends PanelContainer
class_name TaskCreationModal

signal task_created(task_data: Dictionary)

const EMPLOYEES_PATH: String = "res://data/employees.json"

const TASK_TYPES: Array[String] = [
	"add_section",
	"edit_section",
	"fix_bug",
	"refactor"
]

const SECTIONS: Array[String] = [
	"header",
	"hero",
	"catalog",
	"features",
	"footer"
]

const LAYOUTS: Array[String] = [
	"cards",
	"table",
	"carousel",
	"text_block",
	"title_button"
]

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var task_type_select: OptionButton = $VBoxContainer/TaskTypeSelect
@onready var assignee_select: OptionButton = $VBoxContainer/AssigneeSelect
@onready var section_select: OptionButton = $VBoxContainer/SectionSelect
@onready var layout_select: OptionButton = $VBoxContainer/LayoutSelect
@onready var create_button: Button = $VBoxContainer/CreateButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var _employees: Array[Dictionary] = []
var _id_counter: int = 0

func _ready() -> void:
	title_label.text = "Создать задачу"
	create_button.text = "Создать"
	cancel_button.text = "Отмена"

	_setup_static_options()
	_load_employees()
	_connect_signals()
	reset_form()

func _setup_static_options() -> void:
	task_type_select.clear()
	for task_type: String in TASK_TYPES:
		task_type_select.add_item(task_type)

	section_select.clear()
	for section_name: String in SECTIONS:
		section_select.add_item(section_name)

	layout_select.clear()
	for layout_name: String in LAYOUTS:
		layout_select.add_item(layout_name)

func _load_employees() -> void:
	assignee_select.clear()
	_employees.clear()

	if not FileAccess.file_exists(EMPLOYEES_PATH):
		push_warning("Employees file not found: %s" % EMPLOYEES_PATH)
		_update_create_button_state()
		return

	var raw_json: String = FileAccess.get_file_as_string(EMPLOYEES_PATH)
	var parsed: Variant = JSON.parse_string(raw_json)

	if parsed is not Array:
		push_warning("Invalid employees JSON format. Expected Array.")
		_update_create_button_state()
		return

	for entry: Variant in parsed:
		if entry is Dictionary and entry.has("name") and entry.has("role"):
			var employee: Dictionary = {
				"name": String(entry.get("name", "")),
				"role": String(entry.get("role", ""))
			}
			_employees.append(employee)
			assignee_select.add_item("%s (%s)" % [employee["name"], employee["role"]])

	if _employees.is_empty():
		push_warning("No valid employees found in JSON.")

func _connect_signals() -> void:
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

	task_type_select.item_selected.connect(_on_any_selection_changed)
	assignee_select.item_selected.connect(_on_any_selection_changed)
	section_select.item_selected.connect(_on_any_selection_changed)
	layout_select.item_selected.connect(_on_any_selection_changed)

func _on_any_selection_changed(_index: int) -> void:
	_update_create_button_state()

func _update_create_button_state() -> void:
	create_button.disabled = not _is_form_valid()

func _is_form_valid() -> bool:
	return (
		task_type_select.selected >= 0
		and section_select.selected >= 0
		and layout_select.selected >= 0
		and assignee_select.selected >= 0
		and not _employees.is_empty()
	)

func _on_create_pressed() -> void:
	if not _is_form_valid():
		push_warning("Task cannot be created: missing or invalid selection.")
		return

	var selected_employee: Dictionary = _employees[assignee_select.selected]
	var task: Dictionary = {
		"id": _generate_task_id(),
		"type": task_type_select.get_item_text(task_type_select.selected),
		"section": section_select.get_item_text(section_select.selected),
		"layout": layout_select.get_item_text(layout_select.selected),
		"elements": _build_elements_for_layout(layout_select.get_item_text(layout_select.selected)),
		"assignee": {
			"name": String(selected_employee.get("name", "")),
			"role": String(selected_employee.get("role", ""))
		}
	}

	_append_task_to_site_sections(task)
	_generate_site_from_global_sections()

	task_created.emit(task)
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()

func reset_form() -> void:
	if task_type_select.item_count > 0:
		task_type_select.select(0)
	if section_select.item_count > 0:
		section_select.select(0)
	if layout_select.item_count > 0:
		layout_select.select(0)
	if assignee_select.item_count > 0:
		assignee_select.select(0)

	_update_create_button_state()

func _generate_task_id() -> int:
	_id_counter += 1
	return int(Time.get_unix_time_from_system()) * 1000 + _id_counter

func _build_elements_for_layout(layout_name: String) -> Array[String]:
	match layout_name:
		"cards":
			return ["title", "product_card", "price", "button"]
		"table":
			return ["title", "text"]
		"carousel":
			return ["title", "image", "button"]
		"title_button":
			return ["title", "button"]
		_:
			return ["title", "text"]

func _append_task_to_site_sections(task: Dictionary) -> void:
	if not Global:
		return

	Global.site_sections.append(task)

func _generate_site_from_global_sections() -> void:
	if not Global:
		return

	var generator: SiteGenerator = SiteGenerator.new()
	generator.generate_from_tasks(Global.site_sections)
