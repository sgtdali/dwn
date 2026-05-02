@tool
extends Control

const GameStateScript := preload("res://scripts/game_state.gd")
const BuildCatalogScript := preload("res://scripts/ui/build_catalog.gd")
const BuildPlacementStateScript := preload("res://scripts/ui/build_placement_state.gd")
const PlacedBuildingPresenterScript := preload("res://scripts/ui/placed_building_presenter.gd")
const WorkforcePresenterScript := preload("res://scripts/ui/workforce_presenter.gd")
const CitizenPresenterScript := preload("res://scripts/ui/citizen_presenter.gd")
const ProductionPresenterScript := preload("res://scripts/ui/production_presenter.gd")
const StoragePresenterScript := preload("res://scripts/ui/storage_presenter.gd")
const EventsPresenterScript := preload("res://scripts/ui/events_presenter.gd")
const ManagementPresenterScript := preload("res://scripts/ui/management_presenter.gd")

const TopStatChipScene := preload("res://scenes/ui/components/TopStatChip.tscn")
const BoardBuildingTileScene := preload("res://scenes/ui/components/BoardBuildingTile.tscn")
const SidebarSectionScene := preload("res://scenes/ui/components/SidebarSection.tscn")
const SidebarStatCardScene := preload("res://scenes/ui/components/SidebarStatCard.tscn")
const BuildEntryCardScene := preload("res://scenes/ui/components/BuildEntryCard.tscn")

const UI_PANEL_OUTER := preload("res://local_ui_assets/ui_panel_outer_9slice.png")
const UI_PANEL_INNER := preload("res://local_ui_assets/ui_panel_inner_9slice.png")
const UI_BUTTON_PRIMARY := preload("res://local_ui_assets/ui_button_primary_9slice.png")
const UI_BUTTON_SECONDARY := preload("res://local_ui_assets/ui_button_secondary_9slice.png")
const UI_TAB_ACTIVE := preload("res://local_ui_assets/ui_tab_active_9slice.png")
const UI_TAB_INACTIVE := preload("res://local_ui_assets/ui_tab_inactive_9slice.png")
const UI_CHIP := preload("res://local_ui_assets/ui_chip_9slice.png")
const UI_WARNING_CHIP := preload("res://local_ui_assets/ui_warning_chip_9slice.png")

const UI_PANEL_OUTER_REGION := Rect2(48, 68, 1420, 856)
const UI_BUTTON_PRIMARY_REGION := Rect2(108, 292, 1316, 404)

const TOP_BAR_HEIGHT := 112
const BOTTOM_BAR_HEIGHT := 122
const RIGHT_PANEL_WIDTH := 300
const PLACEMENT_GRID_COLUMNS := 8
const PLACEMENT_GRID_ROWS := 5
const GENERATED_UI_ROOT := "__GeneratedMainUIPreview"

var game: GameState
var tick_accumulator: float = 0.0
var time_scale: int = 1
var selected_section: String = "Build"
var selected_build_id: String = ""
var selected_placed_cell := Vector2i(-1, -1)
var details_collapsed: bool = false
var placement_state: BuildPlacementState
var selected_citizen_id: int = -1
var citizens_filter: String = "All"
var selected_production_id: String = ""
var production_filter: String = "All"
var selected_resource_id: String = ""
var storage_filter: String = "All"

var color_bg := Color(0.07, 0.06, 0.05)
var color_panel := Color(0.11, 0.10, 0.07)
var color_panel_soft := Color(0.17, 0.15, 0.10)
var color_border := Color(0.40, 0.31, 0.14)
var color_text := Color(0.92, 0.88, 0.76)
var color_muted := Color(0.46, 0.42, 0.32)
var color_accent := Color(0.76, 0.58, 0.22)

var root_margin: MarginContainer
var main_vbox: VBoxContainer
var resource_row: HBoxContainer
var body_row: HBoxContainer
var map_panel: PanelContainer
var map_content: VBoxContainer
var detail_panel: PanelContainer
var detail_content: VBoxContainer
var bottom_nav: HFlowContainer
var generated_ui_root: Control

var time_buttons: Dictionary = {}


func _ready() -> void:
	if Engine.is_editor_hint():
		_build_editor_preview()
		return

	game = GameStateScript.new()
	add_child(game)
	game.changed.connect(_refresh)
	placement_state = BuildPlacementStateScript.new()

	_build_layout()
	game.load_game()
	_refresh()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not game.running:
		return

	tick_accumulator += delta
	var tick_interval: float = 2.0 / float(maxi(time_scale, 1))
	if tick_accumulator >= tick_interval:
		tick_accumulator = 0.0
		game.tick_day()


func _build_editor_preview() -> void:
	custom_minimum_size = Vector2(1280, 720)
	size = Vector2(1280, 720)
	game = GameStateScript.new()
	placement_state = BuildPlacementStateScript.new()
	selected_section = "Build"
	selected_build_id = ""
	selected_placed_cell = Vector2i(-1, -1)
	details_collapsed = false

	_build_layout()
	_refresh()


func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if has_node("RootMargin"):
		_bind_scene_layout()
		return

	_clear_generated_ui_root()

	generated_ui_root = Control.new()
	generated_ui_root.name = GENERATED_UI_ROOT
	generated_ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	generated_ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(generated_ui_root)

	var background := ColorRect.new()
	background.color = color_bg
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	generated_ui_root.add_child(background)

	root_margin = MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 12)
	root_margin.add_theme_constant_override("margin_top", 10)
	root_margin.add_theme_constant_override("margin_right", 12)
	root_margin.add_theme_constant_override("margin_bottom", 10)
	generated_ui_root.add_child(root_margin)

	main_vbox = VBoxContainer.new()
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_theme_constant_override("separation", 10)
	root_margin.add_child(main_vbox)

	_build_top_resource_bar()
	_build_body()
	_build_bottom_nav()


func _bind_scene_layout() -> void:
	var apply_defaults := not Engine.is_editor_hint()

	var background := get_node_or_null("Background") as ColorRect
	if background != null and apply_defaults:
		background.color = color_bg
		background.set_anchors_preset(Control.PRESET_FULL_RECT)

	root_margin = get_node("RootMargin") as MarginContainer
	if apply_defaults:
		root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		root_margin.add_theme_constant_override("margin_left", 12)
		root_margin.add_theme_constant_override("margin_top", 10)
		root_margin.add_theme_constant_override("margin_right", 12)
		root_margin.add_theme_constant_override("margin_bottom", 10)

	main_vbox = get_node("RootMargin/MainVBox") as VBoxContainer
	if apply_defaults:
		main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		main_vbox.add_theme_constant_override("separation", 10)

	var top_panel := get_node("RootMargin/MainVBox/TopPanel") as PanelContainer
	if apply_defaults:
		top_panel.custom_minimum_size.y = TOP_BAR_HEIGHT
		top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_panel(top_panel, color_panel, color_border, 2, "outer")

	resource_row = get_node("RootMargin/MainVBox/TopPanel/TopMargin/ResourceRow") as HBoxContainer
	if apply_defaults:
		resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		resource_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		resource_row.add_theme_constant_override("separation", 10)

	body_row = get_node("RootMargin/MainVBox/BodyRow") as HBoxContainer
	if apply_defaults:
		body_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		body_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		body_row.add_theme_constant_override("separation", 10)

	map_panel = get_node("RootMargin/MainVBox/BodyRow/MapPanel") as PanelContainer
	if apply_defaults:
		map_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		map_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_style_panel(map_panel, Color(0.08, 0.07, 0.05), color_border, 2, "outer")

	map_content = get_node("RootMargin/MainVBox/BodyRow/MapPanel/MapMargin/MapContent") as VBoxContainer
	if apply_defaults:
		map_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		map_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		map_content.add_theme_constant_override("separation", 8)

	detail_panel = get_node("RootMargin/MainVBox/BodyRow/DetailPanel") as PanelContainer
	if apply_defaults:
		detail_panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH
		detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_style_panel(detail_panel, Color(0.10, 0.09, 0.07), color_border, 2, "outer")

	detail_content = get_node("RootMargin/MainVBox/BodyRow/DetailPanel/DetailMargin/DetailContent") as VBoxContainer
	if apply_defaults:
		detail_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		detail_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_content.add_theme_constant_override("separation", 10)

	var bottom_panel := get_node("RootMargin/MainVBox/BottomPanel") as PanelContainer
	if apply_defaults:
		bottom_panel.custom_minimum_size.y = BOTTOM_BAR_HEIGHT
		bottom_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_panel(bottom_panel, Color(0.07, 0.06, 0.04), color_border, 2, "outer")

	bottom_nav = get_node("RootMargin/MainVBox/BottomPanel/BottomMargin/BottomNav") as HFlowContainer
	if apply_defaults:
		bottom_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
		bottom_nav.add_theme_constant_override("h_separation", 10)
		bottom_nav.add_theme_constant_override("v_separation", 10)
	_bind_bottom_nav_buttons()


func _clear_generated_ui_root() -> void:
	var existing := get_node_or_null(GENERATED_UI_ROOT)
	if existing == null:
		return
	remove_child(existing)
	existing.queue_free()


func _bind_bottom_nav_buttons() -> void:
	var sections := ["Build", "Citizens", "Production", "Storage", "Events", "Management"]
	if bottom_nav.get_child_count() == 0:
		for section in sections:
			var button := _nav_button(section)
			bottom_nav.add_child(button)
	else:
		for section in sections:
			var button := bottom_nav.get_node_or_null(section + "Button") as Button
			if button != null:
				_setup_nav_button(button, section)


func _build_top_resource_bar() -> void:
	var top_panel := PanelContainer.new()
	top_panel.custom_minimum_size.y = TOP_BAR_HEIGHT
	top_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(top_panel, color_panel, color_border, 2, "outer")
	main_vbox.add_child(top_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	top_panel.add_child(margin)

	resource_row = HBoxContainer.new()
	resource_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	resource_row.add_theme_constant_override("separation", 10)
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
	_style_panel(map_panel, Color(0.08, 0.07, 0.05), color_border, 2, "outer")
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
	_style_panel(detail_panel, Color(0.10, 0.09, 0.07), color_border, 2, "outer")
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
	_style_panel(bottom_panel, Color(0.07, 0.06, 0.04), color_border, 2, "outer")
	main_vbox.add_child(bottom_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	bottom_panel.add_child(margin)

	bottom_nav = HFlowContainer.new()
	bottom_nav.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_nav.add_theme_constant_override("h_separation", 10)
	bottom_nav.add_theme_constant_override("v_separation", 10)
	margin.add_child(bottom_nav)

	for section in ["Build", "Citizens", "Production", "Storage", "Events", "Management"]:
		var button := _nav_button(section)
		bottom_nav.add_child(button)


func _refresh() -> void:
	_draw_top_bar()
	_draw_map_placeholder()
	_draw_detail_panel()
	_update_nav_buttons()


func _draw_top_bar() -> void:
	_clear(resource_row)
	var workforce := WorkforcePresenterScript.summary(game)

	# Resources group — framed HUD panel
	var res_g := _make_top_group_panel("RESOURCES")
	resource_row.add_child(res_g[0])
	_add_top_chip(res_g[1], "Wood", str(game.industry_resources.get("Wood", 0)), color_text)
	_add_top_chip(res_g[1], "Stone", str(game.industry_resources.get("stone", 0)), color_text)
	_add_top_chip(res_g[1], "Coal", str(game.industry_resources.get("coal", 0)), color_text)
	_add_top_chip(res_g[1], "Food", str(game.total_food()), color_text)

	# Workforce group — framed HUD panel
	var wf_g := _make_top_group_panel("WORKFORCE")
	resource_row.add_child(wf_g[0])
	var free_c := _citizen_status_color("Free") if int(workforce.free) > 0 else color_muted
	var work_c := _citizen_status_color("Working") if int(workforce.assigned_workers) > 0 else color_muted
	var build_c := _citizen_status_color("Building") if int(workforce.builders) > 0 else color_muted
	_add_top_chip(wf_g[1], "Pop", "%s/%s" % [int(workforce.total), _citizen_capacity()], color_text)
	_add_top_chip(wf_g[1], "Free", str(int(workforce.free)), free_c)
	_add_top_chip(wf_g[1], "Assigned", str(int(workforce.assigned_workers)), work_c)
	_add_top_chip(wf_g[1], "Builders", str(int(workforce.builders)), build_c)

	# Time group — framed HUD panel
	var time_g := _make_top_group_panel("TIME")
	resource_row.add_child(time_g[0])
	_add_date_block(time_g[1])

	# Game Speed group — framed HUD panel
	var speed_g := _make_top_group_panel("GAME SPEED")
	resource_row.add_child(speed_g[0])
	_add_time_controls(speed_g[1])

	# Spacer + warnings
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resource_row.add_child(spacer)
	_add_top_warnings()


func _draw_map_placeholder() -> void:
	_clear(map_content)

	# Board header
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_content.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.add_theme_constant_override("separation", 2)
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	var title := _label("SETTLEMENT BOARD", 16, color_text)
	title_col.add_child(title)
	var subtitle_text := "Placement Mode — choose an empty cell" if _is_placing_build() else "Plan and manage your settlement"
	var subtitle := _label(subtitle_text, 11, color_accent if _is_placing_build() else color_muted)
	title_col.add_child(subtitle)

	# Board area (inner container for grid + legend)
	var board_outer := PanelContainer.new()
	board_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var board_fill := Color(0.12, 0.10, 0.07) if _is_placing_build() else Color(0.07, 0.07, 0.05)
	var board_border := color_accent if _is_placing_build() else Color(0.34, 0.26, 0.12)
	_style_panel(board_outer, board_fill, board_border, 2)
	map_content.add_child(board_outer)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 16)
	board_margin.add_theme_constant_override("margin_top", 14)
	board_margin.add_theme_constant_override("margin_right", 16)
	board_margin.add_theme_constant_override("margin_bottom", 10)
	board_outer.add_child(board_margin)

	var board_vbox := VBoxContainer.new()
	board_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_vbox.add_theme_constant_override("separation", 10)
	board_margin.add_child(board_vbox)

	if _is_placing_build():
		_draw_placement_preview(board_vbox)
	else:
		_draw_placement_grid(board_vbox)
		var legend_spacer := Control.new()
		legend_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		board_vbox.add_child(legend_spacer)
		_draw_board_legend(board_vbox)


func _draw_placement_preview(parent: VBoxContainer) -> void:
	var instruction := _label("Select Location", 16, color_accent)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(instruction)

	var selected := _label(placement_state.selected_name(), 24, color_text)
	selected.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(selected)

	var state_label := _label(_placement_status_text(), 14, color_accent if placement_state.has_valid_target() else color_muted)
	state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(state_label)

	_draw_placement_grid(parent)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 10)
	parent.add_child(controls)

	var confirm := Button.new()
	confirm.text = "Confirm Placement"
	confirm.custom_minimum_size = Vector2(160, 42)
	confirm.pressed.connect(_confirm_build_placement)
	_style_button(confirm, placement_state.has_valid_target())
	controls.add_child(confirm)

	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size = Vector2(110, 42)
	cancel.pressed.connect(_cancel_build_placement)
	_style_button(cancel, false)
	controls.add_child(cancel)

	var message := _label(placement_state.message, 13, color_muted)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(message)


func _draw_placement_grid(parent: VBoxContainer) -> void:
	var grid_shell := PanelContainer.new()
	grid_shell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_style_panel(grid_shell, Color(0.06, 0.06, 0.04), Color(0.36, 0.28, 0.12), 2)
	parent.add_child(grid_shell)

	var grid_margin := MarginContainer.new()
	grid_margin.add_theme_constant_override("margin_left", 10)
	grid_margin.add_theme_constant_override("margin_top", 10)
	grid_margin.add_theme_constant_override("margin_right", 10)
	grid_margin.add_theme_constant_override("margin_bottom", 10)
	grid_shell.add_child(grid_margin)

	var grid := GridContainer.new()
	grid.columns = PLACEMENT_GRID_COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid_margin.add_child(grid)

	for y in range(PLACEMENT_GRID_ROWS):
		for x in range(PLACEMENT_GRID_COLUMNS):
			_add_placement_cell_button(grid, x, y)


func _add_placement_cell_button(parent: GridContainer, x: int, y: int) -> void:
	var placement := game.placement_at(x, y)
	var occupied := not placement.is_empty()
	var cell := Vector2i(x, y)
	var selected := placement_state.target_cell == cell if _is_placing_build() else selected_placed_cell == cell
	var valid := not occupied

	var button = BoardBuildingTileScene.instantiate()
	button.custom_minimum_size = Vector2(92, 58)
	button.text = ""
	if occupied:
		var tile := PlacedBuildingPresenterScript.tile(game, placement)
		button.configure_placed(tile, selected and _is_placing_build(), color_text, color_muted, color_accent)
	else:
		button.configure_empty(selected and _is_placing_build(), Color(0.70, 0.92, 0.60), color_muted)
	if _is_placing_build():
		button.mouse_entered.connect(_target_placement_cell.bind(x, y))
	button.pressed.connect(_click_grid_cell.bind(x, y))
	_style_placement_cell(button, valid, selected, placement)
	parent.add_child(button)


func _placement_cell_text(x: int, y: int, placement: Dictionary, selected: bool) -> String:
	var occupied := not placement.is_empty()
	if not occupied:
		return "Place" if (selected and _is_placing_build()) else ""
	var tile := PlacedBuildingPresenterScript.tile(game, placement)
	if selected and _is_placing_build():
		return "%s\nBlocked" % str(tile.name)
	if bool(tile.under_construction):
		return "%s\n%s" % [str(tile.name), str(tile.progress_text)]
	return str(tile.name)


func _click_grid_cell(x: int, y: int) -> void:
	if _is_placing_build():
		_target_placement_cell(x, y)
		if not game.placement_at(x, y).is_empty():
			selected_placed_cell = Vector2i(x, y)
		return

	if not game.placement_at(x, y).is_empty():
		selected_placed_cell = Vector2i(x, y)
		_refresh()


func _target_placement_cell(x: int, y: int) -> void:
	if not _is_placing_build():
		return
	placement_state.target(x, y, game.can_place_building(x, y))
	_refresh()


func _placement_status_text() -> String:
	if placement_state.has_valid_target():
		return "Valid cell selected - ready to confirm."
	if placement_state.target_cell.x >= 0:
		return "Selected cell is occupied."
	return "Choose an empty cell."


func _draw_detail_panel() -> void:
	_clear(detail_content)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(header)

	var panel_title := selected_section.to_upper()
	var title := _label("─  %s" % panel_title, 14, color_accent)
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

	detail_panel.custom_minimum_size.x = RIGHT_PANEL_WIDTH + (40 if selected_section in ["Build", "Citizens", "Production", "Storage"] else 0)

	if selected_section == "Build":
		if _has_selected_placed_building() and not _is_placing_build():
			_draw_placed_building_detail()
			return
		_draw_build_panel()
		return

	if selected_section == "Citizens":
		_draw_citizens_panel()
		return

	if selected_section == "Production":
		_draw_production_panel()
		return

	if selected_section == "Storage":
		_draw_storage_panel()
		return

	if selected_section == "Events":
		_draw_events_panel()
		return

	if selected_section == "Management":
		_draw_management_panel()
		return

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


func _draw_build_panel() -> void:
	var entries: Array = BuildCatalogScript.entries(game)
	if entries.is_empty():
		detail_content.add_child(_label("No buildable entries found.", 13, color_muted))
		return

	if selected_build_id.is_empty():
		selected_build_id = str(entries[0].id)

	var intro_text := "Choose a building to prepare placement."
	if _is_placing_build():
		intro_text = "Placement preparation active. Confirm or cancel when ready."
	var intro := _label(intro_text, 12, color_muted)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_content.add_child(intro)

	var selected_entry := _find_build_entry(entries, selected_build_id)
	_draw_selected_build_summary(selected_entry)

	var list_title := _label("Buildable", 14, color_accent)
	detail_content.add_child(list_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 8)
	scroll.add_child(list)

	var last_category := ""
	for entry in entries:
		var category := str(entry.category_label)
		if category != last_category:
			var category_label := _label(category, 13, color_accent)
			category_label.custom_minimum_size.y = 26
			list.add_child(category_label)
			last_category = category
		_add_build_entry_card(list, entry)


func _draw_placed_building_detail() -> void:
	var placement := game.placement_at(selected_placed_cell.x, selected_placed_cell.y)
	if placement.is_empty():
		selected_placed_cell = Vector2i(-1, -1)
		_draw_build_panel()
		return

	var tile := PlacedBuildingPresenterScript.tile(game, placement)
	var position: Vector2i = tile.position
	var title := _label(str(tile.full_name), 17, color_text)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_content.add_child(title)

	var state_color := color_accent if bool(tile.under_construction) else color_text
	_add_detail_row("Category", str(tile.category))
	_add_detail_row("Position", "%s, %s" % [position.x, position.y])
	_add_detail_row("State", str(tile.state), state_color)
	_add_detail_row("Construction", "Yes" if bool(tile.under_construction) else "No")
	_draw_construction_progress_detail(tile)
	_draw_builder_controls(tile)
	_add_detail_row("Workers", _worker_detail_text(tile))
	_add_detail_row("Output", str(tile.output))

	var separator := HSeparator.new()
	detail_content.add_child(separator)

	var actions_title := _label("Actions", 14, color_accent)
	detail_content.add_child(actions_title)

	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	detail_content.add_child(actions)

	if bool(tile.has_workers):
		_add_sidebar_action(actions, "Assign Worker", _assign_selected_building_worker, bool(tile.can_assign_worker), true)
		_add_sidebar_action(actions, "Remove Worker", _remove_selected_building_worker, bool(tile.can_remove_worker))

		var hint := _label(_worker_action_hint(tile), 12, color_muted)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_content.add_child(hint)
	else:
		var no_workers := _label("This building type does not use assignable workers yet.", 12, color_muted)
		no_workers.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_content.add_child(no_workers)

	_add_sidebar_action(actions, "Demolish", _demolish_selected_building, true)

	var back := Button.new()
	back.text = "Back To Build Menu"
	back.custom_minimum_size.y = 38
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.pressed.connect(_clear_placed_building_selection)
	_style_button(back, false)
	detail_content.add_child(back)


func _draw_construction_progress_detail(tile: Dictionary) -> void:
	if not bool(tile.under_construction):
		var ready := _label("Construction complete. Building is ready.", 12, color_muted)
		ready.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_content.add_child(ready)
		return

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.24, 0.20, 0.13), color_accent, 1)
	detail_content.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var title := _label("Construction in progress", 13, color_accent)
	box.add_child(title)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = int(tile.progress_max)
	bar.value = int(tile.progress)
	bar.custom_minimum_size.y = 16
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	box.add_child(bar)

	var progress := _label("%s / %s  (%s)" % [int(tile.progress), int(tile.progress_max), str(tile.progress_text)], 12, color_text)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(progress)


func _draw_builder_controls(tile: Dictionary) -> void:
	if not bool(tile.under_construction):
		return

	var panel = SidebarSectionScene.instantiate()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.19, 0.18, 0.14), Color(0.38, 0.34, 0.25), 1, "inner")
	detail_content.add_child(panel)

	var box: VBoxContainer = panel.configure("Construction Crew", color_accent)
	box.add_child(_label("Builders assigned: %s" % int(tile.builders), 12, color_text))
	box.add_child(_label(WorkforcePresenterScript.free_text(game), 12, color_muted))
	var status := _label(str(tile.construction_status), 12, color_accent if int(tile.builders) > 0 else color_muted)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)

	_add_sidebar_action(actions, "Assign Builder", _assign_selected_building_builder, bool(tile.can_assign_builder), true)
	_add_sidebar_action(actions, "Remove Builder", _remove_selected_building_builder, bool(tile.can_remove_builder))


func _draw_selected_build_summary(entry: Dictionary) -> void:
	var summary := PanelContainer.new()
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(summary, Color(0.25, 0.21, 0.14), color_accent, 1)
	detail_content.add_child(summary)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	summary.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	box.add_child(_label(str(entry.name), 16, color_text))
	var status_text := "Selected - %s" % str(entry.status)
	if _is_placing_build() and placement_state.has_valid_target():
		status_text = "Selected - target cell ready"
	elif _is_placing_build():
		status_text = "Selected - choose an empty cell"
	var status := _label(status_text, 12, color_accent)
	box.add_child(status)
	box.add_child(_label("Role: %s" % str(entry.capacity), 12, color_muted))
	box.add_child(_label("Output: %s" % str(entry.output), 12, color_muted))
	box.add_child(_label("Build cost: %s" % str(entry.cost), 12, color_muted))
	if placement_state != null and placement_state.message != "":
		box.add_child(_label(placement_state.message, 12, color_accent if _is_placing_build() else color_muted))

	var action := Button.new()
	action.text = "Confirm Placement" if _is_placing_build() else "Ready To Place"
	action.custom_minimum_size.y = 36
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _is_placing_build():
		action.pressed.connect(_confirm_build_placement)
	else:
		action.pressed.connect(_prepare_selected_build_placement)
	_style_button(action, true)
	box.add_child(action)

	if _is_placing_build():
		var cancel := Button.new()
		cancel.text = "Cancel Placement"
		cancel.custom_minimum_size.y = 34
		cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cancel.pressed.connect(_cancel_build_placement)
		_style_button(cancel, false)
		box.add_child(cancel)


func _add_build_entry_card(parent: VBoxContainer, entry: Dictionary) -> void:
	var selected := str(entry.id) == selected_build_id
	var card = BuildEntryCardScene.instantiate()
	card.configure(entry, selected, color_text, color_muted, color_accent)
	card.selected.connect(_select_build_entry)
	parent.add_child(card)
	_style_panel(card, Color(0.24, 0.21, 0.16) if selected else color_panel_soft, color_accent if selected else Color(0.30, 0.27, 0.20), 1, "inner")
	_style_button(card.select_button, selected)


func _draw_citizens_panel() -> void:
	var workforce := WorkforcePresenterScript.summary(game)
	var all_presented: Array = CitizenPresenterScript.present_all(game)

	# Workforce stat chips
	var stat_row := HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(stat_row)
	_make_citizen_stat_chip(stat_row, "Total", str(int(workforce.total)), color_text)
	_make_citizen_stat_chip(stat_row, "Free", str(int(workforce.free)), _citizen_status_color("Free"))
	_make_citizen_stat_chip(stat_row, "Working", str(int(workforce.assigned_workers)), _citizen_status_color("Working"))
	_make_citizen_stat_chip(stat_row, "Building", str(int(workforce.builders)), _citizen_status_color("Building"))

	# Filter chips
	var filter_row := HBoxContainer.new()
	filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(filter_row)
	for f in ["All", "Free", "Working", "Building"]:
		var chip := Button.new()
		chip.text = f
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size.y = 30
		chip.pressed.connect(_set_citizens_filter.bind(f))
		_style_button(chip, citizens_filter == f)
		filter_row.add_child(chip)

	# Roster label
	detail_content.add_child(_label("Roster", 13, color_muted))

	# Scrollable citizen list
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.add_theme_constant_override("separation", 6)
	scroll.add_child(roster)

	var shown := 0
	for presented in all_presented:
		if citizens_filter != "All" and str(presented.status) != citizens_filter:
			continue
		shown += 1
		_draw_citizen_row(roster, presented)

	if shown == 0:
		var empty := _label("No citizens match this filter.", 12, color_muted)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roster.add_child(empty)

	# Separator + selected detail
	detail_content.add_child(HSeparator.new())

	var selected_data: Dictionary = {}
	for p in all_presented:
		if int(p.id) == selected_citizen_id:
			selected_data = p
			break

	if selected_data.is_empty():
		var hint := _label("Select a citizen to see details.", 12, color_muted)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_content.add_child(hint)
	else:
		_draw_citizen_detail_panel(selected_data)


func _draw_citizen_row(parent: VBoxContainer, presented: Dictionary) -> void:
	var cid := int(presented.id)
	var selected := cid == selected_citizen_id

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_panel(card,
		Color(0.26, 0.23, 0.16) if selected else color_panel_soft,
		color_accent if selected else Color(0.30, 0.27, 0.20),
		1)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_citizen(cid)
	)
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_top", 7)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_bottom", 7)
	card.add_child(cm)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	cm.add_child(box)

	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(name_row)

	var name_lbl := _label(str(presented.name), 14, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var status_lbl := _label(str(presented.status), 12, _citizen_status_color(str(presented.status)))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_row.add_child(status_lbl)

	var info_row := HBoxContainer.new()
	info_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_theme_constant_override("separation", 8)
	box.add_child(info_row)

	var wa_lbl := _label(str(presented.workarea_label), 11, color_muted)
	wa_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_row.add_child(wa_lbl)

	var stats_lbl := _label("HP:%s  Joy:%s  Age:%s" % [int(presented.health), int(presented.happiness), int(presented.age)], 11, color_muted)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_row.add_child(stats_lbl)


func _draw_citizen_detail_panel(presented: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.22, 0.20, 0.15), color_accent, 1)
	detail_content.add_child(panel)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 12)
	cm.add_theme_constant_override("margin_top", 10)
	cm.add_theme_constant_override("margin_right", 12)
	cm.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(cm)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	cm.add_child(box)

	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header_row)

	var name_lbl := _label(str(presented.name), 15, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)

	var status_lbl := _label(str(presented.status), 13, _citizen_status_color(str(presented.status)))
	header_row.add_child(status_lbl)

	var wa_lbl := _label(str(presented.workarea_label), 12, color_muted)
	wa_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(wa_lbl)

	box.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)

	var hunger_text := "Hungry" if presented.get("hunger", false) else "Sated"
	var shelter_text := "Yes" if presented.get("shelter", false) else "No"
	for row in [
		["Health", "%s / 100" % int(presented.health)],
		["Happiness", "%s / 100" % int(presented.happiness)],
		["Age", "%s years" % int(presented.age)],
		["Efficiency", "%s%%" % int(presented.efficiency)],
		["Hunger", hunger_text],
		["Shelter", shelter_text],
	]:
		grid.add_child(_label(str(row[0]), 12, color_muted))
		grid.add_child(_label(str(row[1]), 12, color_text))


func _set_citizens_filter(filter: String) -> void:
	citizens_filter = filter
	_refresh()


func _select_citizen(citizen_id: int) -> void:
	selected_citizen_id = citizen_id if selected_citizen_id != citizen_id else -1
	_refresh()


func _citizen_status_color(status: String) -> Color:
	match status:
		"Free":
			return Color(0.52, 0.74, 0.38)
		"Working":
			return Color(0.46, 0.72, 0.88)
		"Building":
			return color_accent
	return color_muted


func _make_citizen_stat_chip(parent: HBoxContainer, label_text: String, value: String, value_color: Color) -> void:
	var chip = SidebarStatCardScene.instantiate()
	chip.configure(label_text, value, value_color, color_muted)
	chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(chip, color_panel_soft, color_border, 1, "inner")
	parent.add_child(chip)


func _draw_production_panel() -> void:
	var all_entries: Array = ProductionPresenterScript.present_buildings(game)

	# Count entries per filter key for summary chips
	var counts := {"Producing": 0, "No Workers": 0, "Building": 0, "Idle": 0}
	for entry in all_entries:
		var fk := str(entry.filter_key)
		if counts.has(fk):
			counts[fk] += 1

	# Summary stat chips
	var stat_row := HBoxContainer.new()
	stat_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(stat_row)
	_make_citizen_stat_chip(stat_row, "Producing", str(counts["Producing"]), _production_status_color("Producing"))
	_make_citizen_stat_chip(stat_row, "No Workers", str(counts["No Workers"]), _production_status_color("No Workers"))
	_make_citizen_stat_chip(stat_row, "Building", str(counts["Building"]), _production_status_color("Building X%"))
	_make_citizen_stat_chip(stat_row, "Idle", str(counts["Idle"]), color_muted)

	# Filter chips
	var filter_row := HBoxContainer.new()
	filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(filter_row)
	for f in ["All", "Producing", "No Workers", "Building"]:
		var chip := Button.new()
		chip.text = f
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size.y = 30
		chip.add_theme_font_size_override("font_size", 12)
		chip.pressed.connect(_set_production_filter.bind(f))
		_style_button(chip, production_filter == f)
		filter_row.add_child(chip)

	# Category labels + scrollable roster
	detail_content.add_child(_label("Buildings", 13, color_muted))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.add_theme_constant_override("separation", 5)
	scroll.add_child(roster)

	var last_category := ""
	var shown := 0
	for entry in all_entries:
		if production_filter != "All" and str(entry.filter_key) != production_filter:
			continue
		# Category section header
		var cat_label := str(entry.category_label)
		if cat_label != last_category:
			var cat_lbl := _label(cat_label, 11, color_accent)
			cat_lbl.custom_minimum_size.y = 20
			roster.add_child(cat_lbl)
			last_category = cat_label
		shown += 1
		_draw_production_row(roster, entry)

	if shown == 0:
		var empty := _label("No buildings match this filter.", 12, color_muted)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roster.add_child(empty)

	# Separator + selected detail
	detail_content.add_child(HSeparator.new())

	var selected_entry: Dictionary = {}
	for e in all_entries:
		if str(e.id) == selected_production_id:
			selected_entry = e
			break

	if selected_entry.is_empty():
		var hint := _label("Select a building to see details.", 12, color_muted)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_content.add_child(hint)
	else:
		_draw_production_detail_panel(selected_entry)


func _draw_production_row(parent: VBoxContainer, entry: Dictionary) -> void:
	var eid := str(entry.id)
	var selected := eid == selected_production_id

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_panel(card,
		Color(0.26, 0.23, 0.16) if selected else color_panel_soft,
		color_accent if selected else Color(0.30, 0.27, 0.20),
		1)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_production_entry(eid)
	)
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_top", 7)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_bottom", 7)
	card.add_child(cm)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	cm.add_child(box)

	# Row 1: Name + Status
	var name_row := HBoxContainer.new()
	name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(name_row)

	var name_lbl := _label(str(entry.name), 14, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_lbl)

	var status_str := str(entry.status)
	var status_lbl := _label(status_str, 11, _production_status_color(status_str))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	name_row.add_child(status_lbl)

	# Row 2: Grid + Workers
	var meta_row := HBoxContainer.new()
	meta_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_row.add_theme_constant_override("separation", 8)
	box.add_child(meta_row)

	var grid_lbl := _label("Grid: %s" % str(entry.position_label), 11, color_muted)
	meta_row.add_child(grid_lbl)

	var workers_lbl := _label("Workers: %s/%s" % [int(entry.workers), int(entry.capacity)], 11, color_muted)
	meta_row.add_child(workers_lbl)

	# Row 3: Output + Last
	var output_row := HBoxContainer.new()
	output_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_row.add_theme_constant_override("separation", 8)
	box.add_child(output_row)

	var out_lbl := _label("→ %s" % str(entry.output_label), 11, color_muted)
	out_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	output_row.add_child(out_lbl)

	var last_str := str(entry.last_label)
	if last_str != "":
		var last_lbl := _label(last_str, 11, _production_last_color(last_str))
		last_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		output_row.add_child(last_lbl)


func _draw_production_detail_panel(entry: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.22, 0.20, 0.15), color_accent, 1)
	detail_content.add_child(panel)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 12)
	cm.add_theme_constant_override("margin_top", 10)
	cm.add_theme_constant_override("margin_right", 12)
	cm.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(cm)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	cm.add_child(box)

	# Name + Status header
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header_row)

	var name_lbl := _label(str(entry.name), 15, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)

	var status_str := str(entry.status)
	var status_lbl := _label(status_str, 12, _production_status_color(status_str))
	header_row.add_child(status_lbl)

	var cat_lbl := _label(str(entry.category_label), 12, color_muted)
	box.add_child(cat_lbl)

	box.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)

	var workers_str := "%s / %s" % [int(entry.workers), int(entry.capacity)]
	var last_str := str(entry.last_label)
	var last_display := last_str if last_str != "" else "None this tick"
	var under_con: bool = entry.get("under_construction", false)

	for row in [
		["Grid", str(entry.position_label)],
		["Workers", workers_str],
		["Output", str(entry.output_label)],
		["Last Tick", last_display],
		["Quantity", str(int(entry.quantity))],
		["Under Const.", "Yes — %s%%" % int(entry.build_percent) if under_con else "No"],
	]:
		grid.add_child(_label(str(row[0]), 12, color_muted))
		grid.add_child(_label(str(row[1]), 12, color_text))


func _set_production_filter(filter: String) -> void:
	production_filter = filter
	_refresh()


func _select_production_entry(entry_id: String) -> void:
	selected_production_id = entry_id if selected_production_id != entry_id else ""
	_refresh()


func _production_status_color(status: String) -> Color:
	if status == "Producing" or status == "Crafting":
		return Color(0.52, 0.74, 0.38)
	if status == "Harvesting":
		return Color(0.52, 0.72, 0.58)
	if status == "No Workers":
		return Color(0.74, 0.56, 0.42)
	if status.begins_with("Building"):
		return color_accent
	if status == "Storage Full":
		return Color(0.82, 0.68, 0.30)
	if status == "No Input":
		return Color(0.80, 0.48, 0.32)
	return color_muted


func _production_last_color(last_str: String) -> Color:
	if last_str.begins_with("+"):
		return Color(0.52, 0.74, 0.38)
	if last_str == "Storage Full":
		return Color(0.82, 0.68, 0.30)
	if last_str == "No Input":
		return Color(0.80, 0.48, 0.32)
	return color_muted


func _draw_storage_panel() -> void:
	var barn := StoragePresenterScript.barn_summary(game)
	var warehouse := StoragePresenterScript.warehouse_summary(game)
	var all_rows: Array = StoragePresenterScript.resource_rows(game)

	# Storage summary cards (side by side)
	var cards_row := HBoxContainer.new()
	cards_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_row.add_theme_constant_override("separation", 8)
	detail_content.add_child(cards_row)
	_draw_storage_summary_card(cards_row, barn)
	_draw_storage_summary_card(cards_row, warehouse)

	# Filter chips
	var filter_row := HBoxContainer.new()
	filter_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_row.add_theme_constant_override("separation", 6)
	detail_content.add_child(filter_row)
	for f in ["All", "Food", "Materials", "Stocked"]:
		var chip := Button.new()
		chip.text = f
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size.y = 30
		chip.add_theme_font_size_override("font_size", 13)
		chip.pressed.connect(_set_storage_filter.bind(f))
		_style_button(chip, storage_filter == f)
		filter_row.add_child(chip)

	# Resources label
	detail_content.add_child(_label("Resources", 13, color_muted))

	# Scrollable resource roster
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var roster := VBoxContainer.new()
	roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster.add_theme_constant_override("separation", 4)
	scroll.add_child(roster)

	var show_all := storage_filter == "All"
	var last_cat := ""
	var shown := 0

	for row in all_rows:
		var cat := str(row.category)
		var amount := int(row.amount)
		var pass_filter := false
		match storage_filter:
			"All":
				pass_filter = true
			"Food":
				pass_filter = cat == "food"
			"Materials":
				pass_filter = cat == "industry" or cat == "crafted"
			"Stocked":
				pass_filter = amount > 0

		if not pass_filter:
			continue

		# Section header (only in All mode, and only when category changes)
		if show_all and str(row.category_label) != last_cat:
			last_cat = str(row.category_label)
			var storage_ctx := barn if cat == "food" else warehouse
			var sec_text := "%s  ·  %s %s/%s" % [
				str(row.category_label),
				str(storage_ctx.label),
				int(storage_ctx.current),
				int(storage_ctx.capacity)
			]
			var sec_lbl := _label(sec_text, 11, color_accent)
			sec_lbl.custom_minimum_size.y = 22
			roster.add_child(sec_lbl)

		shown += 1
		_draw_resource_row(roster, row)

	if shown == 0:
		var empty := _label("No resources match this filter.", 12, color_muted)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		roster.add_child(empty)

	# Separator + selected resource detail
	detail_content.add_child(HSeparator.new())

	var selected_row: Dictionary = {}
	for r in all_rows:
		if str(r.id) == selected_resource_id:
			selected_row = r
			break

	if selected_row.is_empty():
		var hint := _label("Select a resource to see details.", 12, color_muted)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail_content.add_child(hint)
	else:
		_draw_storage_resource_detail(selected_row)


func _draw_storage_summary_card(parent: HBoxContainer, summary: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(card, Color(0.20, 0.19, 0.15), color_border, 1)
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 8)
	cm.add_theme_constant_override("margin_top", 8)
	cm.add_theme_constant_override("margin_right", 8)
	cm.add_theme_constant_override("margin_bottom", 8)
	card.add_child(cm)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	cm.add_child(box)

	var name_lbl := _label(str(summary.label), 14, color_accent)
	box.add_child(name_lbl)

	var role_lbl := _label(str(summary.role), 10, color_muted)
	box.add_child(role_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(int(summary.capacity), 1)
	bar.value = int(summary.current)
	bar.custom_minimum_size.y = 12
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	box.add_child(bar)

	var pct := int(summary.fill_pct)
	var status_str := str(summary.fill_status)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 4)
	box.add_child(stats_row)

	var fill_lbl := _label("%s/%s" % [int(summary.current), int(summary.capacity)], 10, color_muted)
	fill_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(fill_lbl)

	var status_lbl := _label(status_str, 10, _storage_fill_color(pct))
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_row.add_child(status_lbl)


func _draw_resource_row(parent: VBoxContainer, row: Dictionary) -> void:
	var rid := str(row.id)
	var selected := rid == selected_resource_id
	var amount := int(row.amount)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_style_panel(card,
		Color(0.26, 0.23, 0.16) if selected else color_panel_soft,
		color_accent if selected else Color(0.30, 0.27, 0.20),
		1)
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_resource(rid)
	)
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_top", 5)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_bottom", 5)
	card.add_child(cm)

	var line := HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cm.add_child(line)

	var name_lbl := _label(str(row.name), 13, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_lbl)

	var amount_color := color_text if amount > 0 else color_muted
	var amount_lbl := _label(str(amount), 13, amount_color)
	amount_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_lbl.custom_minimum_size.x = 38
	line.add_child(amount_lbl)


func _draw_storage_resource_detail(row: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color(0.22, 0.20, 0.15), color_accent, 1)
	detail_content.add_child(panel)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 12)
	cm.add_theme_constant_override("margin_top", 10)
	cm.add_theme_constant_override("margin_right", 12)
	cm.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(cm)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	cm.add_child(box)

	# Name + Amount header
	var header_row := HBoxContainer.new()
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(header_row)

	var name_lbl := _label(str(row.name), 15, color_text)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(name_lbl)

	var amount := int(row.amount)
	var amount_lbl := _label(str(amount), 15, color_text if amount > 0 else color_muted)
	header_row.add_child(amount_lbl)

	var cat_lbl := _label("%s  ·  %s" % [str(row.category_label), str(row.storage_label)], 12, color_muted)
	box.add_child(cat_lbl)

	box.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)

	var pct := int(row.storage_fill_pct)
	for detail_row in [
		["Storage Fill", "%s / %s" % [int(row.storage_current), int(row.storage_capacity)]],
		["Fill Level", "%s%%" % pct],
		["Storage Status", str(row.storage_fill_status)],
	]:
		grid.add_child(_label(str(detail_row[0]), 12, color_muted))
		grid.add_child(_label(str(detail_row[1]), 12, color_text))


func _set_storage_filter(filter: String) -> void:
	storage_filter = filter
	_refresh()


func _select_resource(resource_id: String) -> void:
	selected_resource_id = resource_id if selected_resource_id != resource_id else ""
	_refresh()


func _storage_fill_color(pct: int) -> Color:
	if pct >= 95:
		return Color(0.80, 0.38, 0.30)
	if pct >= 75:
		return Color(0.82, 0.68, 0.30)
	if pct >= 20:
		return Color(0.52, 0.74, 0.38)
	if pct > 0:
		return Color(0.74, 0.56, 0.42)
	return color_muted


func _draw_events_panel() -> void:
	var all_events: Array = EventsPresenterScript.present_events(game)
	var count := all_events.size()

	var count_lbl := _label(
		"%s recent event%s" % [count, "s" if count != 1 else ""] if count > 0 else "No events recorded yet.",
		12, color_muted)
	detail_content.add_child(count_lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var log_box := VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_theme_constant_override("separation", 5)
	scroll.add_child(log_box)

	if all_events.is_empty():
		var empty := _label("Settlement activity will appear here.", 13, color_muted)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_box.add_child(empty)
		return

	for event in all_events:
		_draw_event_row(log_box, event)


func _draw_event_row(parent: VBoxContainer, event: Dictionary) -> void:
	var cat := str(event.category)
	var cat_color := _event_category_color(cat)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_panel(card, color_panel_soft, cat_color, 1, "inner")
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_top", 6)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_bottom", 6)
	card.add_child(cm)

	var line := HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_theme_constant_override("separation", 8)
	cm.add_child(line)

	var text_lbl := _label(str(event.text), 13, color_text)
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_child(text_lbl)

	var cat_label := str(event.category_label)
	if cat_label != "—":
		var cat_lbl := _label(cat_label, 10, cat_color)
		cat_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		line.add_child(cat_lbl)


func _event_category_color(category: String) -> Color:
	match category:
		"construction":
			return color_accent
		"production":
			return Color(0.52, 0.74, 0.38)
	return color_muted


func _draw_management_panel() -> void:
	var overview := ManagementPresenterScript.overview(game)
	var status_items := ManagementPresenterScript.status_items(game)
	var warn_list := ManagementPresenterScript.warnings(game)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_content.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)

	# === SETTLEMENT OVERVIEW ===
	body.add_child(_section_header("SETTLEMENT OVERVIEW", color_accent))

	# Date + time state (compact)
	var time_state := "PAUSED" if not game.running else "%sx" % time_scale
	var date_row := HBoxContainer.new()
	date_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(date_row)
	var date_lbl := _label(str(overview.date), 11, color_muted)
	date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_row.add_child(date_lbl)
	var time_lbl := _label(time_state, 11, color_accent if game.running else Color(0.80, 0.40, 0.30))
	date_row.add_child(time_lbl)

	# Population stat chips
	var pop_row := HBoxContainer.new()
	pop_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pop_row.add_theme_constant_override("separation", 5)
	body.add_child(pop_row)
	_make_citizen_stat_chip(pop_row, "Citizens", str(int(overview.population)), color_text)
	_make_citizen_stat_chip(pop_row, "Free", str(int(overview.free)), _citizen_status_color("Free"))
	_make_citizen_stat_chip(pop_row, "Working", str(int(overview.assigned)), _citizen_status_color("Working"))
	_make_citizen_stat_chip(pop_row, "Building", str(int(overview.builders)), _citizen_status_color("Building"))

	# Wellness chips
	var well_row := HBoxContainer.new()
	well_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	well_row.add_theme_constant_override("separation", 5)
	body.add_child(well_row)
	var hp := int(overview.global_health)
	var joy := int(overview.global_happiness)
	_make_citizen_stat_chip(well_row, "Health", "%s%%" % hp, _wellness_color(hp))
	_make_citizen_stat_chip(well_row, "Joy", "%s%%" % joy, _wellness_color(joy))
	_make_citizen_stat_chip(well_row, "Food", str(int(overview.total_food)), color_muted)

	# === SETTLEMENT STATUS ===
	body.add_child(_section_header("SETTLEMENT STATUS", color_muted))

	for item in status_items:
		_draw_management_status_item(body, item)

	# === ACTIVE ALERTS ===
	if not warn_list.is_empty():
		body.add_child(_section_header("ACTIVE ALERTS", Color(0.82, 0.36, 0.26)))
		for w in warn_list:
			_draw_management_warning(body, str(w))

	# === CONTROLS ===
	body.add_child(_section_header("CONTROLS", color_muted))

	var save_btn := Button.new()
	save_btn.text = "SAVE GAME"
	save_btn.custom_minimum_size.y = 42
	save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_btn.add_theme_font_size_override("font_size", 13)
	save_btn.pressed.connect(_management_save_game)
	_style_button(save_btn, true)
	body.add_child(save_btn)

	var auto_note := _label("Auto-saves each day cycle.", 10, color_muted)
	body.add_child(auto_note)

	var reset_btn := Button.new()
	reset_btn.text = "CLEAR SAVE DATA"
	reset_btn.custom_minimum_size.y = 38
	reset_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_btn.add_theme_font_size_override("font_size", 12)
	reset_btn.pressed.connect(_management_reset_save)
	_style_button(reset_btn, false)
	body.add_child(reset_btn)

	var reset_note := _label("Requires scene restart to take effect.", 10, color_muted)
	reset_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(reset_note)


func _draw_management_status_item(parent: VBoxContainer, item: Dictionary) -> void:
	var level := str(item.level)
	var level_color := _management_level_color(level)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var dot := _label("●", 11, level_color)
	dot.custom_minimum_size.x = 14
	row.add_child(dot)

	var lbl := _label(str(item.label), 12, color_muted)
	lbl.custom_minimum_size.x = 88
	row.add_child(lbl)

	var val := _label(str(item.value), 12, level_color)
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(val)


func _draw_management_warning(parent: VBoxContainer, text: String) -> void:
	var is_critical := "critical" in text.to_lower() or "hungry" in text.to_lower()
	var warn_fill := Color(0.22, 0.10, 0.08) if is_critical else Color(0.22, 0.17, 0.08)
	var warn_border := Color(0.70, 0.28, 0.20) if is_critical else Color(0.72, 0.56, 0.20)
	var warn_text_color := Color(0.90, 0.50, 0.44) if is_critical else Color(0.86, 0.70, 0.36)

	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(card, warn_fill, warn_border, 1, "warning")
	parent.add_child(card)

	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 10)
	cm.add_theme_constant_override("margin_top", 6)
	cm.add_theme_constant_override("margin_right", 10)
	cm.add_theme_constant_override("margin_bottom", 6)
	card.add_child(cm)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	cm.add_child(row)
	row.add_child(_label("!", 13, warn_border))
	var lbl := _label(text, 12, warn_text_color)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)


func _management_save_game() -> void:
	_save_game_if_runtime()


func _management_reset_save() -> void:
	game.reset_save()
	_refresh()


func _management_level_color(level: String) -> Color:
	match level:
		"ok":
			return Color(0.52, 0.74, 0.38)
		"active":
			return color_accent
		"warning":
			return Color(0.82, 0.68, 0.30)
		"critical":
			return Color(0.80, 0.38, 0.30)
	return color_muted


func _wellness_color(pct: int) -> Color:
	if pct >= 70:
		return Color(0.52, 0.74, 0.38)
	if pct >= 50:
		return color_accent
	if pct >= 30:
		return Color(0.82, 0.68, 0.30)
	return Color(0.80, 0.38, 0.30)


func _select_build_entry(entry_id: String) -> void:
	selected_placed_cell = Vector2i(-1, -1)
	selected_build_id = entry_id
	_prepare_selected_build_placement()


func _prepare_selected_build_placement() -> void:
	selected_placed_cell = Vector2i(-1, -1)
	var entries: Array = BuildCatalogScript.entries(game)
	if entries.is_empty():
		return
	var entry := _find_build_entry(entries, selected_build_id)
	placement_state.prepare(entry)
	_refresh()


func _cancel_build_placement() -> void:
	placement_state.cancel()
	_refresh()


func _confirm_build_placement() -> void:
	if not placement_state.has_selection():
		return
	if not placement_state.has_valid_target():
		placement_state.message = "Choose an empty cell before confirming."
		_refresh()
		return

	var entry := placement_state.selected_entry
	var building := _building_data_for_entry(entry)
	if bool(building.get("building", false)):
		placement_state.active = false
		placement_state.message = "Already under construction."
		_refresh()
		return

	var target_cell := placement_state.target_cell
	if not game.place_building(str(entry.get("category", "")), int(entry.get("index", -1)), target_cell.x, target_cell.y):
		placement_state.message = "That cell cannot accept a building."
		_refresh()
		return

	placement_state.confirm()
	game.start_build(str(entry.get("category", "")), int(entry.get("index", -1)))
	selected_placed_cell = target_cell
	_save_game_if_runtime()
	_refresh()


func _is_placing_build() -> bool:
	return selected_section == "Build" and placement_state != null and placement_state.active


func _has_selected_placed_building() -> bool:
	return selected_placed_cell.x >= 0 and selected_placed_cell.y >= 0 and not game.placement_at(selected_placed_cell.x, selected_placed_cell.y).is_empty()


func _clear_placed_building_selection() -> void:
	selected_placed_cell = Vector2i(-1, -1)
	_refresh()


func _assign_selected_building_worker() -> void:
	var tile := _selected_placed_tile()
	if tile.is_empty() or not bool(tile.can_assign_worker):
		return
	game.add_worker(str(tile.category_key), int(tile.index))
	_save_game_if_runtime()
	_refresh()


func _remove_selected_building_worker() -> void:
	var tile := _selected_placed_tile()
	if tile.is_empty() or not bool(tile.can_remove_worker):
		return
	game.remove_worker(str(tile.category_key), int(tile.index))
	_save_game_if_runtime()
	_refresh()


func _assign_selected_building_builder() -> void:
	var tile := _selected_placed_tile()
	if tile.is_empty() or not bool(tile.can_assign_builder):
		return
	game.assign_builder(str(tile.category_key), int(tile.index))
	_save_game_if_runtime()
	_refresh()


func _remove_selected_building_builder() -> void:
	var tile := _selected_placed_tile()
	if tile.is_empty() or not bool(tile.can_remove_builder):
		return
	game.remove_builder(str(tile.category_key), int(tile.index))
	_save_game_if_runtime()
	_refresh()


func _demolish_selected_building() -> void:
	if selected_placed_cell.x < 0 or selected_placed_cell.y < 0:
		return
	if game.demolish_placed_building(selected_placed_cell.x, selected_placed_cell.y):
		selected_placed_cell = Vector2i(-1, -1)
		if placement_state != null:
			placement_state.cancel()
		_refresh()


func _selected_placed_tile() -> Dictionary:
	if not _has_selected_placed_building():
		return {}
	return PlacedBuildingPresenterScript.tile(game, game.placement_at(selected_placed_cell.x, selected_placed_cell.y))


func _worker_detail_text(tile: Dictionary) -> String:
	if not bool(tile.has_workers):
		return "Not used"
	return "%s / %s" % [int(tile.workers), int(tile.capacity)]


func _worker_action_hint(tile: Dictionary) -> String:
	if bool(tile.can_assign_worker):
		return WorkforcePresenterScript.free_text(game)
	if int(tile.workers) >= int(tile.capacity):
		return "Worker capacity is full."
	if int(WorkforcePresenterScript.summary(game).free) <= 0:
		return WorkforcePresenterScript.assignment_blocked_text(game)
	return "Worker actions available."


func _save_game_if_runtime() -> void:
	if Engine.is_editor_hint():
		return
	game.save_game()


func _find_build_entry(entries: Array, entry_id: String) -> Dictionary:
	for entry in entries:
		if str(entry.id) == entry_id:
			return entry
	return entries[0]


func _building_data_for_entry(entry: Dictionary) -> Dictionary:
	var list: Array = []
	var category := str(entry.get("category", ""))
	if category == "industry":
		list = game.industry_buildings
	elif category == "food":
		list = game.food_buildings
	elif category == "craft":
		list = game.craft_buildings
	elif category == "town":
		list = game.town_services
	elif category == "storage":
		list = game.storages

	var index := int(entry.get("index", -1))
	if index < 0 or index >= list.size():
		return {}
	return list[index]


func _draw_board_legend(parent: VBoxContainer) -> void:
	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", 14)
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(legend)

	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend.add_child(filler)

	for cat in [
		["Food", Color(0.28, 0.52, 0.22)],
		["Resources", Color(0.46, 0.40, 0.26)],
		["Crafting", Color(0.26, 0.42, 0.58)],
		["Town", Color(0.42, 0.28, 0.58)],
		["Storage", Color(0.52, 0.42, 0.20)],
		["Building", color_accent],
	]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		legend.add_child(item)
		var dot := _label("●", 10, cat[1] as Color)
		item.add_child(dot)
		var lbl := _label(cat[0] as String, 10, color_muted)
		item.add_child(lbl)


func _add_resource_chip(title: String, value: String) -> void:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(104, 38)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(chip, color_panel_soft, Color(0.30, 0.27, 0.20), 1, "chip")
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


func _add_date_block(parent: HBoxContainer) -> void:
	var chip := PanelContainer.new()
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(chip, color_panel_soft, Color(0.30, 0.27, 0.20), 1, "chip")
	parent.add_child(chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 4)
	chip.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	margin.add_child(box)
	box.add_child(_label("Date", 10, color_muted))
	box.add_child(_label("Day %s  ·  %s / %s" % [game.day, game.month, game.year], 14, color_text))


func _add_time_controls(parent: HBoxContainer) -> void:
	time_buttons.clear()
	var group := HBoxContainer.new()
	group.add_theme_constant_override("separation", 3)
	group.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(group)

	var pause := _time_button("Pause")
	pause.pressed.connect(_toggle_pause)
	group.add_child(pause)
	time_buttons["Pause"] = pause

	for speed in [1, 2, 3]:
		var btn := _time_button("%sx" % speed)
		btn.pressed.connect(_set_time_scale.bind(speed))
		group.add_child(btn)
		time_buttons[speed] = btn

	_update_time_buttons()


func _add_top_chip(parent: HBoxContainer, title: String, value: String, value_color: Color) -> void:
	var chip = TopStatChipScene.instantiate()
	chip.configure(title, value, value_color, Color(0.52, 0.46, 0.30))
	chip.custom_minimum_size = Vector2(80, 0)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(chip, color_panel_soft, color_border, 1, "chip")
	parent.add_child(chip)


func _make_top_group_panel(label_text: String) -> Array:
	# Returns [outer PanelContainer, inner HBoxContainer for chip content]
	var outer := PanelContainer.new()
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_panel(outer, Color(0.13, 0.12, 0.08), color_border, 1, "inner")

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	outer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	margin.add_child(vbox)

	var lbl := _label(label_text, 9, Color(0.58, 0.50, 0.30))
	vbox.add_child(lbl)

	var content := HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	vbox.add_child(content)

	return [outer, content]


func _section_header(label_text: String, label_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)

	var line_l := HSeparator.new()
	line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sl := StyleBoxLine.new()
	sl.color = Color(label_color.r, label_color.g, label_color.b, 0.35)
	line_l.add_theme_stylebox_override("separator", sl)
	row.add_child(line_l)

	row.add_child(_label(label_text, 10, label_color))

	var line_r := HSeparator.new()
	line_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sr := StyleBoxLine.new()
	sr.color = Color(label_color.r, label_color.g, label_color.b, 0.35)
	line_r.add_theme_stylebox_override("separator", sr)
	row.add_child(line_r)

	return row


func _top_vsep() -> VSeparator:
	var sep := VSeparator.new()
	sep.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sep.custom_minimum_size = Vector2(2, 0)
	var style := StyleBoxLine.new()
	style.color = color_border
	style.grow_begin = 8
	style.grow_end = 8
	sep.add_theme_stylebox_override("separator", style)
	return sep


func _add_top_warnings() -> void:
	var daily_need := game.citizens.size() * 20
	var food := game.total_food()
	var shown := 0

	if food < daily_need:
		_add_top_warning_chip("Food critical", Color(0.80, 0.38, 0.30))
		shown += 1
	elif food < daily_need * 2:
		_add_top_warning_chip("Food low", Color(0.82, 0.68, 0.30))
		shown += 1

	if shown < 2:
		var wh_cap := game.storage_capacity("WAREHOUSE")
		if wh_cap > 0 and game.warehouse_fullness() * 100 / wh_cap >= 90:
			_add_top_warning_chip("Storage full", Color(0.82, 0.68, 0.30))
			shown += 1

	if shown < 2:
		var barn_cap := game.storage_capacity("BARN")
		if barn_cap > 0 and food * 100 / barn_cap >= 90:
			_add_top_warning_chip("Barn full", Color(0.82, 0.68, 0.30))


func _add_top_warning_chip(text: String, warn_color: Color) -> void:
	var chip := PanelContainer.new()
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_panel(chip, Color(0.24, 0.18, 0.13), warn_color, 1, "warning")
	resource_row.add_child(chip)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 4)
	chip.add_child(margin)

	margin.add_child(_label("! " + text, 11, warn_color))


func _style_time_button(button: Button, active: bool, is_pause: bool) -> void:
	button.add_theme_color_override("font_hover_color", color_text)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	if is_pause and active:
		button.add_theme_color_override("font_color", Color(0.88, 0.58, 0.52))
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _warning_chip_style())
		button.add_theme_stylebox_override("hover", _warning_chip_style())
		button.add_theme_stylebox_override("pressed", _warning_chip_style())
	elif active:
		button.add_theme_color_override("font_color", color_text)
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", _button_style(true))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.add_theme_stylebox_override("pressed", _button_style(true))
	else:
		button.add_theme_color_override("font_color", color_muted)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _button_style(false))
		button.add_theme_stylebox_override("hover", _button_style(true))
		button.add_theme_stylebox_override("pressed", _button_style(true))


func _add_detail_row(title: String, value: String, value_color: Color = Color(-1, -1, -1)) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_content.add_child(row)

	var left := _label(title, 13, color_muted)
	left.custom_minimum_size.x = 86
	row.add_child(left)

	var right := _label(value, 13, color_text if value_color.r < 0.0 else value_color)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)


func _add_sidebar_action(parent: BoxContainer, text: String, callback: Callable, enabled: bool, primary: bool = false) -> void:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.custom_minimum_size.y = 38
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if enabled:
		button.pressed.connect(callback)
	_style_button(button, primary and enabled)
	if not enabled:
		button.add_theme_color_override("font_color", Color(0.42, 0.40, 0.35))
		button.add_theme_stylebox_override("disabled", _button_style(false))
	parent.add_child(button)


func _select_section(section: String) -> void:
	if selected_section == "Build" and section != "Build" and placement_state != null:
		placement_state.cancel()
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

	_style_time_button(time_buttons["Pause"], not game.running, true)
	for speed in [1, 2, 3]:
		if time_buttons.has(speed):
			_style_time_button(time_buttons[speed], game.running and time_scale == speed, false)


func _update_nav_buttons() -> void:
	if Engine.is_editor_hint():
		return
	for child in bottom_nav.get_children():
		var button := child as Button
		if button == null:
			continue
		var section := str(button.get_meta("section", ""))
		_style_button(button, section == selected_section)


func _nav_button(text: String) -> Button:
	var button := Button.new()
	_setup_nav_button(button, text)
	return button


func _setup_nav_button(button: Button, section: String) -> void:
	button.set_meta("section", section)
	var callback := _select_section.bind(section)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if Engine.is_editor_hint():
		return
	button.text = section.to_upper()
	if button.custom_minimum_size.x <= 0.0:
		button.custom_minimum_size.x = 100.0
	if button.custom_minimum_size.y <= 0.0:
		button.custom_minimum_size.y = 56.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	_style_button(button, section == selected_section)


func _time_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(54, 0)
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_button(button, false)
	return button


func _style_button(button: Button, active: bool) -> void:
	button.add_theme_color_override("font_color", color_text if active else color_muted)
	button.add_theme_color_override("font_hover_color", color_text)
	button.add_theme_font_size_override("font_size", 14)
	if button.has_meta("section"):
		button.add_theme_stylebox_override("normal", _tab_style(active))
		button.add_theme_stylebox_override("hover", _tab_style(true))
		button.add_theme_stylebox_override("pressed", _tab_style(true))
	else:
		button.add_theme_stylebox_override("normal", _button_style(active))
		button.add_theme_stylebox_override("hover", _button_style(active))
		button.add_theme_stylebox_override("pressed", _button_style(active))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _button_style(primary: bool) -> StyleBox:
	if primary:
		return _texture_style(UI_BUTTON_PRIMARY, 12, 12, UI_BUTTON_PRIMARY_REGION)
	return _texture_style(UI_BUTTON_SECONDARY, 12, 12)


func _tab_style(active: bool) -> StyleBox:
	return _texture_style(UI_TAB_ACTIVE if active else UI_TAB_INACTIVE, 12, 10)


func _chip_style() -> StyleBox:
	return _texture_style(UI_CHIP, 10, 8)


func _warning_chip_style() -> StyleBox:
	return _texture_style(UI_WARNING_CHIP, 10, 8)


func _style_placement_cell(button: Button, valid: bool, selected: bool, placement: Dictionary = {}) -> void:
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_hover_color", color_text)
	var occupied := not placement.is_empty()
	var fill: Color
	var border: Color
	var border_width := 1
	var font_color := color_text

	if not occupied:
		if _is_placing_build() and selected:
			fill = Color(0.17, 0.27, 0.15)
			border = Color(0.34, 0.70, 0.26)
			border_width = 2
			font_color = Color(0.70, 0.92, 0.60)
		else:
			fill = Color(0.12, 0.14, 0.12)
			border = Color(0.19, 0.22, 0.18)
			font_color = Color(0.28, 0.32, 0.26)
	else:
		var tile := PlacedBuildingPresenterScript.tile(game, placement)
		var under_construction := bool(tile.get("under_construction", false))
		var cat := str(tile.get("category_key", ""))
		var cat_fill := _cell_category_fill(cat)
		var cat_border := _cell_category_border(cat)

		if _is_placing_build():
			fill = Color(0.22, 0.12, 0.11)
			border = Color(0.62, 0.20, 0.16)
			font_color = Color(0.74, 0.44, 0.42)
		elif under_construction:
			fill = Color(cat_fill.r * 0.78 + 0.08, cat_fill.g * 0.78 + 0.05, cat_fill.b * 0.78 + 0.02)
			border = color_accent
			border_width = 2
			font_color = color_accent
		else:
			fill = cat_fill
			border = cat_border
			font_color = color_text

		if selected and not _is_placing_build():
			border = color_accent
			border_width = 3
			fill = Color(fill.r + 0.06, fill.g + 0.05, fill.b + 0.04)

	button.add_theme_color_override("font_color", font_color)
	button.add_theme_stylebox_override("normal", _flat_style(fill, border, border_width))
	button.add_theme_stylebox_override("hover", _flat_style(
		Color(fill.r + 0.05, fill.g + 0.05, fill.b + 0.05), border, border_width))
	button.add_theme_stylebox_override("pressed", _flat_style(fill, border, border_width))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _add_staffing_indicator(button: Button, placement: Dictionary) -> void:
	if placement.is_empty() or _is_placing_build():
		return
	var tile := PlacedBuildingPresenterScript.tile(game, placement)
	if not bool(tile.get("has_workers", false)) or bool(tile.get("under_construction", false)):
		return
	var workers := int(tile.get("workers", 0))
	var capacity := int(tile.get("capacity", 0))
	if capacity <= 0:
		return

	var dot_label := Label.new()
	dot_label.text = _staffing_dots(workers, capacity)
	dot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot_label.add_theme_font_size_override("font_size", 10)
	dot_label.add_theme_color_override("font_color", _staffing_dot_color(workers, capacity))
	dot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot_label.anchor_left = 0.0
	dot_label.anchor_right = 1.0
	dot_label.anchor_top = 1.0
	dot_label.anchor_bottom = 1.0
	dot_label.offset_left = 1
	dot_label.offset_right = -1
	dot_label.offset_top = -13
	dot_label.offset_bottom = -1
	button.add_child(dot_label)


func _staffing_dots(workers: int, capacity: int) -> String:
	if capacity > 5:
		return "%s/%s" % [workers, capacity]
	var result := ""
	for i in capacity:
		result += "●" if i < workers else "○"
	return result


func _staffing_dot_color(workers: int, capacity: int) -> Color:
	if workers <= 0:
		return color_muted
	if workers >= capacity:
		return Color(0.52, 0.74, 0.38)
	return color_accent


func _flat_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style


func _cell_category_fill(category: String) -> Color:
	match category:
		"food":     return Color(0.14, 0.22, 0.13)
		"industry": return Color(0.20, 0.18, 0.14)
		"craft":    return Color(0.13, 0.16, 0.22)
		"town":     return Color(0.18, 0.14, 0.22)
		"storage":  return Color(0.22, 0.18, 0.12)
	return Color(0.18, 0.17, 0.14)


func _cell_category_border(category: String) -> Color:
	match category:
		"food":     return Color(0.28, 0.52, 0.22)
		"industry": return Color(0.46, 0.40, 0.26)
		"craft":    return Color(0.26, 0.42, 0.58)
		"town":     return Color(0.42, 0.28, 0.58)
		"storage":  return Color(0.52, 0.42, 0.20)
	return Color(0.38, 0.34, 0.25)


func _style_panel(panel: PanelContainer, fill: Color, border: Color, border_width: int, skin: String = "inner") -> void:
	if skin == "outer":
		panel.add_theme_stylebox_override("panel", _texture_style(UI_PANEL_OUTER, 24, 16, UI_PANEL_OUTER_REGION))
		return
	if skin == "chip":
		panel.add_theme_stylebox_override("panel", _chip_style())
		return
	if skin == "warning":
		panel.add_theme_stylebox_override("panel", _warning_chip_style())
		return
	if skin == "inner":
		panel.add_theme_stylebox_override("panel", _texture_style(UI_PANEL_INNER, 12, 10))
		return

	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)


func _texture_style(texture: Texture2D, texture_margin: int, content_margin: int, region: Rect2 = Rect2()) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	if region.size.x > 0 and region.size.y > 0:
		style.region_rect = region
	style.draw_center = true
	style.texture_margin_left = texture_margin
	style.texture_margin_top = texture_margin
	style.texture_margin_right = texture_margin
	style.texture_margin_bottom = texture_margin
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style


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
