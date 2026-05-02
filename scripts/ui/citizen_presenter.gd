static func present(citizen: Dictionary) -> Dictionary:
	var workarea: String = str(citizen.get("workarea", "unemployed"))
	var status: String
	var workarea_label: String
	if workarea == "unemployed":
		status = "Free"
		workarea_label = "Unemployed"
	elif workarea.begins_with("builder:"):
		status = "Building"
		workarea_label = "Building: " + workarea.substr(8)
	else:
		status = "Working"
		workarea_label = workarea
	return {
		"id": int(citizen.get("id", 0)),
		"name": str(citizen.get("name", "Unknown")),
		"status": status,
		"workarea_label": workarea_label,
		"health": int(citizen.get("health", 0)),
		"happiness": int(citizen.get("happiness", 0)),
		"efficiency": int(citizen.get("efficiency", 0)),
		"age": int(citizen.get("age", 0)),
		"hunger": citizen.get("hunger", false),
		"shelter": citizen.get("shelter", false),
	}

static func present_all(game: GameState) -> Array:
	var result: Array = []
	for citizen in game.citizens:
		result.append(present(citizen))
	return result
