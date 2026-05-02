extends RefCounted
class_name BuildCatalog


static func entries(game: GameState) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	_add_category(result, game.industry_buildings, "industry", "Natural Resources", "Gather raw materials for the settlement.")
	_add_category(result, game.food_buildings, "food", "Food", "Produce and gather food for citizens.")
	_add_category(result, game.craft_buildings, "craft", "Production", "Turn inputs into crafted goods.")
	_add_category(result, game.town_services, "town", "Town Services", "Support housing, health, happiness, and safety.")
	_add_category(result, game.storages, "storage", "Storage", "Increase resource storage capacity.")
	return result


static func _add_category(result: Array[Dictionary], source: Array, category: String, label: String, category_description: String) -> void:
	for index in source.size():
		var building: Dictionary = source[index]
		result.append({
			"id": "%s:%s" % [category, index],
			"category": category,
			"category_label": label,
			"category_description": category_description,
			"index": index,
			"name": str(building.get("name", "Unknown")),
			"description": _description_for(category, building),
			"capacity": _capacity_text(building),
			"output": _output_text(category, building),
			"cost": _cost_text(building),
			"status": _status_text(building),
			"quantity": int(building.get("quantity", 0))
		})


static func _description_for(category: String, building: Dictionary) -> String:
	if category == "industry":
		return "Workplace for collecting %s." % _title_case(str(building.get("output", "raw resources")))
	if category == "food":
		return "Food workplace that supports daily survival and storage."
	if category == "craft":
		return "Production building for crafted settlement goods."
	if category == "town":
		var effect := str(building.get("effect", "service"))
		return "Town service providing %s support." % effect
	return "Storage building for increasing resource capacity."


static func _capacity_text(building: Dictionary) -> String:
	if building.has("capacity_per_building"):
		return "%s workers per building" % int(building.capacity_per_building)
	if building.has("capacity"):
		return "Capacity %s" % int(building.capacity)
	return "No worker role"


static func _output_text(category: String, building: Dictionary) -> String:
	if building.has("output"):
		return _title_case(str(building.output))
	if building.has("outputs"):
		var names: Array[String] = []
		for output in building.outputs:
			names.append(_title_case(str(output.get("name", ""))))
		return _join_strings(names, ", ")
	if building.has("products"):
		var products: Array[String] = []
		for product in building.products:
			products.append(_title_case(str(product.get("name", ""))))
		return _join_strings(products, ", ")
	if category == "town":
		return _title_case(str(building.get("effect", "service")))
	if building.has("capacity_per_building"):
		return "Storage capacity"
	return "None"


static func _cost_text(building: Dictionary) -> String:
	if building.has("build_cost"):
		return _format_costs(building.build_cost)
	return "Uses Wood + Stone during construction"


static func _status_text(building: Dictionary) -> String:
	if bool(building.get("building", false)):
		return "Under construction %s/80" % int(building.get("build_progress", 0))
	return "Owned: %s" % int(building.get("quantity", 0))


static func _format_costs(costs: Array) -> String:
	var parts: Array[String] = []
	for cost in costs:
		parts.append("%s %s" % [int(cost.get("count", 0)), _title_case(str(cost.get("name", "")))])
	return _join_strings(parts, ", ")


static func _title_case(value: String) -> String:
	var pieces := value.replace("_", " ").split(" ", false)
	var words: Array[String] = []
	for word in pieces:
		words.append(str(word).capitalize())
	return _join_strings(words, " ")


static func _join_strings(parts: Array, separator: String) -> String:
	var result := ""
	for i in parts.size():
		if i > 0:
			result += separator
		result += str(parts[i])
	return result
