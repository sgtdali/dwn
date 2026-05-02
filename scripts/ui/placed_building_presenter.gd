extends RefCounted
class_name PlacedBuildingPresenter

const WorkforcePresenterScript := preload("res://scripts/ui/workforce_presenter.gd")


static func tile(game: GameState, placement: Dictionary) -> Dictionary:
	var building := _building_data(game, placement)
	var state := _state_text(building)
	var capacity := _capacity(building)
	var workers := int(building.get("workers", 0)) if building.has("workers") else 0
	var progress := int(building.get("build_progress", 0))
	var progress_percent := clampi(roundi(progress / 80.0 * 100.0), 0, 100)
	var category_key := str(placement.get("category", ""))
	var index := int(placement.get("index", -1))
	var builders := game.builder_count_for(category_key, index)
	var under_construction := bool(building.get("building", false))
	var workforce := WorkforcePresenterScript.summary(game)
	var free_workers := int(workforce.free)
	return {
		"name": _short_name(str(placement.get("name", "Building"))),
		"full_name": str(placement.get("name", "Building")),
		"category_key": category_key,
		"category": _category_label(category_key),
		"index": index,
		"position": Vector2i(int(placement.get("x", -1)), int(placement.get("y", -1))),
		"state": state,
		"under_construction": under_construction,
		"progress": progress,
		"progress_max": 80,
		"progress_percent": progress_percent,
		"progress_text": "%s%%" % progress_percent,
		"builders": builders,
		"can_assign_builder": under_construction and free_workers > 0,
		"can_remove_builder": under_construction and builders > 0,
		"construction_status": _construction_status(under_construction, builders, free_workers),
		"has_workers": building.has("workers"),
		"workers": workers,
		"capacity": capacity,
		"output": _output_text(building),
		"can_assign_worker": building.has("workers") and workers < capacity and free_workers > 0,
		"can_remove_worker": building.has("workers") and workers > 0
	}


static func _building_data(game: GameState, placement: Dictionary) -> Dictionary:
	var list: Array = []
	var category := str(placement.get("category", ""))
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

	var index := int(placement.get("index", -1))
	if index < 0 or index >= list.size():
		return {}
	return list[index]


static func _state_text(building: Dictionary) -> String:
	if building.is_empty():
		return "Unknown"
	if bool(building.get("building", false)):
		var progress := int(building.get("build_progress", 0))
		var percent := clampi(roundi(progress / 80.0 * 100.0), 0, 100)
		return "Building %s%%" % percent
	return "Ready"


static func _construction_status(under_construction: bool, builders: int, free_workers: int) -> String:
	if not under_construction:
		return "Construction complete."
	if builders > 0:
		return "Construction active."
	if free_workers <= 0:
		return "Construction paused: no free workers available."
	return "Construction paused: no builders assigned."


static func _capacity(building: Dictionary) -> int:
	if building.has("capacity_per_building"):
		return int(building.get("quantity", 0)) * int(building.get("capacity_per_building", 0))
	if building.has("capacity"):
		return int(building.get("capacity", 0))
	return 0


static func _output_text(building: Dictionary) -> String:
	if building.has("output"):
		return str(building.output).capitalize()
	if building.has("outputs"):
		var names: Array[String] = []
		for output in building.outputs:
			names.append(str(output.get("name", "")).capitalize())
		return _join_strings(names, ", ")
	if building.has("products"):
		var products: Array[String] = []
		for product in building.products:
			products.append(str(product.get("name", "")).capitalize())
		return _join_strings(products, ", ")
	if building.has("effect"):
		return str(building.effect).capitalize()
	if building.has("capacity_per_building"):
		return "Storage"
	return "None"


static func _category_label(category: String) -> String:
	if category == "industry":
		return "Natural Resources"
	if category == "food":
		return "Food"
	if category == "craft":
		return "Production"
	if category == "town":
		return "Town Service"
	if category == "storage":
		return "Storage"
	return "Unknown"


static func _short_name(value: String) -> String:
	if value.length() <= 13:
		return value
	return "%s..." % value.substr(0, 10)


static func _join_strings(parts: Array, separator: String) -> String:
	var result := ""
	for i in parts.size():
		if i > 0:
			result += separator
		result += str(parts[i])
	return result
