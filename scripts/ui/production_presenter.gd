static func present_buildings(game: GameState) -> Array:
	var result: Array = []
	for i in game.industry_buildings.size():
		result.append(_present(game, "industry", i, game.industry_buildings[i]))
	for i in game.food_buildings.size():
		result.append(_present(game, "food", i, game.food_buildings[i]))
	for i in game.craft_buildings.size():
		result.append(_present(game, "craft", i, game.craft_buildings[i]))
	return result


static func _present(game: GameState, category: String, index: int, building: Dictionary) -> Dictionary:
	var status := _derive_status(category, building)
	var workers := int(building.get("workers", 0))
	var quantity := int(building.get("quantity", 1))
	var cap_per := int(building.get("capacity_per_building", 2))
	var build_prog := int(building.get("build_progress", 0))
	return {
		"id": "%s:%s" % [category, index],
		"name": str(building.get("name", "Unknown")),
		"category": category,
		"category_label": _category_label(category),
		"workers": workers,
		"capacity": quantity * cap_per,
		"status": status,
		"filter_key": _filter_key(status),
		"output_label": _output_label(category, building),
		"last_label": _last_label(category, building),
		"under_construction": bool(building.get("building", false)),
		"build_percent": int(build_prog * 100 / 80),
		"quantity": quantity,
		"position_label": _placement_label(game, str(building.get("name", ""))),
	}


static func _derive_status(category: String, building: Dictionary) -> String:
	if building.get("building", false):
		var pct := int(int(building.get("build_progress", 0)) * 100 / 80)
		return "Building %s%%" % pct

	var workers := int(building.get("workers", 0))
	if workers <= 0:
		return "No Workers"

	var last = building.get("last", 0)
	if typeof(last) == TYPE_STRING:
		var s := str(last)
		if s == "STORAGE FULL":
			return "Storage Full"
		if s == "NO INPUT":
			return "No Input"
		if s.begins_with("IN PROGRESS"):
			return "Crafting"
		if s != "" and s != "0":
			return "Producing"
	elif last > 0:
		return "Producing"

	if category == "industry" and building.get("harvest", false):
		return "Harvesting"

	return "Idle"


static func _filter_key(status: String) -> String:
	if status == "Producing" or status == "Crafting" or status == "Harvesting":
		return "Producing"
	if status == "No Workers":
		return "No Workers"
	if status.begins_with("Building"):
		return "Building"
	return "Idle"


static func _last_label(category: String, building: Dictionary) -> String:
	var last = building.get("last", 0)
	if typeof(last) == TYPE_STRING:
		var s := str(last)
		if s == "STORAGE FULL":
			return "Storage Full"
		if s == "NO INPUT":
			return "No Input"
		if s.begins_with("IN PROGRESS"):
			return s.replace("IN PROGRESS ", "")
		if s != "" and s != "0":
			return s
		return ""
	if last > 0:
		if category == "food":
			return "+%s food" % int(last)
		return "+%s" % int(last)
	return ""


static func _output_label(category: String, building: Dictionary) -> String:
	if category == "food":
		var outputs: Array = building.get("outputs", [])
		if outputs.size() == 1:
			return _title_case(str(outputs[0].get("name", "")))
		if outputs.size() > 1:
			return _title_case(str(outputs[0].get("name", ""))) + "…"
		return "—"
	if category == "craft":
		if building.get("one_output", true):
			return str(building.get("output", "—"))
		var products: Array = building.get("products", [])
		var selected := int(building.get("selected", 0))
		if selected < products.size():
			return str(products[selected].get("name", "—"))
		return "—"
	return str(building.get("output", "—"))


static func _placement_label(game: GameState, building_name: String) -> String:
	var positions: Array = []
	for placement in game.placed_buildings:
		if str(placement.get("name", "")) == building_name:
			positions.append("%s,%s" % [int(placement.get("x", 0)), int(placement.get("y", 0))])
	if positions.is_empty():
		return "—"
	if positions.size() == 1:
		return positions[0]
	return "%s +%s" % [positions[0], positions.size() - 1]


static func _category_label(category: String) -> String:
	match category:
		"industry": return "Resources"
		"food": return "Food"
		"craft": return "Crafting"
	return category


static func _title_case(text: String) -> String:
	var words := text.split(" ")
	var result := ""
	for word in words:
		if word.length() > 0:
			result += word.substr(0, 1).to_upper() + word.substr(1).to_lower() + " "
	return result.strip_edges()
