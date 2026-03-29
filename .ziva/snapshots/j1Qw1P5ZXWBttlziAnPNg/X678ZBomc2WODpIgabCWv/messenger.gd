extends Control
class_name MessengerWindow

const WINDOW_BORDER_COLOR: Color = Color(0.09, 0.09, 0.1, 1.0)
const WINDOW_BORDER_WIDTH: int = 1
const QUICK_REPLIES: Array[String] = [
	"Не реализуемо",
	"Сделано!",
	"Ок",
	"Нет"
]

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_size: Vector2 = Vector2(900, 650)
var original_position: Vector2 = Vector2.ZERO
var is_maximized: bool = false

@onready var panel: Panel = $Panel
@onready var hbox: HBoxContainer = $Panel/HBoxContainer
@onready var content: ColorRect = $ColorRect
@onready var title_label: Label = $Panel/TitleLabel
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
		"Нужен статус по спринту к вечеру.",
		"Покажите демо последней версии.",
		"Какие риски по срокам?"
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
	title_label.text = "Messenger"
	title_label.add_theme_color_override("font_color", Color.WHITE)

	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
	title_style.border_color = WINDOW_BORDER_COLOR
	title_style.border_width_left = 1
	title_style.border_width_top = 1
	title_style.border_width_right = 1
	title_style.border_width_bottom = 1
	panel.add_theme_stylebox_override("panel", title_style)

	content.color = Color(0.12, 0.13, 0.16, 1.0)

	message_input.placeholder_text = "Введите сообщение..."
	message_input.add_theme_color_override("font_color", Color.WHITE)
	message_input.add_theme_color_override("caret_color", Color.WHITE)
	message_input.add_theme_color_override("placeholder_color", Color(0.7, 0.7, 0.7, 1))

	send_button.text = "Отправить"
	send_button.add_theme_color_override("font_color", Color.WHITE)
	quick_send_button.text = "Отправить"
	quick_send_button.add_theme_color_override("font_color", Color.WHITE)

func _setup_signals() -> void:
	$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)
	$Panel/HBoxContainer/MaxButton.pressed.connect(_on_max_button)
	$Panel/HBoxContainer/MinButton.pressed.connect(_on_min_button)
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
		btn.pressed.connect(func() -> void: _load_chat(chat_name))
		chat_list.add_child(btn)

	if chats.size() > 0:
		var first_chat: String = String(chats.keys()[0])
		_load_chat(first_chat)

func _load_chat(chat_name: String) -> void:
	current_chat = chat_name
	chat_title.text = "# " + chat_name
	chat_title.add_theme_color_override("font_color", Color.WHITE)

	for child: Node in messages_vbox.get_children():
		child.queue_free()

	var chat_messages: Array = chats.get(chat_name, [])
	for msg_variant: Variant in chat_messages:
		_add_message_label("Собеседник", String(msg_variant))

	call_deferred("_scroll_messages_to_bottom")

func _add_message_label(sender: String, message: String) -> void:
	var lbl := Label.new()
	lbl.text = "%s: %s" % [sender, message]
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.add_theme_color_override("font_color", Color.WHITE)
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
	call_deferred("_scroll_messages_to_bottom")

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
	var title_height: float = 42.0

	panel.size = Vector2(w, title_height)
	panel.position = Vector2.ZERO
	var hbox_size: Vector2 = hbox.get_combined_minimum_size()
	hbox.position = Vector2(w - hbox_size.x - 10.0, (title_height - hbox_size.y) / 2.0)
	hbox.size = hbox_size

	content.position = Vector2(0.0, title_height)
	content.size = Vector2(w, h - title_height)

	var split: HSplitContainer = $ColorRect/HSplitContainer
	split.size = content.size
	split.position = Vector2.ZERO

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
