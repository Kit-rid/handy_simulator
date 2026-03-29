extends PanelContainer
class_name TaskCreationModal

signal task_created(task_data: Dictionary)

const ACTION_TYPES: Array[String] = [
	"create_section",
	"edit_section",
	"create_object",
	"edit_object"
]

const SECTION_COLORS: Array[String] = ["white", "blue", "gray", "dark"]
const OBJECT_COLOR_OPTIONS: Array[String] = ["black", "white", "blue", "gray", "dark"]
const SECTION_HEIGHTS: Array[String] = ["50%", "75%", "100%"]
const ALIGN_OPTIONS: Array[String] = ["left", "center", "right"]

const OBJECT_TYPES: Array[String] = ["text", "button", "image", "card"]
const ASSIGNEE_OPTIONS: Array[String] = ["Alex", "Mila", "Nikita", "Unassigned"]
const TEXT_CONTENT_PRESETS: Array[String] = [
	"Hello",
	"Welcome",
	"Новый текстовый блок"
]
const BUTTON_TEXT_PRESETS: Array[String] = [
	"Click",
	"Подробнее",
	"Купить"
]
const FONT_SIZE_OPTIONS: Array[String] = ["14", "16", "18", "24", "32"]
const BUTTON_SIZE_OPTIONS: Array[String] = ["small", "medium", "large"]

const IMAGES_DIR: String = "res://assets/images"

const CSS_MAP: Dictionary = {
	"bg_color": {
		"white": "bg-white",
		"blue": "bg-blue",
		"gray": "bg-gray",
		"dark": "bg-dark"
	},
	"align": {
		"left": "align-left",
		"center": "align-center",
		"right": "align-right"
	},
	"height": {
		"50%": "h-50",
		"75%": "h-75",
		"100%": "h-100"
	},
	"font_size": {
		"14": "fs-14",
		"16": "fs-16",
		"18": "fs-18",
		"24": "fs-24",
		"32": "fs-32"
	},
	"color": {
		"white": "text-white",
		"blue": "text-blue",
		"gray": "text-gray",
		"dark": "text-dark",
		"black": "text-black"
	},
	"size": {
		"small": "size-sm",
		"medium": "size-md",
		"large": "size-lg"
	}
}

const PLACEHOLDER_NO_SECTIONS: String = "— нет секций —"
const PLACEHOLDER_NO_OBJECTS: String = "— нет объектов —"

const WINDOW_BORDER_COLOR: Color = Color(0.09, 0.09, 0.1, 1.0)
const PANEL_BG_COLOR: Color = Color(0.13, 0.15, 0.18, 0.98)
const CONTENT_BG_COLOR: Color = Color(0.11, 0.12, 0.15, 1.0)
const CARD_BG_COLOR: Color = Color(0.16, 0.18, 0.22, 1.0)
const CARD_HOVER_BG_COLOR: Color = Color(0.19, 0.21, 0.26, 1.0)
const ACCENT_COLOR: Color = Color(0.2, 0.6, 1.0, 1.0)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var action_type_select: OptionButton = $VBoxContainer/TaskTypeSelect
@onready var legacy_assignee_select: OptionButton = $VBoxContainer/AssigneeSelect
@onready var legacy_section_select: OptionButton = $VBoxContainer/SectionSelect
@onready var legacy_layout_select: OptionButton = $VBoxContainer/LayoutSelect
@onready var create_button: Button = $VBoxContainer/CreateButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var site_structure: Dictionary = {
	"sections": []
}

var _fields_container: VBoxContainer
var _dynamic_controls: Dictionary = {}
var _is_rebuilding_ui: bool = false
var _id_counter: int = 0

func _ready() -> void:
	title_label.text = "Создать задачу"
	create_button.text = "Создать"
	cancel_button.text = "Отмена"

	_apply_modal_style()
	_setup_action_type_select()
	_hide_legacy_controls()
	_create_dynamic_fields_container()
	_bootstrap_site_structure()
	_connect_signals()
	reset_form()

# Public API for future integrations.
func set_site_structure(structure: Dictionary) -> void:
	site_structure = _sanitize_site_structure(structure)
	update_form_by_action()

func reset_form() -> void:
	if action_type_select.item_count > 0:
		action_type_select.select(0)
	update_form_by_action()

func update_form_by_action() -> void:
	_is_rebuilding_ui = true

	var selected_action: String = _get_selected_action()
	var previous_state: Dictionary = _capture_form_state()

	_clear_dynamic_fields()

	match selected_action:
		"create_section":
			_build_create_section_fields(previous_state)
		"edit_section":
			_build_edit_section_fields(previous_state)
		"create_object":
			_build_create_object_fields(previous_state)
		"edit_object":
			_build_edit_object_fields(previous_state)
		_:
			_build_create_section_fields(previous_state)

	_is_rebuilding_ui = false
	_update_create_button_state()

func _connect_signals() -> void:
	create_button.pressed.connect(_on_create_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	action_type_select.item_selected.connect(_on_action_type_changed)

func _setup_action_type_select() -> void:
	action_type_select.clear()
	for action_type: String in ACTION_TYPES:
		action_type_select.add_item(action_type)

func _hide_legacy_controls() -> void:
	for node: Control in [legacy_assignee_select, legacy_section_select, legacy_layout_select]:
		node.visible = false
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _create_dynamic_fields_container() -> void:
	_fields_container = VBoxContainer.new()
	_fields_container.name = "DynamicFields"
	_fields_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fields_container.add_theme_constant_override("separation", 10)
	$VBoxContainer.add_child(_fields_container)
	$VBoxContainer.move_child(_fields_container, create_button.get_index())

func _bootstrap_site_structure() -> void:
	# По умолчанию сайт пустой, согласно требованиям.
	site_structure = _sanitize_site_structure({"sections": []})

	# Мягкая обратная совместимость: если в Global уже есть site_structure, используем его.
	if Global and _object_has_property(Global, "site_structure"):
		var from_global: Variant = Global.get("site_structure")
		if from_global is Dictionary:
			site_structure = _sanitize_site_structure(from_global)

func _sanitize_site_structure(input_data: Dictionary) -> Dictionary:
	var result: Dictionary = {"sections": []}
	var sections_variant: Variant = input_data.get("sections", [])
	if sections_variant is not Array:
		return result

	var sections_result: Array[Dictionary] = []
	for section_variant: Variant in sections_variant:
		if section_variant is not Dictionary:
			continue

		var section: Dictionary = section_variant
		var safe_section: Dictionary = {
			"id": String(section.get("id", "")),
			"type": String(section.get("type", "section")),
			"style": _sanitize_style_dict(section.get("style", {})),
			"children": []
		}

		var children_variant: Variant = section.get("children", [])
		if children_variant is Array:
			var children_result: Array[Dictionary] = []
			for child_variant: Variant in children_variant:
				if child_variant is Dictionary:
					var child: Dictionary = child_variant
					children_result.append({
						"id": String(child.get("id", "")),
						"type": String(child.get("type", "text")),
						"content": child.get("content", ""),
						"style": _sanitize_style_dict(child.get("style", {}))
					})
			safe_section["children"] = children_result

		if safe_section["id"].is_empty():
			safe_section["id"] = "section_%d" % (sections_result.size() + 1)

		sections_result.append(safe_section)

	result["sections"] = sections_result
	return result

func _sanitize_style_dict(style_variant: Variant) -> Dictionary:
	if style_variant is Dictionary:
		return (style_variant as Dictionary).duplicate(true)
	return {}

func _build_create_section_fields(previous_state: Dictionary) -> void:
	_add_option_field(
		"assignee",
		"Assignee",
		ASSIGNEE_OPTIONS,
		String(previous_state.get("assignee", "Unassigned"))
	)
	_add_option_field(
		"bg_color",
		"Color",
		SECTION_COLORS,
		String(previous_state.get("bg_color", "white"))
	)
	_add_option_field(
		"height",
		"Height",
		SECTION_HEIGHTS,
		String(previous_state.get("height", "100%"))
	)
	_add_option_field(
		"align",
		"Align",
		ALIGN_OPTIONS,
		String(previous_state.get("align", "center"))
	)

func _build_edit_section_fields(previous_state: Dictionary) -> void:
	var preferred_section_id: String = String(previous_state.get("section_id", ""))
	_add_section_select_field("section_id", "Section", preferred_section_id)
	_add_option_field(
		"assignee",
		"Assignee",
		ASSIGNEE_OPTIONS,
		String(previous_state.get("assignee", "Unassigned"))
	)

	_add_option_field(
		"bg_color",
		"Color",
		SECTION_COLORS,
		String(previous_state.get("bg_color", "white"))
	)
	_add_option_field(
		"height",
		"Height",
		SECTION_HEIGHTS,
		String(previous_state.get("height", "100%"))
	)
	_add_option_field(
		"align",
		"Align",
		ALIGN_OPTIONS,
		String(previous_state.get("align", "center"))
	)

func _build_create_object_fields(previous_state: Dictionary) -> void:
	var preferred_section_id: String = String(previous_state.get("section_id", ""))
	_add_section_select_field("section_id", "Section", preferred_section_id)
	_add_option_field(
		"assignee",
		"Assignee",
		ASSIGNEE_OPTIONS,
		String(previous_state.get("assignee", "Unassigned"))
	)

	var preferred_object_type: String = String(previous_state.get("object_type", "text"))
	if preferred_object_type.is_empty():
		preferred_object_type = "text"
	_add_option_field("object_type", "ObjectType", OBJECT_TYPES, preferred_object_type)

	_build_object_specific_fields(previous_state, preferred_object_type)

func _build_edit_object_fields(previous_state: Dictionary) -> void:
	var preferred_section_id: String = String(previous_state.get("section_id", ""))
	_add_section_select_field("section_id", "Section", preferred_section_id)
	_add_option_field(
		"assignee",
		"Assignee",
		ASSIGNEE_OPTIONS,
		String(previous_state.get("assignee", "Unassigned"))
	)

	var selected_section_id: String = _get_selected_value("section_id")
	var preferred_object_id: String = String(previous_state.get("object_id", ""))
	_add_object_select_field("object_id", "Object", selected_section_id, preferred_object_id)

	var selected_object: Dictionary = _get_selected_object(selected_section_id)
	var object_type: String = String(selected_object.get("type", previous_state.get("object_type", "text")))
	if object_type.is_empty():
		object_type = "text"

	var object_type_control: OptionButton = _add_option_field("object_type", "ObjectType", OBJECT_TYPES, object_type)
	object_type_control.disabled = true

	var merged_state: Dictionary = previous_state.duplicate(true)
	if not selected_object.is_empty():
		merged_state = _state_from_object(selected_object)
	merged_state["object_type"] = object_type

	_build_object_specific_fields(merged_state, object_type)

func _build_object_specific_fields(state: Dictionary, object_type: String) -> void:
	match object_type:
		"text":
			_add_option_field(
				"content",
				"Content",
				TEXT_CONTENT_PRESETS,
				String(state.get("content", TEXT_CONTENT_PRESETS[0]))
			)
			_add_option_field(
				"font_size",
				"FontSize",
				FONT_SIZE_OPTIONS,
				String(state.get("font_size", "18"))
			)
			_add_option_field(
				"color",
				"Color",
				OBJECT_COLOR_OPTIONS,
				String(state.get("color", "black"))
			)
			_add_option_field(
				"align",
				"Align",
				ALIGN_OPTIONS,
				String(state.get("align", "center"))
			)
		"button":
			_add_option_field(
				"content",
				"Text",
				BUTTON_TEXT_PRESETS,
				String(state.get("content", BUTTON_TEXT_PRESETS[0]))
			)
			_add_option_field(
				"color",
				"Color",
				OBJECT_COLOR_OPTIONS,
				String(state.get("color", "blue"))
			)
			_add_option_field(
				"size",
				"Size",
				BUTTON_SIZE_OPTIONS,
				String(state.get("size", "medium"))
			)
			_add_option_field(
				"align",
				"Align",
				ALIGN_OPTIONS,
				String(state.get("align", "center"))
			)
		"image":
			var images: Array[String] = _list_images_in_assets()
			if images.is_empty():
				images = ["res://icon.svg"]
			_add_option_field(
				"content",
				"ImageSelect",
				images,
				String(state.get("content", images[0]))
			)
			_add_option_field(
				"align",
				"Align",
				ALIGN_OPTIONS,
				String(state.get("align", "center"))
			)
		"card":
			# Карточка фиксирована: 15% от родителя.
			_add_readonly_info_field("card_info", "Card", "width: 15%")
			_add_option_field(
				"align",
				"Align",
				ALIGN_OPTIONS,
				String(state.get("align", "center"))
			)
		_:
			_add_option_field(
				"content",
				"Content",
				TEXT_CONTENT_PRESETS,
				TEXT_CONTENT_PRESETS[0]
			)

func _add_section_select_field(key: String, label_text: String, preferred_id: String) -> OptionButton:
	var sections: Array[Dictionary] = _get_sections_array()
	var option: OptionButton = _create_option_row(key, label_text)

	if sections.is_empty():
		option.add_item(PLACEHOLDER_NO_SECTIONS)
		option.set_item_metadata(0, "")
		option.disabled = true
		return option

	var selected_index: int = 0
	for i: int in sections.size():
		var section: Dictionary = sections[i]
		var section_id: String = String(section.get("id", ""))
		option.add_item(section_id)
		option.set_item_metadata(i, section_id)
		if not preferred_id.is_empty() and section_id == preferred_id:
			selected_index = i

	option.select(selected_index)
	return option

func _add_object_select_field(key: String, label_text: String, section_id: String, preferred_id: String) -> OptionButton:
	var option: OptionButton = _create_option_row(key, label_text)
	var objects: Array[Dictionary] = _get_objects_in_section(section_id)

	if objects.is_empty():
		option.add_item(PLACEHOLDER_NO_OBJECTS)
		option.set_item_metadata(0, "")
		option.disabled = true
		return option

	var selected_index: int = 0
	for i: int in objects.size():
		var obj: Dictionary = objects[i]
		var object_id: String = String(obj.get("id", ""))
		var object_type: String = String(obj.get("type", "object"))
		option.add_item("%s (%s)" % [object_id, object_type])
		option.set_item_metadata(i, object_id)
		if not preferred_id.is_empty() and object_id == preferred_id:
			selected_index = i

	option.select(selected_index)
	return option

func _add_option_field(key: String, label_text: String, values: Array[String], preferred_value: String = "") -> OptionButton:
	var option: OptionButton = _create_option_row(key, label_text)
	if values.is_empty():
		return option

	var selected_index: int = 0
	for i: int in values.size():
		option.add_item(values[i])
		if not preferred_value.is_empty() and values[i] == preferred_value:
			selected_index = i

	option.select(selected_index)
	return option

func _add_readonly_info_field(key: String, label_text: String, value: String) -> Label:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var field_label := Label.new()
	field_label.text = label_text
	field_label.custom_minimum_size = Vector2(120, 0)
	field_label.add_theme_color_override("font_color", Color.WHITE)

	var info_label := Label.new()
	info_label.text = value
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.94, 1.0))

	row.add_child(field_label)
	row.add_child(info_label)
	_fields_container.add_child(row)
	_dynamic_controls[key] = info_label
	return info_label

func _create_option_row(key: String, label_text: String) -> OptionButton:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var field_label := Label.new()
	field_label.text = label_text
	field_label.custom_minimum_size = Vector2(120, 0)
	field_label.add_theme_color_override("font_color", Color.WHITE)

	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size = Vector2(0, 34)
	option.add_theme_color_override("font_color", Color.WHITE)
	_style_option_button(option)

	row.add_child(field_label)
	row.add_child(option)
	_fields_container.add_child(row)

	_dynamic_controls[key] = option
	option.item_selected.connect(_on_dynamic_option_changed.bind(key))
	return option

func _capture_form_state() -> Dictionary:
	var state: Dictionary = {}
	state["action"] = _get_selected_action()

	for key_variant: Variant in _dynamic_controls.keys():
		var key: String = String(key_variant)
		var control: Variant = _dynamic_controls[key]
		if control is OptionButton:
			var opt: OptionButton = control
			if key == "section_id" or key == "object_id":
				if opt.selected >= 0:
					state[key] = String(opt.get_item_metadata(opt.selected))
			else:
				if opt.selected >= 0:
					state[key] = opt.get_item_text(opt.selected)

	return state

func _state_from_object(selected_object: Dictionary) -> Dictionary:
	var style: Dictionary = selected_object.get("style", {})
	var state: Dictionary = {
		"object_type": String(selected_object.get("type", "text")),
		"content": String(selected_object.get("content", "")),
		"align": String(style.get("align", "center")),
		"color": String(style.get("color", "black")),
		"font_size": String(style.get("font_size", "18")),
		"size": String(style.get("size", "medium"))
	}
	return state

func _clear_dynamic_fields() -> void:
	_dynamic_controls.clear()
	for child: Node in _fields_container.get_children():
		child.queue_free()

func _on_action_type_changed(_index: int) -> void:
	if _is_rebuilding_ui:
		return
	update_form_by_action()

func _on_dynamic_option_changed(_index: int, key: String) -> void:
	if _is_rebuilding_ui:
		return

	if key == "section_id" or key == "object_id" or key == "object_type":
		update_form_by_action()
	else:
		_update_create_button_state()

func _on_create_pressed() -> void:
	if not _is_form_valid():
		push_warning("Task cannot be created: missing or invalid selection.")
		return

	var task_data: Dictionary = _build_task_data()
	if task_data.is_empty():
		push_warning("Task data is empty. Nothing emitted.")
		return

	task_created.emit(task_data)
	queue_free()

func _on_cancel_pressed() -> void:
	queue_free()

func _build_task_data() -> Dictionary:
	var action: String = _get_selected_action()
	var task_id: int = _generate_task_id()
	var assignee_name: String = _get_selected_value("assignee")
	if assignee_name.is_empty():
		assignee_name = "Unassigned"
	var assignee_data: Dictionary = {"name": assignee_name}

	match action:
		"create_section":
			var new_section_id: String = _generate_section_id()
			var section_style: Dictionary = _collect_section_style()
			return {
				"id": task_id,
				"type": "create_section",
				"assignee": assignee_data,
				"section_id": new_section_id,
				"style": section_style,
				"css_classes": _style_to_css_classes(section_style),
				# Поля для мягкой совместимости со старым обработчиком в браузере.
				"section": new_section_id,
				"layout": "section"
			}
		"edit_section":
			var section_id: String = _get_selected_value("section_id")
			var edit_section_style: Dictionary = _collect_section_style()
			return {
				"id": task_id,
				"type": "edit_section",
				"assignee": assignee_data,
				"section_id": section_id,
				"style": edit_section_style,
				"css_classes": _style_to_css_classes(edit_section_style),
				"section": section_id,
				"layout": "section"
			}
		"create_object":
			var section_for_object: String = _get_selected_value("section_id")
			var object_type: String = _get_selected_value("object_type")
			var object_payload: Dictionary = _collect_object_payload(object_type)
			return {
				"id": task_id,
				"type": "create_object",
				"assignee": assignee_data,
				"section_id": section_for_object,
				"object_type": object_type,
				"content": object_payload.get("content", ""),
				"style": object_payload.get("style", {}),
				"css_classes": _style_to_css_classes(object_payload.get("style", {})),
				"section": section_for_object,
				"layout": object_type
			}
		"edit_object":
			var section_for_edit_object: String = _get_selected_value("section_id")
			var object_id: String = _get_selected_value("object_id")
			var edit_object_type: String = _get_selected_value("object_type")
			var edit_payload: Dictionary = _collect_object_payload(edit_object_type)
			return {
				"id": task_id,
				"type": "edit_object",
				"assignee": assignee_data,
				"section_id": section_for_edit_object,
				"object_id": object_id,
				"style": edit_payload.get("style", {}),
				"content": edit_payload.get("content", ""),
				"css_classes": _style_to_css_classes(edit_payload.get("style", {})),
				"section": section_for_edit_object,
				"layout": edit_object_type
			}
		_:
			return {}

func _collect_section_style() -> Dictionary:
	return {
		"bg_color": _get_selected_value("bg_color"),
		"height": _get_selected_value("height"),
		"align": _get_selected_value("align")
	}

func _collect_object_payload(object_type: String) -> Dictionary:
	match object_type:
		"text":
			var text_style: Dictionary = {
				"font_size": int(_get_selected_value("font_size")),
				"color": _get_selected_value("color"),
				"align": _get_selected_value("align")
			}
			return {
				"content": _get_selected_value("content"),
				"style": text_style
			}
		"button":
			var button_style: Dictionary = {
				"color": _get_selected_value("color"),
				"size": _get_selected_value("size"),
				"align": _get_selected_value("align")
			}
			return {
				"content": _get_selected_value("content"),
				"style": button_style
			}
		"image":
			var image_style: Dictionary = {
				"align": _get_selected_value("align")
			}
			return {
				"content": _get_selected_value("content"),
				"style": image_style
			}
		"card":
			var card_style: Dictionary = {
				"width": "15%",
				"align": _get_selected_value("align")
			}
			return {
				"content": "",
				"style": card_style
			}
		_:
			return {
				"content": _get_selected_value("content"),
				"style": {
					"align": _get_selected_value("align")
				}
			}

func _update_create_button_state() -> void:
	create_button.disabled = not _is_form_valid()

func _is_form_valid() -> bool:
	var action: String = _get_selected_action()
	if action.is_empty():
		return false

	match action:
		"create_section":
			return _has_valid_value("assignee") and _has_valid_value("bg_color") and _has_valid_value("height") and _has_valid_value("align")
		"edit_section":
			return _has_valid_value("section_id") and _has_valid_value("assignee") and _has_valid_value("bg_color") and _has_valid_value("height") and _has_valid_value("align")
		"create_object":
			if not _has_valid_value("section_id") or not _has_valid_value("assignee") or not _has_valid_value("object_type"):
				return false
			return _validate_object_fields(_get_selected_value("object_type"))
		"edit_object":
			if not _has_valid_value("section_id") or not _has_valid_value("object_id") or not _has_valid_value("assignee"):
				return false
			return _validate_object_fields(_get_selected_value("object_type"))
		_:
			return false

func _validate_object_fields(object_type: String) -> bool:
	match object_type:
		"text":
			return _has_valid_value("content") and _has_valid_value("font_size") and _has_valid_value("color") and _has_valid_value("align")
		"button":
			return _has_valid_value("content") and _has_valid_value("color") and _has_valid_value("size") and _has_valid_value("align")
		"image":
			return _has_valid_value("content") and _has_valid_value("align")
		"card":
			return _has_valid_value("align")
		_:
			return true

func _get_selected_action() -> String:
	if action_type_select.selected < 0:
		return ""
	return action_type_select.get_item_text(action_type_select.selected)

func _has_valid_value(key: String) -> bool:
	return not _get_selected_value(key).is_empty()

func _get_selected_value(key: String) -> String:
	if not _dynamic_controls.has(key):
		return ""

	var control: Variant = _dynamic_controls[key]
	if control is not OptionButton:
		return ""

	var option: OptionButton = control
	if option.selected < 0:
		return ""

	if key == "section_id" or key == "object_id":
		return String(option.get_item_metadata(option.selected))

	return option.get_item_text(option.selected)

func _generate_task_id() -> int:
	_id_counter += 1
	return int(Time.get_unix_time_from_system()) * 1000 + _id_counter

func _generate_section_id() -> String:
	var section_count: int = _get_sections_array().size()
	if Global:
		section_count = max(section_count, Global.site_sections.size())
	return "section_%d" % (section_count + 1)

func _style_to_css_classes(style: Dictionary) -> Array[String]:
	var classes: Array[String] = []
	for key_variant: Variant in style.keys():
		var key: String = String(key_variant)
		if not CSS_MAP.has(key):
			continue

		var value: String = String(style[key])
		var map_for_key: Dictionary = CSS_MAP[key]
		if map_for_key.has(value):
			classes.append(String(map_for_key[value]))

	return classes

func _get_sections_array() -> Array[Dictionary]:
	var sections_variant: Variant = site_structure.get("sections", [])
	if sections_variant is not Array:
		return []

	var result: Array[Dictionary] = []
	for section_variant: Variant in sections_variant:
		if section_variant is Dictionary:
			result.append(section_variant)
	return result

func _get_section_by_id(section_id: String) -> Dictionary:
	for section: Dictionary in _get_sections_array():
		if String(section.get("id", "")) == section_id:
			return section
	return {}

func _get_objects_in_section(section_id: String) -> Array[Dictionary]:
	if section_id.is_empty():
		return []

	var section: Dictionary = _get_section_by_id(section_id)
	if section.is_empty():
		return []

	var children_variant: Variant = section.get("children", [])
	if children_variant is not Array:
		return []

	var result: Array[Dictionary] = []
	for child_variant: Variant in children_variant:
		if child_variant is Dictionary:
			result.append(child_variant)
	return result

func _get_selected_object(section_id: String) -> Dictionary:
	var object_id: String = _get_selected_value("object_id")
	if object_id.is_empty():
		return {}

	for obj: Dictionary in _get_objects_in_section(section_id):
		if String(obj.get("id", "")) == object_id:
			return obj
	return {}

func _list_images_in_assets() -> Array[String]:
	var images: Array[String] = []
	var dir: DirAccess = DirAccess.open(IMAGES_DIR)
	if dir == null:
		return images

	dir.list_dir_begin()
	while true:
		var file_name: String = dir.get_next()
		if file_name.is_empty():
			break
		if dir.current_is_dir():
			continue

		var extension: String = file_name.get_extension().to_lower()
		if extension in ["png", "jpg", "jpeg", "webp", "svg"]:
			images.append("%s/%s" % [IMAGES_DIR, file_name])
	dir.list_dir_end()

	images.sort()
	return images

func _object_has_property(obj: Object, property_name: String) -> bool:
	for prop_variant: Variant in obj.get_property_list():
		if prop_variant is Dictionary:
			var prop: Dictionary = prop_variant
			if String(prop.get("name", "")) == property_name:
				return true
	return false

func _apply_modal_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG_COLOR
	style.border_color = WINDOW_BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style)

	if has_node("ColorRect"):
		$ColorRect.color = CONTENT_BG_COLOR

	if has_node("VBoxContainer"):
		var root_box: VBoxContainer = $VBoxContainer
		root_box.add_theme_constant_override("separation", 10)

	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 18)

	action_type_select.add_theme_color_override("font_color", Color.WHITE)
	action_type_select.custom_minimum_size = Vector2(0, 36)
	_style_option_button(action_type_select)

	create_button.add_theme_color_override("font_color", Color.WHITE)
	create_button.custom_minimum_size = Vector2(0, 38)
	create_button.add_theme_stylebox_override("normal", _make_button_style(ACCENT_COLOR, 8))
	create_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.26, 0.67, 1.0, 1.0), 8))
	create_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.17, 0.50, 0.85, 1.0), 8))

	cancel_button.add_theme_color_override("font_color", Color.WHITE)
	cancel_button.custom_minimum_size = Vector2(0, 38)
	cancel_button.add_theme_stylebox_override("normal", _make_button_style(CARD_BG_COLOR, 8))
	cancel_button.add_theme_stylebox_override("hover", _make_button_style(CARD_HOVER_BG_COLOR, 8))
	cancel_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.16, 0.20, 1.0), 8))

func _style_option_button(option: OptionButton) -> void:
	option.add_theme_stylebox_override("normal", _make_button_style(Color(0.17, 0.19, 0.23, 1.0), 8))
	option.add_theme_stylebox_override("hover", _make_button_style(Color(0.21, 0.24, 0.29, 1.0), 8))
	option.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.16, 0.20, 1.0), 8))

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
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style
