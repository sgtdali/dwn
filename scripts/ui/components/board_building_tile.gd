extends Button

@onready var name_label: Label = %NameLabel
@onready var state_label: Label = %StateLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var staff_label: Label = %StaffLabel


func configure_empty(is_target: bool, text_color: Color, muted_color: Color) -> void:
	_bind_nodes()
	name_label.text = "Place" if is_target else ""
	state_label.text = ""
	progress_bar.visible = false
	staff_label.text = ""
	name_label.add_theme_color_override("font_color", text_color)
	state_label.add_theme_color_override("font_color", muted_color)
	staff_label.add_theme_color_override("font_color", muted_color)


func configure_placed(tile: Dictionary, blocked: bool, text_color: Color, muted_color: Color, accent_color: Color) -> void:
	_bind_nodes()
	name_label.text = str(tile.get("name", "Building"))
	if blocked:
		state_label.text = "Blocked"
	elif bool(tile.get("under_construction", false)):
		state_label.text = str(tile.get("progress_text", "0%"))
	else:
		state_label.text = str(tile.get("state", "Ready"))

	progress_bar.visible = bool(tile.get("under_construction", false))
	progress_bar.value = float(tile.get("progress_percent", 0))
	staff_label.text = _staff_text(tile)

	name_label.add_theme_color_override("font_color", text_color)
	state_label.add_theme_color_override("font_color", accent_color if bool(tile.get("under_construction", false)) else muted_color)
	staff_label.add_theme_color_override("font_color", muted_color)


func _staff_text(tile: Dictionary) -> String:
	var workers := int(tile.get("workers", 0))
	var builders := int(tile.get("builders", 0))
	if workers <= 0 and builders <= 0:
		return ""
	var parts: Array[String] = []
	if workers > 0:
		parts.append("W:%s" % workers)
	if builders > 0:
		parts.append("B:%s" % builders)
	var result := ""
	for i in parts.size():
		if i > 0:
			result += " "
		result += parts[i]
	return result


func _bind_nodes() -> void:
	if name_label == null:
		name_label = get_node("%NameLabel") as Label
	if state_label == null:
		state_label = get_node("%StateLabel") as Label
	if progress_bar == null:
		progress_bar = get_node("%ProgressBar") as ProgressBar
	if staff_label == null:
		staff_label = get_node("%StaffLabel") as Label
