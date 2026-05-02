static func present_events(game: GameState) -> Array:
	var result: Array = []
	for raw in game.events:
		var text := str(raw)
		var category := _categorize(text)
		result.append({
			"text": text,
			"category": category,
			"category_label": _category_label(category),
		})
	return result


static func _categorize(text: String) -> String:
	if "construction started" in text:
		return "construction"
	if text.ends_with(" completed."):
		return "construction"
	if text.ends_with(" demolished."):
		return "construction"
	if "Gatherers found" in text:
		return "production"
	return "general"


static func _category_label(category: String) -> String:
	match category:
		"construction": return "Build"
		"production": return "Gather"
	return "—"
