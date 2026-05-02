extends Control

const GameStateScript := preload("res://scripts/game_state.gd")

const TOP_BAR_HEIGHT := 112
const BOTTOM_BAR_HEIGHT := 110
const RIGHT_PANEL_WIDTH := 300

var game: GameState
var tick_accumulator: float = 0.0
var time_scale: int = 1
var selected_section: String = "Build"
var details_collapsed: bool = false

var color_bg := Color(0.12, 0.13, 0.11)
var color_panel := Color(0.18, 0.17, 0.14)
var color_panel_soft := Color(0.23, 0.22, 0.18)
var color_border := Color(0.38, 0.34, 0.25)
var color_text := Color(0.88, 0.84, 0.74)
var color_muted := Color(0.62, 0.58, 0.49)
var color_accent := Color(0.74, 0.56, 0.28)

var root_margin: MarginContainer
var main_vbox: VBoxContainer
var resource_row: HFlowContainer
var body_row: HBoxContainer
var map_panel: PanelContainer
var map_content: VBoxContainer
var detail_panel: PanelContainer
var detail_content: VBoxContainer
var bottom_nav: HFlowContainer

var time_buttons: Dictionary = {}


func _ready() -> void:
	game = GameStateScript.new()
	add_child(game)
	game.changed.connect(_refresh)

	_build_layout()
	game.load_game()
	_refresh()


func _process(delta: float) -> void:
	if not game.running:
		return

	tick_accumulator += delta
	var tick_interval: float = 2.0 / float(maxi(time_scale, 1))
	if tick_accumulator >= tick_interval:
		tick_accumulator = 0.0
		game.tick_day()


func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = color_bg
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 12)
	root_margin.add_theme_constant_override("margin_top", 10)
	root_margin.add_theme_constant_override("margin_right", 12)
	root_margin.add_theme_constant_override("margin_bottom", 10)
	add_child(root_margin)

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	root_margin.add_child(main_vbox)

	_build_top_resource_bar()
	_build_body()
	_build_bottom_nav()


func _build_top_resource_bar() -> void:
	var top_panel := PanelContainer.new()
	top_panel.custom_minimum_size.y = TOP_BAR_HEIGHT
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(top_panel, color_panel, color_border, 1)
	main_vbox.add_child(top_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	top_panel.add_child(margin)

	resource_row = HFlowContainer.new()
	resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resource_row.add_theme_constant_override("h_separation", 8)
	resource_row.add_theme_constant_override("v_separation", 8)
	margin.add_child(resource_row)


func _build_body() -> void:
	body_row = HBoxContainer.new()
	body_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_row.add_theme_constant_override("separation", 10)
	main_vbox.add_child(body_row)

	map_panel = PanelContainer.new()
	map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(map_panel, Color(0.16, 0.18, 0.15), color_border, 1)
	body_row.add_child(map_panel)

	var map_margin := MarginContainer.new()
	map_margin.add_theme_constant_override("margin_left", 16)
	map_margin.add_theme_constant_override("margin_top", 14)
	map_margin.add_theme_constant_override("margin_right", 16)
	map_margin.add_theme_constant_override("margin_bottom", 14)
	map_panel.add_child(map_margin)

	map_content = VBoxContainer.new()
	map_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_content.add_theme_constant_override("separation", 8)
	map_margin.add_child(map_content)

	detail_panel = PanelContainer.new()
	detail_panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(detail_panel, color_panel, color_border, 1)
	body_row.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 14)
	detail_margin.add_theme_constant_override("margin_top", 14)
	detail_margin.add_theme_constant_override("margin_right", 14)
	detail_margin.add_theme_constant_override("margin_bottom", 14)
	detail_panel.add_child(detail_margin)

	detail_content = VBoxContainer.new()
	detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_content.add_theme_constant_override("separation", 10)
	detail_margin.add_child(detail_content)


func _build_bottom_nav() -> void:
	var bottom_panel := PanelContainer.new()
	bottom_panel.custom_minimum_size.y = BOTTOM_BAR_HEIGHT
	bottom_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(bottom_panel, color_panel, color_border, 1)
	main_vbox.add_child(bottom_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	bottom_panel.add_child(margin)

	bottom_nav = HFlowContainer.new()
	bottom_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_nav.add_theme_constant_override("h_separation", 10)
	bottom_nav.add_theme_constant_override("v_separation", 10)
	margin.add_child(bottom_nav)

	for section in ["Build", "Citizens", "Production", "Storage", "Events", "Management"]:
		var button := _nav_button(section)
		button.pressed.connect(_select_section.bind(section))
		bottom_nav.add_child(button)


func _refresh() -> void:
	_draw_top_bar()
	_draw_map_placeholder()
	_draw_detail_panel()
	_update_nav_buttons()


func _draw_top_bar() -> void:
	_clear(resource_row)

	_add_resource_chip("Wood", str(game.industry_resources.get("Wood", 0)))
	_add_resource_chip("Stone", str(game.industry_resources.get("stone", 0)))
	_add_resource_chip("Food", str(game.total_food()))
	_add_resource_chip("Coal", str(game.industry_resources.get("coal", 0)))
	_add_resource_chip("Population", "%s/%s" % [game.citizens.size(), _citizen_capacity()])
	_add_resource_chip("Free Workers", str(game.free_citizens()))

	_add_date_chip()
	_add_time_controls()


func _draw_map_placeholder() -> void:
	_clear(map_content)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_content.add_child(header)

	var title := _label("Settlement View", 20, color_text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var mode := _label(selected_section, 14, color_muted)
	mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(mode)

	var play_area := PanelContainer.new()
	play_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(play_area, Color(0.13, 0.16, 0.13), Color(0.27, 0.30, 0.23), 1)
	map_content.add_child(play_area)

	var play_margin := MarginContainer.new()
	play_margin.add_theme_constant_override("margin_left", 18)
	play_margin.add_theme_constant_override("margin_top", 18)
	play_margin.add_theme_constant_override("margin_right", 18)
	play_margin.add_theme_constant_override("margin_bottom", 18)
	play_area.add_child(play_margin)

	var placeholder := VBoxContainer.new()
	placeholder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	placeholder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	placeholder.alignment = BoxContainer.ALIGNMENT_CENTER
	placeholder.add_theme_constant_override("separation", 8)
	play_margin.add_child(placeholder)

	var label := _label("Main Settlement / Map Area", 22, color_text)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(label)

	var sublabel := _label("Reserved for buildings, terrain, roads, selection, and overlays.", 14, color_muted)
	sublabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.add_child(sublabel)


func _draw_detail_panel() -> void:
	_clear(detail_content)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(header)

	var title := _label("Selected Object", 18, color_text)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var collapse := Button.new()
	collapse.text = "<" if details_collapsed else ">"
	collapse.custom_minimum_size = Vector2(36, 32)
	collapse.pressed.connect(_toggle_details)
	_style_button(collapse, false)
	header.add_child(collapse)

	if details_collapsed:
		detail_panel.custom_minimum_size.x = 62
		return

	detail_panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH

	_add_detail_row("Status", "Idle")
	_add_detail_row("Workers", "0 / 0")
	_add_detail_row("Output", "None")

	var upgrade := Button.new()
	upgrade.text = "Upgrade"
	upgrade.custom_minimum_size.y = 40
	upgrade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_button(upgrade, false)
	detail_content.add_child(upgrade)

	var separator := HSeparator.new()
	detail_content.add_child(separator)

	var description_title := _label("Description", 14, color_accent)
	detail_content.add_child(description_title)

	var description := _label("Select a building, citizen, storage, or event to show contextual details here.", 13, color_muted)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(description)

	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_content.add_child(filler)


func _add_resource_chip(title: String, value: String) -> void:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(104, 38)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(chip, color_panel_soft, Color(0.30, 0.27, 0.20), 1)
	resource_row.add_child(chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 5)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)

	box.add_child(_label(title, 11, color_muted))
	box.add_child(_label(value, 16, color_text))


func _add_date_chip() -> void:
	var date_chip := PanelContainer.new()
	date_chip.custom_minimum_size = Vector2(166, 38)
	_style_panel(date_chip, color_panel_soft, Color(0.30, 0.27, 0.20), 1)
	resource_row.add_child(date_chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 5)
	date_chip.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	margin.add_child(box)
	box.add_child(_label("Date", 11, color_muted))
	box.add_child(_label("Day %s / Month %s / Year %s" % [game.day, game.month, game.year], 14, color_text))


func _add_time_controls() -> void:
	time_buttons.clear()
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 4)
	resource_row.add_child(group)

	var pause := _time_button("Pause")
	pause.pressed.connect(_toggle_pause)
	group.add_child(pause)
	time_buttons["Pause"] = pause

	for speed in [1, 2, 3]:
		var button := _time_button("%sx" % speed)
		button.pressed.connect(_set_time_scale.bind(speed))
		group.add_child(button)
		time_buttons[speed] = button

	_update_time_buttons()


func _add_detail_row(title: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(row)

	var left := _label(title, 13, color_muted)
	left.custom_minimum_size.x = 86
	row.add_child(left)

	var right := _label(value, 13, color_text)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)


func _select_section(section: String) -> void:
	selected_section = section
	_refresh()


func _toggle_details() -> void:
	details_collapsed = not details_collapsed
	_draw_detail_panel()


func _toggle_pause() -> void:
	game.set_running(not game.running)
	_update_time_buttons()


func _set_time_scale(speed: int) -> void:
	time_scale = speed
	game.set_running(true)
	_update_time_buttons()


func _update_time_buttons() -> void:
	if not time_buttons.has("Pause"):
		return

	_style_button(time_buttons["Pause"], not game.running)
	for speed in [1, 2, 3]:
		if time_buttons.has(speed):
			_style_button(time_buttons[speed], game.running and time_scale == speed)


func _update_nav_buttons() -> void:
	for child in bottom_nav.get_children():
		var button := child as Button
		if button == null:
			continue
		_style_button(button, button.text == selected_section)


func _nav_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(126, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_button(button, text == selected_section)
	return button


func _time_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(54, 38)
	_style_button(button, false)
	return button


func _style_button(button: Button, active: bool) -> void:
	button.add_theme_color_override("font_color", color_text if active else color_muted)
	button.add_theme_color_override("font_hover_color", color_text)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_stylebox_override("normal", _button_style(active))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.32, 0.26, 0.16) if active else Color(0.16, 0.15, 0.13)
	style.border_color = color_accent if active else Color(0.30, 0.27, 0.20)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _style_panel(panel: PanelContainer, fill: Color, border: Color, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _citizen_capacity() -> int:
	for service in game.town_services:
		if service.name == "HOUSE":
			return int(service.quantity) * int(service.capacity)
	return game.citizens.size()


func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
