extends Control

const WINDOW_BORDER_COLOR: Color = Color(0.09, 0.09, 0.1, 1.0)
const WINDOW_BORDER_WIDTH: int = 1
const TITLEBAR_HEIGHT: float = 46.0
const WINDOW_PADDING: float = 14.0

const PANEL_BG_COLOR: Color = Color(0.13, 0.15, 0.18, 1.0)
const CONTENT_BG_COLOR: Color = Color(0.11, 0.12, 0.15, 1.0)
const CARD_BG_COLOR: Color = Color(0.16, 0.18, 0.22, 1.0)
const CARD_HOVER_BG_COLOR: Color = Color(0.19, 0.21, 0.26, 1.0)
const ACCENT_COLOR: Color = Color(0.2, 0.6, 1.0, 1.0)

const QUICK_REPLIES: Array[String] = [
	"Не реализуемо",
	"Сделано!",
	"Ок",
	"Нет"
]

const BOSS_CHAT_NAME: String = "Босс"
const BOSS_QUESTS_MESSAGE: String = "Задача босса:\n1) Черная секция с текстом и кнопкой\n2) Белая секция с кнопкой Купить\n3) Две сущности: текст и кнопка Купить\nОтветь \"Ок\", если берешь в работу."

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_size: Vector2 = Vector2(900, 650)
var original_position: Vector2 = Vector2.ZERO
var is_maximized: bool = false

@onready var panel: Panel = $Panel
@onready var hbox: HBoxContainer = $Panel/HBoxContainer
@onready var content: ColorRect = $ColorRect
@onready var title_label: Label = $Panel/TitleLabel

@onready var min_button: Button = $Panel/HBoxContainer/MinButton
@onready var max_button: Button = $Panel/HBoxContainer/MaxButton
@onready var close_button: Button = $Panel/HBoxContainer/CloseButton

@onready var split: HSplitContainer = $ColorRect/HSplitContainer
@onready var chat_list: VBoxContainer = $ColorRect/HSplitContainer/ChatListScroll/ChatListVBox
@onready var chat_title: Label = $ColorRect/HSplitContainer/ChatArea/ChatTitle
@onready var messages_scroll: ScrollContainer = $ColorRect/HSplitContainer/ChatArea/MessagesScroll
@onready var messages_vbox: VBoxContainer = $ColorRect/HSplitContainer/ChatArea/MessagesScroll/MessagesVBox
@onready var input_mode_select: OptionButton = $ColorRect/HSplitContainer/ChatArea/InputBar/InputModeSelect
@onready var message_input: LineEdit = $ColorRect/HSplitContainer/ChatArea/InputBar/MessageInput
@onready var send_button: Button = $ColorRect/HSplitContainer/ChatArea/InputBar/SendButton
@onready var quick_reply_select: OptionButton = $ColorRect/HSplitContainer/ChatArea/InputBar/QuickReplySelect
@onready var quick_send_button: Button = $ColorRect/HSplitContainer/ChatArea/InputBar/QuickSendButton

var current_chat: String = ""

var chats: Dictionary = {
	"Общий с командой": [
		"Всем привет! Сегодня синк в 11:00.",
		"Проверьте новые задачи в Jira.",
		"Кто берёт задачу по лендингу?"
	],
	"Босс": [
	],
	"Старший аналитик Влад": [
		"Добавил комментарии по требованиям.",
		"Уточни, какой сценарий приоритетный.",
		"Нужна проверка гипотезы до пятницы."
	],
	"Проектный чат": [
		"Обновил roadmap на этот месяц.",
		"Давайте согласуем блок hero.",
		"Есть предложения по структуре каталога?"
	]
}

func _ready() -> void:
	original_size = size
	original_position = position

	if Global:
		Global.register_window(self)

	_inject_boss_quests_message()
	_setup_theme()
	_setup_input_modes()
	_setup_quick_replies()
	_setup_signals()
	_setup_messenger_ui()
	_resize_children_to_window()
	_ensure_window_border()
	move_to_front()

func _exit_tree() -> void:
	if Global:
		Global.unregister_window(self)

func _setup_theme() -> void:
	_apply_window_styles()
	_apply_controls_styles()

func _apply_window_styles() -> void:
	title_label.text = "Messenger"
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_font_size_override("font_size", 18)

	var title_style := StyleBoxFlat.new()
	title_style.bg_color = PANEL_BG_COLOR
	title_style.border_color = WINDOW_BORDER_COLOR
	title_style.border_width_left = 1
	title_style.border_width_top = 1
	title_style.border_width_right = 1
	title_style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", title_style)

	content.color = CONTENT_BG_COLOR
	hbox.add_theme_constant_override("separation", 6)

	_style_title_button(min_button, "—")
	_style_title_button(max_button, "□")
	_style_title_button(close_button, "✕", true)

	min_button.tooltip_text = "Свернуть"
	max_button.tooltip_text = "Развернуть"
	close_button.tooltip_text = "Закрыть"

func _apply_controls_styles() -> void:
	split.split_offset = 240

	chat_title.add_theme_color_override("font_color", Color.WHITE)
	chat_title.add_theme_font_size_override("font_size", 18)

	message_input.placeholder_text = "Введите сообщение..."
	message_input.add_theme_color_override("font_color", Color.WHITE)
	message_input.add_theme_color_override("caret_color", Color.WHITE)
	message_input.add_theme_color_override("placeholder_color", Color(0.62, 0.67, 0.77, 1.0))
	message_input.add_theme_stylebox_override("normal", _make_input_style())
	message_input.add_theme_stylebox_override("focus", _make_input_style(Color(0.28, 0.55, 0.95, 1.0)))

	_style_option_button(input_mode_select)
	_style_option_button(quick_reply_select)

	send_button.text = "Отправить"
	send_button.add_theme_color_override("font_color", Color.WHITE)
	send_button.add_theme_stylebox_override("normal", _make_button_style(ACCENT_COLOR, 8))
	send_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.26, 0.67, 1.0, 1.0), 8))
	send_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.17, 0.50, 0.85, 1.0), 8))

	quick_send_button.text = "Отправить"
	quick_send_button.add_theme_color_override("font_color", Color.WHITE)
	quick_send_button.add_theme_stylebox_override("normal", _make_button_style(ACCENT_COLOR, 8))
	quick_send_button.add_theme_stylebox_override("hover", _make_button_style(Color(0.26, 0.67, 1.0, 1.0), 8))
	quick_send_button.add_theme_stylebox_override("pressed", _make_button_style(Color(0.17, 0.50, 0.85, 1.0), 8))

func _setup_signals() -> void:
	close_button.pressed.connect(queue_free)
	max_button.pressed.connect(_on_max_button)
	min_button.pressed.connect(_on_min_button)
	panel.gui_input.connect(_on_panel_gui_input)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	send_button.pressed.connect(_on_send_message)
	message_input.text_submitted.connect(func(_text: String) -> void: _on_send_message())
	quick_send_button.pressed.connect(_on_send_quick_reply)
	input_mode_select.item_selected.connect(_on_input_mode_selected)

func _setup_input_modes() -> void:
	input_mode_select.clear()
	input_mode_select.add_item("Свой текст")
	input_mode_select.add_item("Быстрый ответ")
	input_mode_select.select(0)
	_apply_input_mode_visibility()

func _setup_quick_replies() -> void:
	quick_reply_select.clear()
	for reply: String in QUICK_REPLIES:
		quick_reply_select.add_item(reply)
	if quick_reply_select.item_count > 0:
		quick_reply_select.select(0)

func _on_input_mode_selected(_index: int) -> void:
	_apply_input_mode_visibility()

func _apply_input_mode_visibility() -> void:
	var manual_mode: bool = input_mode_select.selected == 0
	message_input.visible = manual_mode
	send_button.visible = manual_mode
	quick_reply_select.visible = not manual_mode
	quick_send_button.visible = not manual_mode

func _setup_messenger_ui() -> void:
	for child: Node in chat_list.get_children():
		child.queue_free()

	for chat_name_variant: Variant in chats.keys():
		var chat_name: String = String(chat_name_variant)
		var btn := Button.new()
		btn.text = chat_name
		btn.custom_minimum_size = Vector2(0, 42)
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", _make_button_style(CARD_BG_COLOR, 8))
		btn.add_theme_stylebox_override("hover", _make_button_style(CARD_HOVER_BG_COLOR, 8))
		btn.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.16, 0.20, 1.0), 8))
		btn.pressed.connect(func() -> void: _load_chat(chat_name))
		chat_list.add_child(btn)

	if chats.size() > 0:
		var first_chat: String = String(chats.keys()[0])
		_load_chat(first_chat)

func _load_chat(chat_name: String) -> void:
	current_chat = chat_name
	chat_title.text = "# " + chat_name

	for child: Node in messages_vbox.get_children():
		child.queue_free()

	var chat_messages: Array = chats.get(chat_name, [])
	for msg_variant: Variant in chat_messages:
		_add_message_label("Он", String(msg_variant))

	call_deferred("_scroll_messages_to_bottom")

func _add_message_label(sender: String, message: String) -> void:
	var lbl := Label.new()
	lbl.text = "%s: %s" % [sender, message]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98, 1.0))
	lbl.add_theme_font_size_override("font_size", 14)
	messages_vbox.add_child(lbl)

func _scroll_messages_to_bottom() -> void:
	var scroll_bar := messages_scroll.get_v_scroll_bar()
	if scroll_bar:
		scroll_bar.value = scroll_bar.max_value

func _on_send_message() -> void:
	if current_chat.is_empty():
		return

	var text: String = message_input.text.strip_edges()
	if text.is_empty():
		return

	var messages: Array = chats.get(current_chat, [])
	messages.append(text)
	chats[current_chat] = messages

	_add_message_label("Вы", text)
	_try_accept_boss_quests(text)
	message_input.text = ""
	call_deferred("_scroll_messages_to_bottom")

func _on_send_quick_reply() -> void:
	if current_chat.is_empty():
		return
	if quick_reply_select.item_count <= 0:
		return

	var selected_text: String = quick_reply_select.get_item_text(quick_reply_select.selected)
	if selected_text.is_empty():
		return

	var messages: Array = chats.get(current_chat, [])
	messages.append(selected_text)
	chats[current_chat] = messages

	_add_message_label("Вы", selected_text)
	_try_accept_boss_quests(selected_text)
	call_deferred("_scroll_messages_to_bottom")

func _inject_boss_quests_message() -> void:
	if not chats.has(BOSS_CHAT_NAME):
		return

	var boss_messages: Array = chats.get(BOSS_CHAT_NAME, [])
	for msg_variant: Variant in boss_messages:
		if String(msg_variant).contains("Задания босса"):
			return

	boss_messages.append(BOSS_QUESTS_MESSAGE)
	chats[BOSS_CHAT_NAME] = boss_messages

func _try_accept_boss_quests(sent_text: String) -> void:
	if current_chat != BOSS_CHAT_NAME:
		return
	if not Global:
		return
	if Global.boss_quests_unlocked:
		return

	if sent_text.strip_edges().to_lower() != "ок":
		return

	Global.accept_boss_quests()
	var messages: Array = chats.get(current_chat, [])
	messages.append("Принято. Работай.")
	chats[current_chat] = messages
	_add_message_label("Босс", "Принято. Окно заданий разблокировано.")

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

	panel.size = Vector2(w, TITLEBAR_HEIGHT)
	panel.position = Vector2.ZERO
	var hbox_size: Vector2 = hbox.get_combined_minimum_size()
	hbox.position = Vector2(w - hbox_size.x - 12.0, (TITLEBAR_HEIGHT - hbox_size.y) * 0.5)
	hbox.size = hbox_size

	title_label.position = Vector2(14.0, (TITLEBAR_HEIGHT - title_label.size.y) * 0.5)

	content.position = Vector2(0.0, TITLEBAR_HEIGHT)
	content.size = Vector2(w, h - TITLEBAR_HEIGHT)

	split.position = Vector2(WINDOW_PADDING, WINDOW_PADDING)
	split.size = content.size - Vector2(WINDOW_PADDING * 2.0, WINDOW_PADDING * 2.0)

	_ensure_indicator(w)
	_ensure_window_border()

func _ensure_indicator(width: float) -> void:
	var indicator: ColorRect = get_node_or_null("Indicator")
	if indicator == null:
		indicator = ColorRect.new()
		indicator.name = "Indicator"
		indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(indicator)
	indicator.color = ACCENT_COLOR
	indicator.position = Vector2(0, TITLEBAR_HEIGHT - 1.0)
	indicator.size = Vector2(width, 1.0)
	indicator.move_to_front()

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

func _style_option_button(option: OptionButton) -> void:
	option.add_theme_color_override("font_color", Color.WHITE)
	option.add_theme_stylebox_override("normal", _make_button_style(Color(0.17, 0.19, 0.23, 1.0), 8))
	option.add_theme_stylebox_override("hover", _make_button_style(Color(0.21, 0.24, 0.29, 1.0), 8))
	option.add_theme_stylebox_override("pressed", _make_button_style(Color(0.14, 0.16, 0.20, 1.0), 8))

func _make_input_style(border_color: Color = Color(0.21, 0.25, 0.32, 1.0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.16, 0.20, 1.0)
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style

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
