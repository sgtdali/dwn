extends RefCounted
class_name BuildPlacementState

var active := false
var selected_entry: Dictionary = {}
var target_cell := Vector2i(-1, -1)
var target_valid := false
var message := "Select a building."


func prepare(entry: Dictionary) -> void:
	active = true
	selected_entry = entry.duplicate(true)
	target_cell = Vector2i(-1, -1)
	target_valid = false
	message = "Select location."


func cancel() -> void:
	active = false
	target_cell = Vector2i(-1, -1)
	target_valid = false
	message = "Placement cancelled."


func confirm() -> void:
	active = false
	target_cell = Vector2i(-1, -1)
	target_valid = false
	message = "Construction started."


func target(x: int, y: int, valid: bool) -> void:
	target_cell = Vector2i(x, y)
	target_valid = valid
	message = "Confirm placement." if valid else "Cell occupied."


func selected_name() -> String:
	return str(selected_entry.get("name", "No building selected"))


func has_selection() -> bool:
	return not selected_entry.is_empty()


func has_valid_target() -> bool:
	return target_cell.x >= 0 and target_cell.y >= 0 and target_valid
