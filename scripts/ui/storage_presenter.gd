static func barn_summary(game: GameState) -> Dictionary:
	var current := game.total_food()
	var capacity := game.storage_capacity("BARN")
	var pct := int(current * 100 / capacity) if capacity > 0 else 0
	return {
		"name": "BARN",
		"label": "Barn",
		"role": "Food storage",
		"current": current,
		"capacity": capacity,
		"fill_pct": pct,
		"fill_status": _fill_status(pct),
	}


static func warehouse_summary(game: GameState) -> Dictionary:
	var current := game.warehouse_fullness()
	var capacity := game.storage_capacity("WAREHOUSE")
	var pct := int(current * 100 / capacity) if capacity > 0 else 0
	return {
		"name": "WAREHOUSE",
		"label": "Warehouse",
		"role": "Industry & Crafting",
		"current": current,
		"capacity": capacity,
		"fill_pct": pct,
		"fill_status": _fill_status(pct),
	}


static func resource_rows(game: GameState) -> Array:
	var barn_current := game.total_food()
	var barn_cap := game.storage_capacity("BARN")
	var barn_pct := int(barn_current * 100 / barn_cap) if barn_cap > 0 else 0

	var wh_current := game.warehouse_fullness()
	var wh_cap := game.storage_capacity("WAREHOUSE")
	var wh_pct := int(wh_current * 100 / wh_cap) if wh_cap > 0 else 0

	var result: Array = []

	for key in game.food_resources.keys():
		result.append({
			"id": "food:%s" % key,
			"name": _title_case(key),
			"category": "food",
			"category_label": "Food",
			"amount": int(game.food_resources[key]),
			"storage_label": "Barn",
			"storage_current": barn_current,
			"storage_capacity": barn_cap,
			"storage_fill_pct": barn_pct,
			"storage_fill_status": _fill_status(barn_pct),
		})

	for key in game.industry_resources.keys():
		result.append({
			"id": "industry:%s" % key,
			"name": _title_case(key),
			"category": "industry",
			"category_label": "Industry",
			"amount": int(game.industry_resources[key]),
			"storage_label": "Warehouse",
			"storage_current": wh_current,
			"storage_capacity": wh_cap,
			"storage_fill_pct": wh_pct,
			"storage_fill_status": _fill_status(wh_pct),
		})

	for key in game.crafted_resources.keys():
		result.append({
			"id": "crafted:%s" % key,
			"name": _title_case(key),
			"category": "crafted",
			"category_label": "Crafted",
			"amount": int(game.crafted_resources[key]),
			"storage_label": "Warehouse",
			"storage_current": wh_current,
			"storage_capacity": wh_cap,
			"storage_fill_pct": wh_pct,
			"storage_fill_status": _fill_status(wh_pct),
		})

	return result


static func _fill_status(pct: int) -> String:
	if pct >= 95:
		return "Full"
	if pct >= 75:
		return "Near Full"
	if pct >= 20:
		return "Healthy"
	if pct > 0:
		return "Low"
	return "Empty"


static func _title_case(text: String) -> String:
	var words := text.split(" ")
	var result := ""
	for word in words:
		if word.length() > 0:
			result += word.substr(0, 1).to_upper() + word.substr(1).to_lower() + " "
	return result.strip_edges()
