extends RefCounted
class_name WorkforcePresenter


static func summary(game: GameState) -> Dictionary:
	var total := game.citizens.size()
	var free := 0
	var builders := 0
	var assigned_workers := 0

	for citizen in game.citizens:
		var workarea := str(citizen.get("workarea", "unemployed"))
		if workarea == "unemployed":
			free += 1
		elif workarea.begins_with("builder:"):
			builders += 1
		else:
			assigned_workers += 1

	return {
		"total": total,
		"free": free,
		"assigned_workers": assigned_workers,
		"builders": builders,
		"assigned_total": assigned_workers + builders
	}


static func free_text(game: GameState) -> String:
	var data := summary(game)
	return "Free workers available: %s" % int(data.free)


static func assignment_blocked_text(game: GameState) -> String:
	var data := summary(game)
	if int(data.free) <= 0:
		return "No free workers available."
	return "Free workers available: %s" % int(data.free)
