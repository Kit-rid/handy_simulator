extends PanelContainer
class_name QuestMenu

const CHECK_INTERVAL_SEC: float = 1.5

const QUEST_DEFINITIONS: Array[Dictionary] = [
	{
		"id": "q1",
		"title": "1) Черная секция с текстом и кнопкой"
	},
	{
		"id": "q2",
		"title": "2) Белая секция с кнопкой Купить"
	},
	{
		"id": "q3",
		"title": "3) Две сущности: текст и кнопка Купить"
	}
]

var _active_quests: Array[Dictionary] = []
var _labels_by_id: Dictionary = {}

var _refresh_button: Button
var _timer: Timer
var _is_activated: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(360, 190)
	mouse_filter = Control.MOUSE_FILTER_STOP

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
	_active_quests.shuffle()

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
	for i: int in _active_quests.size():
		var quest: Dictionary = _active_quests[i]
		var quest_id: String = String(quest.get("id", ""))
		var completed: bool = _is_quest_completed(quest_id, html)
		quest["completed"] = completed
		_active_quests[i] = quest
		_update_quest_label(quest)

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

	var sections: Array[Dictionary] = _extract_sections(html)

	match quest_id:
		"q1":
			for section: Dictionary in sections:
				var open_tag: String = String(section.get("open_tag", ""))
				var body: String = String(section.get("body", ""))
				if _is_black_section(open_tag) and _has_text_entity(body) and _has_button_entity(body):
					return true
			return false
		"q2":
			for section: Dictionary in sections:
				var open_tag: String = String(section.get("open_tag", ""))
				var body: String = String(section.get("body", ""))
				if _is_white_section(open_tag) and _has_buy_button(body):
					return true
			return false
		"q3":
			var has_text: bool = _has_text_entity(html)
			var has_buy: bool = _has_buy_button(html)
			return has_text and has_buy
		_:
			return false

func _extract_sections(html: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var regex := RegEx.new()
	var err: int = regex.compile("(?is)(<section\\b[^>]*>)(.*?)</section>")
	if err != OK:
		return result

	for match: RegExMatch in regex.search_all(html):
		result.append({
			"open_tag": match.get_string(1),
			"body": match.get_string(2)
		})

	return result

func _is_black_section(open_tag: String) -> bool:
	var tag: String = open_tag.to_lower()
	return tag.contains("#111827") or tag.contains("bg-dark") or tag.contains("background-color: black")

func _is_white_section(open_tag: String) -> bool:
	var tag: String = open_tag.to_lower()
	return tag.contains("#ffffff") or tag.contains("bg-white") or tag.contains("background-color: white")

func _has_buy_button(input_html: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("(?is)<button\\b[^>]*>\\s*купить\\s*</button>") != OK:
		return false
	return regex.search(input_html) != null

func _has_button_entity(input_html: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("(?is)<button\\b[^>]*>.*?</button>") != OK:
		return false
	return regex.search(input_html) != null

func _has_text_entity(input_html: String) -> bool:
	var regex := RegEx.new()
	if regex.compile("(?is)<(p|h[1-6])\\b[^>]*>\\s*.*?\\s*</(p|h[1-6])>") != OK:
		return false
	return regex.search(input_html) != null
