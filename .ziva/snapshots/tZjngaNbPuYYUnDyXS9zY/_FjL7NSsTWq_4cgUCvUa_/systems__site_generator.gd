extends RefCounted
class_name SiteGenerator

const GENERATED_DIR: String = "user://generated_site"
const INDEX_FILE_PATH: String = GENERATED_DIR + "/index.html"
const CSS_FILE_PATH: String = GENERATED_DIR + "/style.css"

const TEMPLATES_ROOT: String = "res://templates"
const BASE_TEMPLATE_PATH: String = TEMPLATES_ROOT + "/base.html"
const SECTION_TEMPLATES_ROOT: String = TEMPLATES_ROOT + "/sections"

func generate_from_tasks(tasks: Array) -> void:
	print("[SiteGenerator] Start generation from tasks...")
	var site_structure: Array = build_site_structure(tasks)
	var html: String = generate_html(site_structure)
	var css: String = generate_css(site_structure)
	save_site(html, css)
	print("[SiteGenerator] Generation completed.")

func build_site_structure(tasks: Array) -> Array:
	var site: Array = []

	for task_variant: Variant in tasks:
		if task_variant is not Dictionary:
			continue

		var task: Dictionary = task_variant
		if String(task.get("type", "")) != "add_section":
			continue

		var elements: Array = []
		var raw_elements: Variant = task.get("elements", [])
		if raw_elements is Array:
			elements = (raw_elements as Array).duplicate()

		var section_data: Dictionary = {
			"type": String(task.get("section", "section")),
			"layout": String(task.get("layout", "text_block")),
			"elements": elements,
			"style": task.get("style", {})
		}
		site.append(section_data)

	print("[SiteGenerator] Site structure built. Sections: ", site.size())
	return site

func generate_html(site_structure: Array) -> String:
	var sections_markup: Array[String] = []

	for section_variant: Variant in site_structure:
		if section_variant is not Dictionary:
			continue

		var section_data: Dictionary = section_variant
		var section_template_path: String = _get_section_template_path(section_data)
		var section_template: String = _load_text_file(section_template_path, "")

		if section_template.is_empty():
			print("[SiteGenerator] Template missing, using fallback for: ", section_template_path)
			section_template = _fallback_section_template()

		var rendered_section: String = _render_section_template(section_template, section_data)
		sections_markup.append(rendered_section)

	var content_html: String = "\n".join(sections_markup)
	var base_template: String = _load_text_file(BASE_TEMPLATE_PATH, _default_base_template())
	return base_template.replace("{{CONTENT}}", content_html)

func generate_css(site_structure: Array) -> String:
	var css_blocks: Array[String] = []

	css_blocks.append("""
* { box-sizing: border-box; }
body {
	margin: 0;
	font-family: Arial, sans-serif;
	background: #f7f7f9;
	color: #1f2937;
	line-height: 1.5;
}
.section {
	padding: 48px 24px;
	border-bottom: 1px solid #e5e7eb;
}
.container {
	max-width: 1000px;
	margin: 0 auto;
}
h1, h2, h3 { margin: 0 0 16px; }
p { margin: 0 0 12px; }
button {
	border: none;
	background: #2563eb;
	color: white;
	padding: 10px 16px;
	border-radius: 8px;
	cursor: pointer;
}
button:hover { background: #1d4ed8; }
""")

	var layouts: Dictionary = {}
	for section_variant: Variant in site_structure:
		if section_variant is Dictionary:
			var layout_name: String = String((section_variant as Dictionary).get("layout", ""))
			layouts[layout_name] = true

	if layouts.has("cards"):
		css_blocks.append("""
.catalog.cards .cards-grid {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
	gap: 16px;
}
.card {
	background: white;
	border: 1px solid #e5e7eb;
	border-radius: 12px;
	padding: 16px;
	box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}
.card .price {
	font-weight: 700;
	color: #059669;
}
""")

	if layouts.has("table"):
		css_blocks.append("""
.catalog.table table {
	width: 100%;
	border-collapse: collapse;
	background: white;
}
.catalog.table th,
.catalog.table td {
	border: 1px solid #e5e7eb;
	padding: 12px;
	text-align: left;
}
.catalog.table th {
	background: #f3f4f6;
}
""")

	if layouts.has("title_button"):
		css_blocks.append("""
.hero.title_button {
	background: linear-gradient(135deg, #0ea5e9, #2563eb);
	color: white;
}
.hero.title_button button {
	background: white;
	color: #1d4ed8;
	font-weight: 700;
}
""")

	return "\n\n".join(css_blocks)

func save_site(html: String, css: String) -> void:
	var user_dir: DirAccess = DirAccess.open("user://")
	if user_dir == null:
		push_error("[SiteGenerator] Cannot open user://")
		return

	var dir_err: int = user_dir.make_dir_recursive("generated_site")
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		push_error("[SiteGenerator] Cannot create user://generated_site, code: %s" % dir_err)
		return

	_write_text_file(INDEX_FILE_PATH, html)
	_write_text_file(CSS_FILE_PATH, css)

	print("[SiteGenerator] Saved files:")
	print("  - ", ProjectSettings.globalize_path(INDEX_FILE_PATH))
	print("  - ", ProjectSettings.globalize_path(CSS_FILE_PATH))

func open_in_browser() -> void:
	var absolute_index_path: String = ProjectSettings.globalize_path(INDEX_FILE_PATH).replace("\\", "/")
	var url: String = "file://" + absolute_index_path
	print("[SiteGenerator] Opening in browser: ", url)
	OS.shell_open(url)

func get_generated_index_path() -> String:
	return ProjectSettings.globalize_path(INDEX_FILE_PATH)

func _get_section_template_path(section_data: Dictionary) -> String:
	var section_type: String = String(section_data.get("type", "section"))
	var layout: String = String(section_data.get("layout", "text_block"))
	var file_name: String = "%s_%s.html" % [section_type, layout]
	return SECTION_TEMPLATES_ROOT + "/" + file_name

func _render_section_template(template: String, section_data: Dictionary) -> String:
	var section_type: String = String(section_data.get("type", "section"))
	var layout: String = String(section_data.get("layout", "text_block"))
	var rendered: String = template

	rendered = rendered.replace("{{SECTION_TYPE}}", section_type)
	rendered = rendered.replace("{{LAYOUT}}", layout)
	rendered = rendered.replace("{{SECTION_CLASS}}", "%s %s" % [section_type, layout])
	rendered = rendered.replace("{{SECTION_STYLE}}", _section_style_to_inline_css(section_data))
	rendered = rendered.replace("{{TITLE}}", "%s section" % section_type.capitalize())
	rendered = rendered.replace("{{BUTTON_TEXT}}", "Learn more")
	rendered = rendered.replace("{{CONTENT}}", _build_content_markup(section_data))

	return rendered

func _build_content_markup(section_data: Dictionary) -> String:
	var parts: Array[String] = []
	var elements_variant: Variant = section_data.get("elements", [])
	var elements: Array = []
	if elements_variant is Array:
		elements = elements_variant

	for element_variant: Variant in elements:
		var element: String = String(element_variant)
		match element:
			"title":
				parts.append("<h2>Generated Title</h2>")
			"text":
				parts.append("<p>Generated paragraph from task elements.</p>")
			"button":
				parts.append("<button>Купить</button>")
			"image":
				parts.append("<img src=\"https://via.placeholder.com/640x280\" alt=\"Generated image\">")
			"product_card":
				parts.append(_build_catalog_cards())
			"price":
				parts.append("<p class=\"price\">$99</p>")
			_:
				parts.append("<span class=\"element\">%s</span>" % element)

	if parts.is_empty():
		parts.append("<p>Empty section (no elements specified).</p>")

	return "\n".join(parts)

func _build_catalog_cards() -> String:
	return """
<div class="cards-grid">
	<article class="card">
		<h3>Product A</h3>
		<p class="price">$29</p>
		<button>Buy</button>
	</article>
	<article class="card">
		<h3>Product B</h3>
		<p class="price">$49</p>
		<button>Buy</button>
	</article>
	<article class="card">
		<h3>Product C</h3>
		<p class="price">$79</p>
		<button>Buy</button>
	</article>
</div>
"""

func _section_style_to_inline_css(section_data: Dictionary) -> String:
	var style_variant: Variant = section_data.get("style", {})
	if style_variant is not Dictionary:
		return ""

	var style: Dictionary = style_variant
	var inline_rules: Array[String] = []

	var bg_color_key: String = String(style.get("bg_color", "")).to_lower()
	match bg_color_key:
		"white":
			inline_rules.append("background-color: #ffffff")
		"blue":
			inline_rules.append("background-color: #dbeafe")
		"gray":
			inline_rules.append("background-color: #f3f4f6")
		"dark":
			inline_rules.append("background-color: #111827")
			inline_rules.append("color: #f9fafb")
		_:
			pass

	var align_key: String = String(style.get("align", "")).to_lower()
	if align_key in ["left", "center", "right"]:
		inline_rules.append("text-align: %s" % align_key)

	var height_key: String = String(style.get("height", ""))
	match height_key:
		"50%":
			inline_rules.append("min-height: 50vh")
		"75%":
			inline_rules.append("min-height: 75vh")
		"100%":
			inline_rules.append("min-height: 100vh")
		_:
			pass

	return "; ".join(inline_rules)

func _load_text_file(path: String, fallback: String = "") -> String:
	if not FileAccess.file_exists(path):
		return fallback
	return FileAccess.get_file_as_string(path)

func _write_text_file(path: String, content: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[SiteGenerator] Cannot write file: %s" % path)
		return
	file.store_string(content)
	file.close()

func _fallback_section_template() -> String:
	return """
<section class="section {{SECTION_CLASS}}" style="{{SECTION_STYLE}}">
	<div class="container">
		<h2>{{TITLE}}</h2>
		{{CONTENT}}
	</div>
</section>
"""

func _default_base_template() -> String:
	return """
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>Generated Site</title>
	<link rel="stylesheet" href="style.css">
</head>
<body>
{{CONTENT}}
</body>
</html>
"""
