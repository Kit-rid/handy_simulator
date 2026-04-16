extends Control
class_name JiraWindow

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_size: Vector2 = Vector2(800, 600)
var original_position: Vector2 = Vector2.ZERO
var is_maximized: bool = false

@onready var panel: Panel = $Panel
@onready var hbox: HBoxContainer = $Panel/HBoxContainer
@onready var content: ColorRect = $ColorRect
@onready var title_label: Label = $Panel/TitleLabel
@onready var page_container: Control = $ColorRect/PageContainer
@onready var back_button: Button = $Panel/HBoxContainer/BackButton
@onready var forward_button: Button = $Panel/HBoxContainer/ForwardButton
@onready var create_task_btn: Button = $ColorRect/PageContainer/HomeView/CreateTaskBtn
@onready var sprint_list: VBoxContainer = $ColorRect/PageContainer/HomeView/SprintListVBox
@onready var details_view: VBoxContainer = $ColorRect/PageContainer/DetailsView
@onready var details_title: Label = $ColorRect/PageContainer/DetailsView/DetailsTitle
@onready var details_meta: Label = $ColorRect/PageContainer/DetailsView/DetailsMeta
@onready var details_description: Label = $ColorRect/PageContainer/DetailsView/DetailsDescription
@onready var title_input: LineEdit = $ColorRect/PageContainer/CreateTaskView/TitleInputTask
@onready var priority_input: OptionButton = $ColorRect/PageContainer/CreateTaskView/PriorityInputTask
@onready var assignee_input: LineEdit = $ColorRect/PageContainer/CreateTaskView/AssigneeInputTask
@onready var description_input: TextEdit = $ColorRect/PageContainer/CreateTaskView/DescriptionInputTask
@onready var submit_btn: Button = $ColorRect/PageContainer/CreateTaskView/SubmitTaskBtn

var history: Array[String] = []
var history_index: int = -1
var current_task: Dictionary = {}

const TASK_CREATION_MODAL_SCENE: PackedScene = preload("res://TaskCreationModal.tscn")

func _ready() -> void:
	original_size = size
	original_position = position

	if Global:
		Global.register_window(self)

	panel.gui_input.connect(_on_panel_gui_input)
	$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)
	$Panel/HBoxContainer/MaxButton.pressed.connect(_on_max_button)
	$Panel/HBoxContainer/MinButton.pressed.connect(_on_min_button)
	back_button.pressed.connect(_on_back_button)
	forward_button.pressed.connect(_on_forward_button)
	create_task_btn.pressed.connect(_on_create_task_pressed)
	submit_btn.pressed.connect(_on_submit_task)

	_setup_app_ui()
	_resize_children_to_window()
	_ensure_window_border()
	move_to_front()

func _setup_app_ui() -> void:
	title_label.text = "Jira Desktop"
	title_label.add_theme_color_override("font_color", Color.WHITE)
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	content.color = Color(0.16, 0.18, 0.22, 1.0)

	$ColorRect/PageContainer/HomeView/CreateTaskBtn.text = "Создать задачу"
	$ColorRect/PageContainer/HomeView/SprintLabel.text = "Текущий спринт (Sprint 42):"
	$ColorRect/PageContainer/HomeView/CreateTaskBtn.add_theme_color_override("font_color", Color.WHITE)
	$ColorRect/PageContainer/HomeView/SprintLabel.add_theme_color_override("font_color", Color.WHITE)

	$ColorRect/PageContainer/CreateTaskView/TitleLabelTask.text = "Название задачи:"
	$ColorRect/PageContainer/CreateTaskView/PriorityLabelTask.text = "Приоритет:"
	$ColorRect/PageContainer/CreateTaskView/AssigneeLabelTask.text = "Исполнитель:"
	$ColorRect/PageContainer/CreateTaskView/DescriptionLabelTask.text = "Описание:"
	$ColorRect/PageContainer/CreateTaskView/SubmitTaskBtn.text = "Сохранить задачу"

	for label_node in [
		$ColorRect/PageContainer/CreateTaskView/TitleLabelTask,
		$ColorRect/PageContainer/CreateTaskView/PriorityLabelTask,
		$ColorRect/PageContainer/CreateTaskView/AssigneeLabelTask,
		$ColorRect/PageContainer/CreateTaskView/DescriptionLabelTask
	]:
		label_node.add_theme_color_override("font_color", Color.WHITE)

	$ColorRect/PageContainer/CreateTaskView/SubmitTaskBtn.add_theme_color_override("font_color", Color.WHITE)

	priority_input.clear()
	priority_input.add_item("Low")
	priority_input.add_item("Medium")
	priority_input.add_item("High")
	priority_input.add_item("Critical")
	priority_input.selected = 1

	title_input.placeholder_text = "Введите название..."
	assignee_input.placeholder_text = "Ник пользователя..."

	back_button.text = "←"
	forward_button.text = "→"
	back_button.add_theme_color_override("font_color", Color.WHITE)
	forward_button.add_theme_color_override("font_color", Color.WHITE)

	go_to_page("Home")

func go_to_page(page_name: String, save_history: bool = true) -> void:
	if save_history:
		if history_index < history.size() - 1:
			history = history.slice(0, history_index + 1)
		history.append(page_name)
		history_index += 1

	for child in page_container.get_children():
		child.visible = false

	var page: Node = page_container.get_node_or_null(page_name + "View")
	if page:
		page.visible = true
		if page_name == "Home":
			_refresh_sprint_list()

	_update_nav_buttons()

func _update_nav_buttons() -> void:
	back_button.disabled = history_index <= 0
	forward_button.disabled = history_index >= history.size() - 1

func _on_back_button() -> void:
	if history_index > 0:
		history_index -= 1
		go_to_page(history[history_index], false)

func _on_forward_button() -> void:
	if history_index < history.size() - 1:
		history_index += 1
		go_to_page(history[history_index], false)

func _on_create_task_pressed() -> void:
	_open_task_creation_modal()

func _refresh_sprint_list() -> void:
	for child in sprint_list.get_children():
		child.queue_free()

	if Global:
		for task in Global.sprint_tasks:
			_add_task_button(task)

func _add_task_button(task_data: Dictionary) -> void:
	var btn := Button.new()
	var status: String = task_data.get("status", "Open")
	btn.text = "- %s (%s)" % [task_data.get("title", "Untitled"), status]
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(func(): _show_task_details(task_data))
	sprint_list.add_child(btn)

func _show_task_details(task_data: Dictionary) -> void:
	current_task = task_data
	var title: String = task_data.get("title", "Без названия")
	var priority: String = task_data.get("priority", "Medium")
	var assignee: String = task_data.get("assignee", "Unknown")
	var status: String = task_data.get("status", "Open")
	var description: String = task_data.get("description", "Описание отсутствует")

	details_title.text = title
	details_meta.text = "Приоритет: %s | Исполнитель: %s | Статус: %s" % [priority, assignee, status]
	details_description.text = description

	details_title.add_theme_color_override("font_color", Color.WHITE)
	details_meta.add_theme_color_override("font_color", Color.WHITE)
	details_description.add_theme_color_override("font_color", Color.WHITE)

	go_to_page("Details")

func _open_task_creation_modal() -> void:
	for child in get_children():
		if child is TaskCreationModal:
			(child as Control).move_to_front()
			return

	var modal: TaskCreationModal = TASK_CREATION_MODAL_SCENE.instantiate()
	add_child(modal)
	modal.task_created.connect(_on_task_created_from_modal)
	modal.position = (size - modal.size) * 0.5
	modal.move_to_front()

func _on_task_created_from_modal(task_data: Dictionary) -> void:
	var assignee_info: Dictionary = task_data.get("assignee", {})
	var assignee_name: String = String(assignee_info.get("name", "Unassigned"))
	var task_type: String = String(task_data.get("type", "add_section"))
	var section_name: String = String(task_data.get("section", "unknown"))
	var layout_name: String = String(task_data.get("layout", "default"))

	var priority_by_type: Dictionary = {
		"fix_bug": "High",
		"refactor": "Medium",
		"add_section": "Medium",
		"edit_section": "Low"
	}

	var task_title: String = "%s: %s" % [_humanize_task_type(task_type), section_name.capitalize()]
	var task_priority: String = String(priority_by_type.get(task_type, "Medium"))
	var task_description: String = "Тип: %s\nСекция: %s\nLayout: %s\nИсполнитель: %s" % [
		_humanize_task_type(task_type),
		section_name,
		layout_name,
		assignee_name
	]

	var task: Dictionary = {
		"id": int(task_data.get("id", Time.get_unix_time_from_system())),
		"title": task_title,
		"priority": task_priority,
		"assignee": assignee_name,
		"description": task_description,
		"status": "Open"
	}

	if Global:
		Global.sprint_tasks.append(task)

	go_to_page("Home")

func _humanize_task_type(task_type: String) -> String:
	return task_type.replace("_", " ").capitalize()

func _on_submit_task() -> void:
	var title: String = title_input.text.strip_edges()
	var assignee: String = assignee_input.text.strip_edges()
	var description: String = description_input.text.strip_edges()
	var priority: String = priority_input.get_item_text(priority_input.selected)

	if title.is_empty():
		title = "Без названия"
	if assignee.is_empty():
		assignee = "Unassigned"
	if description.is_empty():
		description = "Описание отсутствует"

	var next_id := 1
	if Global and Global.sprint_tasks.size() > 0:
		next_id = Global.sprint_tasks[-1].get("id", 0) + 1

	var task := {
		"id": next_id,
		"title": title,
		"priority": priority,
		"assignee": assignee,
		"description": description,
		"status": "Open"
	}

	if Global:
		Global.sprint_tasks.append(task)

	title_input.text = ""
	assignee_input.text = ""
	description_input.text = ""

	go_to_page("Home")

func _exit_tree() -> void:
	if Global:
		Global.unregister_window(self)

func _on_max_button() -> void:
	if is_maximized:
		size = original_size
		position = original_position
		is_maximized = false
	else:
		original_size = size
		original_position = position
		var viewport_size := get_viewport_rect().size
		position = Vector2.ZERO
		size = viewport_size
		is_maximized = true
	_resize_children_to_window()

func _on_min_button() -> void:
	visible = false

func _resize_children_to_window() -> void:
	var w := size.x
	var h := size.y
	var title_height := 40.0

	if panel:
		panel.size = Vector2(w, title_height)
		panel.position = Vector2.ZERO
		if hbox:
			var hbox_size := hbox.get_combined_minimum_size()
			hbox.position = Vector2(w - hbox_size.x - 10, (title_height - hbox_size.y) / 2)
			hbox.size = hbox_size

	if content:
		content.position = Vector2(0, title_height)
		content.size = Vector2(w, h - title_height)

	_ensure_window_border()

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		move_to_front()

func _ensure_window_border() -> void:
	var border: Panel = get_node_or_null("WindowBorder")
	if border == null:
		border = Panel.new()
		border.name = "WindowBorder"
		border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		border.focus_mode = Control.FOCUS_NONE
		border.set_anchors_preset(Control.PRESET_FULL_RECT)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color(0.09, 0.09, 0.1, 1.0)
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		border.add_theme_stylebox_override("panel", style)
		add_child(border)

	border.offset_left = 0
	border.offset_top = 0
	border.offset_right = 0
	border.offset_bottom = 0
	border.move_to_front()
