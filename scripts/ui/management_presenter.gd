static func overview(game: GameState) -> Dictionary:
	var free := game.free_citizens()
	var builders := 0
	var assigned := 0
	for citizen in game.citizens:
		var wa := str(citizen.get("workarea", "unemployed"))
		if wa.begins_with("builder:"):
			builders += 1
		elif wa != "unemployed":
			assigned += 1
	return {
		"date": "Day %s  ·  Month %s  ·  Year %s" % [game.day, game.month, game.year],
		"population": game.citizens.size(),
		"free": free,
		"assigned": assigned,
		"builders": builders,
		"global_health": game.global_health(),
		"global_happiness": game.global_happiness(),
		"total_food": game.total_food(),
		"barn_capacity": game.storage_capacity("BARN"),
		"warehouse_fill": game.warehouse_fullness(),
		"warehouse_capacity": game.storage_capacity("WAREHOUSE"),
	}


static func status_items(game: GameState) -> Array:
	var result: Array = []

	# Construction
	var con_count := _construction_count(game)
	if con_count > 0:
		var plural := "s" if con_count != 1 else ""
		result.append({"label": "Construction", "value": "%s building%s in progress" % [con_count, plural], "level": "active"})
	else:
		result.append({"label": "Construction", "value": "No active construction", "level": "ok"})

	# Workforce
	var free_w := game.free_citizens()
	var total_w := game.citizens.size()
	if free_w == total_w:
		result.append({"label": "Workforce", "value": "All workers idle", "level": "warning"})
	elif free_w == 0:
		result.append({"label": "Workforce", "value": "All assigned", "level": "ok"})
	else:
		result.append({"label": "Workforce", "value": "%s free worker%s" % [free_w, "s" if free_w != 1 else ""], "level": "active"})

	# Food supply
	var food := game.total_food()
	var barn_cap := game.storage_capacity("BARN")
	var daily_need := game.citizens.size() * 20
	if food < daily_need:
		result.append({"label": "Food Supply", "value": "Critical — less than 1 day left", "level": "critical"})
	elif food < daily_need * 3:
		result.append({"label": "Food Supply", "value": "Low — %s in stock" % food, "level": "warning"})
	else:
		result.append({"label": "Food Supply", "value": "Stable — %s / %s" % [food, barn_cap], "level": "ok"})

	# Storage pressure (worst of barn/warehouse)
	var barn_pct := int(food * 100 / maxi(barn_cap, 1))
	var wh_pct := int(game.warehouse_fullness() * 100 / maxi(game.storage_capacity("WAREHOUSE"), 1))
	var peak_pct := maxi(barn_pct, wh_pct)
	if peak_pct >= 90:
		result.append({"label": "Storage", "value": "Near full — production blocked", "level": "warning"})
	elif peak_pct >= 70:
		result.append({"label": "Storage", "value": "Near capacity — watch levels", "level": "active"})
	else:
		result.append({"label": "Storage", "value": "Healthy", "level": "ok"})

	# Citizen welfare
	var health := game.global_health()
	var happiness := game.global_happiness()
	if health < 40 or happiness < 40:
		result.append({"label": "Welfare", "value": "Declining — H:%s%%  J:%s%%" % [health, happiness], "level": "critical"})
	elif health < 60 or happiness < 60:
		result.append({"label": "Welfare", "value": "Needs attention — H:%s%%  J:%s%%" % [health, happiness], "level": "warning"})
	else:
		result.append({"label": "Welfare", "value": "Good — H:%s%%  J:%s%%" % [health, happiness], "level": "ok"})

	return result


static func warnings(game: GameState) -> Array:
	var result: Array = []

	var free := game.free_citizens()
	if free > 0:
		result.append("%s worker%s without assignments" % [free, "s" if free != 1 else ""])

	var barn_pct := int(game.total_food() * 100 / maxi(game.storage_capacity("BARN"), 1))
	if barn_pct >= 90:
		result.append("Barn at %s%% — food production may be blocked" % barn_pct)

	var wh_pct := int(game.warehouse_fullness() * 100 / maxi(game.storage_capacity("WAREHOUSE"), 1))
	if wh_pct >= 90:
		result.append("Warehouse at %s%% — industry may be blocked" % wh_pct)

	var daily_need := game.citizens.size() * 20
	if game.total_food() < daily_need:
		result.append("Food critical — citizens are going hungry")

	return result


static func _construction_count(game: GameState) -> int:
	var count := 0
	for list in [game.industry_buildings, game.food_buildings, game.craft_buildings, game.town_services, game.storages]:
		for building in list:
			if building.get("building", false):
				count += 1
	return count
