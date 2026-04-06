extends Control

const WINDOW_BORDER_COLOR: Color = Color(0.09, 0.09, 0.1, 1.0)
const WINDOW_BORDER_WIDTH: int = 1
const TITLEBAR_HEIGHT: float = 46.0
const WINDOW_PADDING: float = 18.0

const PANEL_BG_COLOR: Color = Color(0.19, 0.21, 0.26, 1.0)
const CONTENT_BG_COLOR: Color = Color(0.11, 0.12, 0.15, 1.0)
const CARD_BG_COLOR: Color = Color(0.16, 0.18, 0.22, 1.0)
const CARD_HOVER_BG_COLOR: Color = Color(0.19, 0.21, 0.26, 1.0)
const ACCENT_COLOR: Color = Color(0.2, 0.6, 1.0, 1.0)

const TASK_CREATION_MODAL_SCENE: PackedScene = preload("res://TaskCreationModal.tscn")

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_size: Vector2 = Vector2(820, 620)
var original_position: Vector2 = Vector2.ZERO
var is_maximized: bool = false

@onready var panel: Panel = $Panel
@onready var hbox: HBoxContainer = $Panel/HBoxContainer
@onready var content: ColorRect = $ColorRect
@onready var title_label: Label = $Panel/TitleLabel
@onready var indicator: ColorRect = $Indicator
@onready var page_container: Control = $ColorRect/PageContainer

@onready var back_button: Button = $Panel/HBoxContainer/BackButton
@onready var forward_button: Button = $Panel/HBoxContainer/ForwardButton
@onready var min_button: Button = $Panel/HBoxContainer/MinButton
@onready var max_button: Button = $Panel/HBoxContainer/MaxButton
@onready var close_button: Button = $Panel/HBoxContainer/CloseButton

@onready var home_view: VBoxContainer = $ColorRect/PageContainer/HomeView
@onready var create_task_btn: Button = $ColorRect/PageContainer/HomeView/CreateTaskBtn
@onready var sprint_label: Label = $ColorRect/PageContainer/HomeView/SprintLabel
@onready var sprint_list: VBoxContainer = $ColorRect/PageContainer/HomeView/SprintListVBox

@onready var details_view: VBoxContainer = $ColorRect/PageContainer/DetailsView
@onready var details_title: Label = $ColorRect/PageContainer/DetailsView/DetailsTitle
@onready var details_meta: Label = $ColorRect/PageContainer/DetailsView/DetailsMeta
@onready var details_description: Label = $ColorRect/PageContainer/DetailsView/DetailsDescription

@onready var create_task_view: VBoxContainer = $ColorRect/PageContainer/CreateTaskView
@onready var title_input: LineEdit = $ColorRect/PageContainer/CreateTaskView/TitleInputTask
@onready var priority_input: OptionButton = $ColorRect/PageContainer/CreateTaskView/PriorityInputTask
@onready var assignee_input: LineEdit = $ColorRect/PageContainer/CreateTaskView/AssigneeInputTask
@onready var description_input: TextEdit = $ColorRect/PageContainer/CreateTaskView/DescriptionInputTask
@onready var submit_btn: Button = $ColorRect/PageContainer/CreateTaskView/SubmitTaskBtn

var history: Array[String] = []
var history_index: int = -1
var current_task: Dictionary = {}

func _ready() -> void:
	original_size = size
	original_position = position

	if Global:
		Global.register_window(self)

	_connect_signals()
	_setup_app_ui()
	_resize_children_to_window()
	_ensure_window_border()
	move_to_front()

func _connect_signals() -> void:
	panel.gui_input.connect(_on_panel_gui_input)
	close_button.pressed.connect(queue_free)
	max_button.pressed.connect(_on_max_button)
	min_button.pressed.connect(_on_min_button)
	back_button.pressed.connect(_on_back_button)
	forward_button.pressed.connect(_on_forward_button)
	create_task_btn.pressed.connect(_on_create_task_pressed)
	submit_btn.pressed.connect(_on_submit_task)

func _setup_app_ui() -> void:
	_apply_window_styles()
	_apply_button_styles()
	_setup_texts()
	_setup_form_defaults()
	_layout_page_views()
	go_to_page("Home")

func _apply_window_styles() -> void:
	title_label.text = "Jira Desktop"
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 18)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL_BG_COLOR
	panel_style.border_color = WINDOW_BORDER_COLOR
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", panel_style)

	content.color = CONTENT_BG_COLOR

	indicator.color = ACCENT_COLOR
	indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE

	hbox.add_theme_constant_override("separation", 6)
	home_view.add_theme_constant_override("separation", 12)
	details_view.add_theme_constant_override("separation", 10)
	create_task_view.add_theme_constant_override("separation", 8)

func _apply_button_styles() -> void:
	_style_title_button(back_button, "←")
	_style_title_button(forward_button, "→")
	_style_title_button(min_button, "—")
	_style_title_button(max_button, "□")
	_style_title_button(close_button, "✕", true)

	create_task_btn.text = "＋ Создать задачу"
	create_task_btn.custom_minimum_size = Vector2(220, 40)
	create_task_btn.add_theme_color_override("font_color", Color.WHITE)
	create_task_btn.add_theme_stylebox_override("normal", _make_button_style(ACCENT_COLOR, 8))
	create_task_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.26, 0.67, 1.0, 1.0), 8))
	create_task_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.17, 0.50, 0.85, 1.0), 8))

	submit_btn.text = "Сохранить задачу"
	submit_btn.add_theme_color_override("font_color", Color.WHITE)
	submit_btn.add_theme_stylebox_override("normal", _make_button_style(Color(0.18, 0.55, 0.35, 1.0), 8))
	submit_btn.add_theme_stylebox_override("hover", _make_button_style(Color(0.20, 0.62, 0.39, 1.0), 8))
	submit_btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.15, 0.47, 0.30, 1.0), 8))

func _setup_texts() -> void:
	sprint_label.text = "Текущий спринт (Sprint 42)"
	sprint_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94, 1.0))
	sprint_label.add_theme_font_size_override("font_size", 16)

	$ColorRect/PageContainer/CreateTaskView/TitleLabelTask.text = "Название задачи"
	$ColorRect/PageContainer/CreateTaskView/PriorityLabelTask.text = "Приоритет"
	$ColorRect/PageContainer/CreateTaskView/AssigneeLabelTask.text = "Исполнитель"
	$ColorRect/PageContainer/CreateTaskView/DescriptionLabelTask.text = "Описание"

	for label_node: Label in [
		$ColorRect/PageContainer/CreateTaskView/TitleLabelTask,
		$ColorRect/PageContainer/CreateTaskView/PriorityLabelTask,
		$ColorRect/PageContainer/CreateTaskView/AssigneeLabelTask,
		$ColorRect/PageContainer/CreateTaskView/DescriptionLabelTask
	]:
		label_node.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))

	details_title.add_theme_color_override("font_color", Color.WHITE)
	details_title.add_theme_font_size_override("font_size", 22)
	details_meta.add_theme_color_override("font_color", Color(0.77, 0.82, 0.9, 1.0))
	details_description.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
	details_description.autowrap_mode = TextServer.AUTOWRAP_WORD

	back_button.tooltip_text = "Назад"
	forward_button.tooltip_text = "Вперед"
	min_button.tooltip_text = "Свернуть"
	max_button.tooltip_text = "Развернуть"
	close_button.tooltip_text = "Закрыть"

func _setup_form_defaults() -> void:
	priority_input.clear()
	priority_input.add_item("Low")
	priority_input.add_item("Medium")
	priority_input.add_item("High")
	priority_input.add_item("Critical")
	priority_input.selected = 1

	title_input.placeholder_text = "Введите название..."
	assignee_input.placeholder_text = "Ник пользователя..."
	description_input.placeholder_text = "Краткое описание задачи..."
	description_input.custom_minimum_size = Vector2(0, 120)

func _layout_page_views() -> void:
	for page: Control in [home_view, create_task_view, details_view]:
		page.set_anchors_preset(Control.PRESET_FULL_RECT)
		page.offset_left = 0
		page.offset_top = 0
		page.offset_right = 0
		page.offset_bottom = 0

	sprint_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	details_description.size_flags_vertical = Control.SIZE_EXPAND_FILL

func go_to_page(page_name: String, save_history: bool = true) -> void:
	if save_history:
		if history_index < history.size() - 1:
			history = history.slice(0, history_index + 1)
		history.append(page_name)
		history_index += 1

	for child: Node in page_container.get_children():
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
	for child: Node in sprint_list.get_children():
		child.queue_free()

	if Global:
		for task_variant: Variant in Global.sprint_tasks:
			if task_variant is Dictionary:
				_add_task_button(task_variant as Dictionary)

func _add_task_button(task_data: Dictionary) -> void:
	var btn := Button.new()
	var status: String = String(task_data.get("status", "Open"))
	btn.text = "%s   ·   %s" % [String(task_data.get("title", "Untitled")), status]
	btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(0, 42)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", _make_button_style(CARD_BG_COLOR, 8))
	btn.add_theme_stylebox_override("hover", _make_button_style(CARD_HOVER_BG_COLOR, 8))
	btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.16, 0.20, 1.0), 8))
	btn.pressed.connect(func() -> void: _show_task_details(task_data))
	sprint_list.add_child(btn)

func _show_task_details(task_data: Dictionary) -> void:
	current_task = task_data
	var title: String = String(task_data.get("title", "Без названия"))
	var priority: String = String(task_data.get("priority", "Medium"))
	var assignee: String = String(task_data.get("assignee", "Unknown"))
	var status: String = String(task_data.get("status", "Open"))
	var description: String = String(task_data.get("description", "Описание отсутствует"))

	details_title.text = title
	details_meta.text = "Приоритет: %s  |  Исполнитель: %s  |  Статус: %s" % [priority, assignee, status]
	details_description.text = description

	go_to_page("Details")

func _open_task_creation_modal() -> void:
	for child: Node in get_children():
		if child is TaskCreationModal:
			(child as Control).move_to_front()
			return

	var modal: TaskCreationModal = TASK_CREATION_MODAL_SCENE.instantiate()
	add_child(modal)
	modal.task_created.connect(_on_task_created_from_modal)
	modal.position = (size - modal.size) * 0.5
	modal.move_to_front()

func _on_task_created_from_modal(task_data: Dictionary) -> void:
	var assignee_name: String = "Unassigned"
	var assignee_variant: Variant = task_data.get("assignee", {})
	if assignee_variant is Dictionary:
		assignee_name = String((assignee_variant as Dictionary).get("name", "Unassigned"))
	elif assignee_variant is String:
		assignee_name = String(assignee_variant)
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
		_apply_task_to_site_sections(task_data)
		_regenerate_site_files()

	go_to_page("Home")

func _humanize_task_type(task_type: String) -> String:
	return task_type.replace("_", " ").capitalize()

func _apply_task_to_site_sections(task_data: Dictionary) -> void:
	if not Global:
		return

	var task_type: String = String(task_data.get("type", ""))
	var section_id: String = String(task_data.get("section_id", task_data.get("section", "")))
	if section_id.is_empty():
		section_id = "section_%d" % (Global.site_sections.size() + 1)

	match task_type:
		"create_section":
			if _find_site_section_index(section_id) != -1:
				return
			var add_section_task: Dictionary = {
				"id": int(task_data.get("id", Time.get_unix_time_from_system())),
				"type": "add_section",
				"section": section_id,
				"layout": "text_block",
				"style": task_data.get("style", {}),
				"elements": []
			}
			Global.site_sections.append(add_section_task)
		"edit_section":
			var existing_index: int = _find_site_section_index(section_id)
			if existing_index != -1:
				var section_task: Dictionary = Global.site_sections[existing_index]
				section_task["style"] = task_data.get("style", {})
				Global.site_sections[existing_index] = section_task
		"create_object":
			var section_index: int = _find_site_section_index(section_id)
			if section_index == -1:
				Global.site_sections.append({
					"id": int(Time.get_unix_time_from_system()),
					"type": "add_section",
					"section": section_id,
					"layout": "text_block",
					"elements": []
				})
				section_index = Global.site_sections.size() - 1

			var section_task_for_object: Dictionary = Global.site_sections[section_index]
			var elements: Array = section_task_for_object.get("elements", [])
			var object_type: String = String(task_data.get("object_type", ""))
			var mapped_element: String = _map_object_type_to_element(object_type)
			if not mapped_element.is_empty():
				elements.append(mapped_element)
			section_task_for_object["elements"] = elements
			Global.site_sections[section_index] = section_task_for_object
		_:
			pass

func _find_site_section_index(section_id: String) -> int:
	if not Global:
		return -1
	for i: int in Global.site_sections.size():
		var item: Dictionary = Global.site_sections[i]
		if String(item.get("section", "")) == section_id:
			return i
	return -1

func _map_object_type_to_element(object_type: String) -> String:
	match object_type:
		"text":
			return "text"
		"button":
			return "button"
		"image":
			return "image"
		"card":
			return "product_card"
		_:
			return ""

func _regenerate_site_files() -> void:
	if not Global:
		return
	var generator := SiteGenerator.new()
	generator.generate_from_tasks(Global.site_sections)

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

	var next_id: int = 1
	if Global and Global.sprint_tasks.size() > 0:
		next_id = int(Global.sprint_tasks[-1].get("id", 0)) + 1

	var task: Dictionary = {
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
		position = Vector2.ZERO
		size = get_viewport_rect().size
		is_maximized = true
	_resize_children_to_window()

func _on_min_button() -> void:
	visible = false

func _resize_children_to_window() -> void:
	var w: float = size.x
	var h: float = size.y

	panel.position = Vector2.ZERO
	panel.size = Vector2(w, TITLEBAR_HEIGHT)

	var controls_size: Vector2 = hbox.get_combined_minimum_size()
	hbox.position = Vector2(w - controls_size.x - 12.0, (TITLEBAR_HEIGHT - controls_size.y) * 0.5)
	hbox.size = controls_size

	title_label.position = Vector2(14.0, (TITLEBAR_HEIGHT - title_label.size.y) * 0.5)

	content.position = Vector2(0, TITLEBAR_HEIGHT)
	content.size = Vector2(w, h - TITLEBAR_HEIGHT)

	page_container.position = Vector2(WINDOW_PADDING, WINDOW_PADDING)
	page_container.size = content.size - Vector2(WINDOW_PADDING * 2.0, WINDOW_PADDING * 2.0)

	indicator.position = Vector2(0, TITLEBAR_HEIGHT - 1.0)
	indicator.size = Vector2(w, 1.0)

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
		style.border_color = WINDOW_BORDER_COLOR
		style.border_width_left = WINDOW_BORDER_WIDTH
		style.border_width_top = WINDOW_BORDER_WIDTH
		style.border_width_right = WINDOW_BORDER_WIDTH
		style.border_width_bottom = WINDOW_BORDER_WIDTH
		border.add_theme_stylebox_override("panel", style)
		add_child(border)

	border.offset_left = 0
	border.offset_top = 0
	border.offset_right = 0
	border.offset_bottom = 0
	border.move_to_front()

func _style_title_button(button: Button, button_text: String, is_danger: bool = false) -> void:
	button.text = button_text
	button.custom_minimum_size = Vector2(34, 30)
	button.add_theme_color_override("font_color", Color.WHITE)

	var normal_color: Color = Color(0.22, 0.24, 0.29, 1.0)
	var hover_color: Color = Color(0.28, 0.31, 0.36, 1.0)
	var pressed_color: Color = Color(0.18, 0.20, 0.24, 1.0)

	if is_danger:
		normal_color = Color(0.48, 0.20, 0.22, 1.0)
		hover_color = Color(0.63, 0.24, 0.27, 1.0)
		pressed_color = Color(0.40, 0.16, 0.18, 1.0)

	button.add_theme_stylebox_override("normal", _make_button_style(normal_color, 6))
	button.add_theme_stylebox_override("hover", _make_button_style(hover_color, 6))
	button.add_theme_stylebox_override("pressed", _make_button_style(pressed_color, 6))

func _make_button_style(bg_color: Color, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	return style
