extends Control
class_name MessengerWindow

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
@onready var message_input: LineEdit = $ColorRect/HSplitContainer/ChatArea/InputBar/MessageInput
@onready var send_button: Button = $ColorRect/HSplitContainer/ChatArea/InputBar/SendButton

var current_chat: String = ""

var chats: Dictionary = {
	"General": ["Welcome to the team!", "Did everyone see the new Jira task?", "Let's meet at 10."],
	"Project A": ["Alpha version is ready.", "Any updates on the bug fix?", "The client is happy."],
	"HR Support": ["Don't forget to submit your hours.", "New policy update.", "Happy Friday!"],
	"Coffee Break": ["Who wants coffee?", "The machine is broken again...", "I prefer tea."]
}

func _ready() -> void:
	original_size = size
	original_position = position

	if Global:
		Global.register_window(self)

	title_label.text = "Messenger"
	title_label.add_theme_color_override("font_color", Color.WHITE)
	panel.modulate = Color(1.0, 1.0, 1.0, 1.0)
	content.color = Color(0.370, 0.370, 0.370, 1.0)

	$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)
	$Panel/HBoxContainer/MaxButton.pressed.connect(_on_max_button)
	$Panel/HBoxContainer/MinButton.pressed.connect(_on_min_button)
	panel.gui_input.connect(_on_panel_gui_input)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	send_button.pressed.connect(_on_send_message)
	message_input.text_submitted.connect(func(_text: String) -> void: _on_send_message())
	message_input.add_theme_color_override("font_color", Color.WHITE)
	message_input.add_theme_color_override("caret_color", Color.WHITE)
	message_input.add_theme_color_override("placeholder_color", Color(0.7, 0.7, 0.7, 1))
	send_button.add_theme_color_override("font_color", Color.WHITE)

	_setup_messenger_ui()
	_resize_children_to_window()
	move_to_front()

func _exit_tree() -> void:
	if Global:
		Global.unregister_window(self)

func _setup_messenger_ui() -> void:
	for child in chat_list.get_children():
		child.queue_free()

	for chat_name in chats.keys():
		var btn := Button.new()
		btn.text = chat_name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.pressed.connect(func(): _load_chat(chat_name))
		chat_list.add_child(btn)

	if chats.size() > 0:
		_load_chat(chats.keys()[0])

func _load_chat(chat_name: String) -> void:
	current_chat = chat_name
	chat_title.text = "# " + chat_name
	chat_title.add_theme_color_override("font_color", Color.WHITE)

	for child in messages_vbox.get_children():
		child.queue_free()

	for msg in chats[chat_name]:
		_add_message_label("User", msg)

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

	var text := message_input.text.strip_edges()
	if text.is_empty():
		return

	if not chats.has(current_chat):
		chats[current_chat] = []

	chats[current_chat].append(text)
	_add_message_label("You", text)
	message_input.text = ""
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
	var w := size.x
	var h := size.y
	var title_height := 40.0

	panel.size = Vector2(w, title_height)
	panel.position = Vector2.ZERO
	var hbox_size := hbox.get_combined_minimum_size()
	hbox.position = Vector2(w - hbox_size.x - 10, (title_height - hbox_size.y) / 2)
	hbox.size = hbox_size

	content.position = Vector2(0, title_height)
	content.size = Vector2(w, h - title_height)

	var split := $ColorRect/HSplitContainer
	split.size = content.size
	split.position = Vector2.ZERO

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
