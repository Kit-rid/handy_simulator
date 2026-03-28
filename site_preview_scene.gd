extends Control

const WINDOW_BORDER_COLOR: Color = Color(0.09, 0.09, 0.1, 1.0)
const WINDOW_BORDER_WIDTH: int = 1

@onready var blocks_container: VBoxContainer = $ScrollContainer/VBoxContainer
const SITE_BLOCK_SCENE: PackedScene = preload("res://SiteBlock.tscn")

func _ready() -> void:
	_build_site()
	_apply_preview_style()
	_ensure_window_border()

	if has_node("Panel/HBoxContainer/CloseButton"):
		$Panel/HBoxContainer/CloseButton.pressed.connect(queue_free)

func _build_site() -> void:
	for child: Node in blocks_container.get_children():
		child.queue_free()

	for task_variant: Variant in Global.site_sections:
		if task_variant is not Dictionary:
			continue
		var task: Dictionary = task_variant
		if String(task.get("type", "")) == "add_section":
			var block: Node = SITE_BLOCK_SCENE.instantiate()
			blocks_container.add_child(block)
			block.setup(
				String(task.get("section", "unknown")),
				String(task.get("layout", "default")),
				task.get("elements", [])
			)

func _apply_preview_style() -> void:
	if has_node("Panel"):
		var panel: Panel = $Panel
		var title_style := StyleBoxFlat.new()
		title_style.bg_color = Color(0.16, 0.18, 0.22, 1.0)
		title_style.border_color = WINDOW_BORDER_COLOR
		title_style.border_width_left = 1
		title_style.border_width_top = 1
		title_style.border_width_right = 1
		title_style.border_width_bottom = 1
		panel.add_theme_stylebox_override("panel", title_style)

	if has_node("ColorRect"):
		$ColorRect.color = Color(0.12, 0.13, 0.16, 1.0)

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
