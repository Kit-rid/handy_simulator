extends Control

# Переменные для перетаскивания
var is_dragging = false
var drag_offset = Vector2.ZERO
var original_size = Vector2(900, 650)
var original_position = Vector2.ZERO
var is_maximized = false

@onready var panel = $Panel
@onready var title_label = $Panel/TitleLabel
@onready var chat_list = $ColorRect/HSplitContainer/ChatListScroll/ChatListVBox
@onready var chat_title = $ColorRect/HSplitContainer/ChatArea/ChatTitle
@onready var messages_vbox = $ColorRect/HSplitContainer/ChatArea/MessagesScroll/MessagesVBox

# Данные для имитации
var chats = {
	"General": ["Welcome to the team!", "Did everyone see the new Jira task?", "Let's meet at 10."],
	"Project A": ["Alpha version is ready.", "Any updates on the bug fix?", "The client is happy."],
	"HR Support": ["Don't forget to submit your hours.", "New policy update.", "Happy Friday!"],
	"Coffee Break": ["Who wants coffee?", "The machine is broken again...", "I prefer tea."]
}

func _ready():
	original_size = size
	original_position = position
	
	if Global:
		Global.register_window(self)
	
	title_label.text = "Microsoft Teams"
	name = "Teams"
	
	# Кнопки окна
	$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)
	$Panel/HBoxContainer/MaxButton.pressed.connect(_on_max_button)
	$Panel/HBoxContainer/MinButton.pressed.connect(_on_min_button)
	
	panel.gui_input.connect(_on_panel_gui_input)
	
	_setup_messenger_ui()
	_resize_children_to_window()
	move_to_front()

func _exit_tree():
	if Global:
		Global.unregister_window(self)

func _setup_messenger_ui():
	# Очищаем и создаем список чатов
	for child in chat_list.get_children():
		child.queue_free()
	
	for chat_name in chats.keys():
		var btn = Button.new()
		btn.text = chat_name
		btn.custom_minimum_size.y = 40
		btn.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(func(): _load_chat(chat_name))
		chat_list.add_child(btn)
	
	# Загружаем первый чат по умолчанию
	_load_chat(chats.keys()[0])

func _load_chat(chat_name: String):
	chat_title.text = "# " + chat_name
	
	# Очищаем старые сообщения
	for child in messages_vbox.get_children():
		child.queue_free()
	
	# Добавляем новые
	for msg in chats[chat_name]:
		var lbl = Label.new()
		lbl.text = "User: " + msg
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		messages_vbox.add_child(lbl)

func _on_max_button():
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

func _on_min_button():
	visible = false

func _resize_children_to_window():
	var w = size.x
	var h = size.y
	var th = 40.0
	
	panel.size = Vector2(w, th)
	$Panel/HBoxContainer.position = Vector2(w - 100, 5)
	
	$ColorRect.position = Vector2(0, th)
	$ColorRect.size = Vector2(w, h - th)
	
	$ColorRect/HSplitContainer.size = $ColorRect.size

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			is_dragging = false
	if event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		move_to_front()


# Переменные для перетаскивания
var is_dragging = false
var drag_offset = Vector2.ZERO
var original_size = Vector2(900, 650)
var original_position = Vector2.ZERO
var is_maximized = false

@onready var panel = $Panel
@onready var hbox = $Panel/HBoxContainer
@onready var content = $ColorRect
@onready var title_label = $Panel/TitleLabel

@onready var chat_list = $ColorRect/HSplitContainer/ChatListScroll/ChatListVBox
@onready var chat_title = $ColorRect/HSplitContainer/ChatArea/ChatTitle
@onready var messages_vbox = $ColorRect/HSplitContainer/ChatArea/MessagesScroll/MessagesVBox

var chats = {
	"General": ["Welcome to the team!", "Let's start the meeting."],
	"Project A": ["Status update?", "All tasks are done."],
	"HR Support": ["Don't forget to submit your hours.", "Thanks!"],
	"Coffee Break": ["Who wants coffee?", "Me!"]
}

func _ready():
	original_size = size
	original_position = position
	
	if Global:
		Global.register_window(self)
	
	if title_label:
		name = title_label.text
		title_label.text = "Teams Messenger"
	
	$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)
	$Panel/HBoxContainer/MaxButton.pressed.connect(_on_max_button)
	$Panel/HBoxContainer/MinButton.pressed.connect(_on_min_button)
	
	panel.gui_input.connect(_on_panel_gui_input)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_setup_messenger_ui()
	_resize_children_to_window()
	
	move_to_front()

func _exit_tree():
	if Global:
		Global.unregister_window(self)

func _setup_messenger_ui():
	# Очистка и создание кнопок чатов
	for child in chat_list.get_children():
		child.queue_free()
		
	for chat_name in chats.keys():
		var btn = Button.new()
		btn.text = chat_name
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(func(): _select_chat(chat_name))
		chat_list.add_child(btn)
	
	if chats.size() > 0:
		_select_chat(chats.keys()[0])

func _select_chat(chat_name: String):
	chat_title.text = "Chat: " + chat_name
	
	# Очистка старых сообщений
	for child in messages_vbox.get_children():
		child.queue_free()
		
	# Добавление новых сообщений
	for msg in chats[chat_name]:
		var lbl = Label.new()
		lbl.text = msg
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		messages_vbox.add_child(lbl)

func _on_max_button():
	if is_maximized:
		size = original_size
		position = original_position
		is_maximized = false
	else:
		original_size = size
		original_position = position
		var viewport_size = get_viewport_rect().size
		position = Vector2.ZERO
		size = viewport_size
		is_maximized = true
	_resize_children_to_window()

func _on_min_button():
	visible = false

func _resize_children_to_window():
	var w = size.x
	var h = size.y
	var title_height = 40.0
	
	panel.size = Vector2(w, title_height)
	panel.position = Vector2.ZERO
	var hbox_size = hbox.get_combined_minimum_size()
	hbox.position = Vector2(w - hbox_size.x - 10, (title_height - hbox_size.y) / 2)
	hbox.size = hbox_size
	
	content.position = Vector2(0, title_height)
	content.size = Vector2(w, h - title_height)
	
	var split = $ColorRect/HSplitContainer
	split.size = content.size
	split.position = Vector2.ZERO

func _on_panel_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = get_global_mouse_position() - global_position
			move_to_front()
		else:
			is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() - drag_offset

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		move_to_front()
