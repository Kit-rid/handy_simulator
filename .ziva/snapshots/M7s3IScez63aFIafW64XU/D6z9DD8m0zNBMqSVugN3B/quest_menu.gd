extends PanelContainer
class_name QuestMenu

const CHECK_INTERVAL_SEC: float = 1.5

const QUEST_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "q1",
		"title": "1) Создать blue секцию"
	},
	{
		"id": "q2",
		"title": "2) Добавить в blue секцию текст от босса"
	},
	{
		"id": "q3",
		"title": "3) Добавить в blue секцию кнопку Купить"
	}
]

const REQUIRED_BOSS_TEXT: String = "Добро пожаловать на наш сайт, свяжитесь с нами по данным номерам или пишите на почту. Ном. +79253334442, gmail@gmail.com"

var _active_quests: Array[Dictionary] = []
var _labels_by_id: Dictionary = {}

var _refresh_button: Button
var _timer: Timer
var _is_activated: bool = false

var _section_regex: RegEx = RegEx.new()
var _buy_button_regex: RegEx = RegEx.new()
var _last_html_hash: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(360, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_compile_regexes()

	_build_ui()

	if Global:
		Global.boss_quests_accepted.connect(_on_boss_quests_accepted)
		if Global.boss_quests_unlocked:
			_activate_quests()
		else:
			visible = false
	else:
		_activate_quests()

func _on_boss_quests_accepted() -> void:
	_activate_quests()

func _compile_regexes() -> void:
	_section_regex.compile("(?is)(<section\\b[^>]*>)(.*?)</section>")
	_buy_button_regex.compile("(?is)<button\\b[^>]*>\\s*купить\\s*</button>")

func _activate_quests() -> void:
	if _is_activated:
		return
	_is_activated = true
	visible = true
	_init_random_quests()
	_start_auto_check_timer()
	_update_quests_state()

func _build_ui() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.09, 0.12, 0.95)
	panel_style.border_color = Color(0.2, 0.6, 1.0, 1.0)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", panel_style)

	var root := VBoxContainer.new()
	root.name = "Root"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 10
	root.offset_top = 10
	root.offset_right = -10
	root.offset_bottom = -10

	var title := Label.new()
	title.text = "Задания босса"
	title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0, 1.0))
	title.add_theme_font_size_override("font_size", 17)
	root.add_child(title)

	var hint := Label.new()
	hint.text = "Статус считается только по HTML"
	hint.add_theme_color_override("font_color", Color(0.70, 0.77, 0.90, 1.0))
	hint.add_theme_font_size_override("font_size", 12)
	root.add_child(hint)

	var quests_box := VBoxContainer.new()
	quests_box.name = "QuestsBox"
	quests_box.add_theme_constant_override("separation", 6)
	quests_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(quests_box)

	_refresh_button = Button.new()
	_refresh_button.text = "Проверить выполнение"
	_refresh_button.custom_minimum_size = Vector2(0, 34)
	_refresh_button.add_theme_color_override("font_color", Color.WHITE)
	_refresh_button.pressed.connect(_update_quests_state)
	root.add_child(_refresh_button)

func _init_random_quests() -> void:
	_active_quests = QUEST_DEFINITIONS.duplicate(true)

	var quests_box: VBoxContainer = get_node("Root/QuestsBox")
	for child: Node in quests_box.get_children():
		child.queue_free()
	_labels_by_id.clear()

	for quest: Dictionary in _active_quests:
		var quest_id: String = String(quest.get("id", ""))
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		row.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
		quests_box.add_child(row)
		_labels_by_id[quest_id] = row

func _start_auto_check_timer() -> void:
	_timer = Timer.new()
	_timer.wait_time = CHECK_INTERVAL_SEC
	_timer.autostart = true
	_timer.one_shot = false
	_timer.timeout.connect(_update_quests_state)
	add_child(_timer)

func _update_quests_state() -> void:
	var html: String = _read_generated_html()
	var html_hash: int = html.hash()
	if html_hash == _last_html_hash and not html.is_empty():
		return
	_last_html_hash = html_hash

	var can_check_next: bool = true
	for i: int in _active_quests.size():
		var quest: Dictionary = _active_quests[i]
		var quest_id: String = String(quest.get("id", ""))
		var completed: bool = false
		if can_check_next:
			completed = _is_quest_completed(quest_id, html)
		quest["completed"] = completed
		_active_quests[i] = quest
		_update_quest_label(quest)
		can_check_next = can_check_next and completed

func _update_quest_label(quest: Dictionary) -> void:
	var quest_id: String = String(quest.get("id", ""))
	if not _labels_by_id.has(quest_id):
		return

	var label: Label = _labels_by_id[quest_id]
	var completed: bool = bool(quest.get("completed", false))
	var mark: String = "✅" if completed else "⬜"
	label.text = "%s %s" % [mark, String(quest.get("title", ""))]

func _read_generated_html() -> String:
	var generator := SiteGenerator.new()
	var html_path: String = generator.get_generated_index_path()
	if not FileAccess.file_exists(html_path):
		return ""
	return FileAccess.get_file_as_string(html_path)

func _is_quest_completed(quest_id: String, html: String) -> bool:
	if html.is_empty():
		return false

	var blue_sections: Array[String] = _extract_blue_section_bodies(html)

	match quest_id:
		"q1":
			return not blue_sections.is_empty()
		"q2":
			for body: String in blue_sections:
				if _has_required_boss_text(body):
					return true
			return false
		"q3":
			for body: String in blue_sections:
				if _has_required_boss_text(body) and _has_buy_button(body):
					return true
			return false
		_:
			return false

func _extract_sections(html: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for match: RegExMatch in _section_regex.search_all(html):
		result.append({
			"open_tag": match.get_string(1),
			"body": match.get_string(2)
		})

	return result

func _extract_blue_section_bodies(html: String) -> Array[String]:
	var result: Array[String] = []
	for section: Dictionary in _extract_sections(html):
		var open_tag: String = String(section.get("open_tag", ""))
		if _is_blue_section(open_tag):
			result.append(String(section.get("body", "")))
	return result

func _is_blue_section(open_tag: String) -> bool:
	var tag: String = open_tag.to_lower()
	return tag.contains("#dbeafe") or tag.contains("bg-blue") or tag.contains("background-color: blue")

func _has_buy_button(input_html: String) -> bool:
	return _buy_button_regex.search(input_html) != null

func _has_required_boss_text(input_html: String) -> bool:
	var normalized_html: String = _normalize_text(input_html)
	var normalized_required: String = _normalize_text(REQUIRED_BOSS_TEXT)
	return normalized_html.contains(normalized_required)

func _normalize_text(input_text: String) -> String:
	var lowered: String = input_text.to_lower()
	var single_line: String = lowered.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	return " ".join(single_line.split(" ", false))
