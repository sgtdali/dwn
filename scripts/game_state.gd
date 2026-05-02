extends Node
class_name GameState

signal changed

var day := 1
var month := 1
var year := 1
var running := false

var industry_resources := {
	"Wood": 80,
	"stone": 80,
	"coal": 0,
	"iron": 0,
	"tree": 25,
	"wool": 0,
	"leather": 0,
	"wheat": 0,
	"herb": 0
}

var food_resources := {
	"mushroom": 120,
	"deer meet": 30,
	"berries": 80,
	"fish": 0,
	"milk": 0,
	"cow meet": 0,
	"sheep meet": 0,
	"chicken meet": 0,
	"egg": 0,
	"apple": 0,
	"orange": 0,
	"corn": 0,
	"potato": 0,
	"tomato": 0,
	"cherry": 0,
	"walnut": 0
}

var crafted_resources := {
	"Firewood": 0,
	"Wooden Tool": 0,
	"Stone Tool": 0,
	"Leather Clothes": 0,
	"Wool Clothes": 0,
	"Warm Clothes": 0,
	"Iron Tool": 0,
	"Steel Tool": 0,
	"Beer": 0,
	"Flour": 0,
	"Bread": 0,
	"Horse": 0
}

var storages := [
	{"name": "BARN", "quantity": 1, "capacity_per_building": 1000, "build_progress": 0, "building": false},
	{"name": "WAREHOUSE", "quantity": 1, "capacity_per_building": 1000, "build_progress": 0, "building": false}
]

var industry_buildings := [
	{"name": "WOOD CAMP", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "Wood", "amount": 5, "harvest": false, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/woodcutter.png"},
	{"name": "STONECUTTER", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "stone", "amount": 5, "harvest": false, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/stone mining.png"},
	{"name": "COAL MINE", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "coal", "amount": 5, "harvest": false, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/coal mining.png"},
	{"name": "IRON MINE", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "iron", "amount": 5, "harvest": false, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/iron mining.png"},
	{"name": "FORESTER", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "tree", "amount": 5, "harvest": true, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/forester.png"},
	{"name": "HERBALIST", "quantity": 1, "capacity_per_building": 2, "workers": 0, "output": "herb", "amount": 5, "harvest": false, "progress": 0, "total": 10, "last": 0, "building": false, "build_progress": 0, "image": "natural_resources/herbalist.png"}
]

var food_buildings := [
	{"name": "GATHERER'S HUT", "quantity": 1, "capacity_per_building": 2, "workers": 0, "outputs": [{"name": "mushroom", "amount": 3, "type": "food"}, {"name": "berries", "amount": 2, "type": "food"}], "last": 0, "building": false, "build_progress": 0, "image": "food_buildings/gatherer hut.png"},
	{"name": "HUNTER'S CABIN", "quantity": 1, "capacity_per_building": 2, "workers": 0, "outputs": [{"name": "deer meet", "amount": 3, "type": "food"}, {"name": "leather", "amount": 2, "type": "industry"}], "last": 0, "building": false, "build_progress": 0, "image": "food_buildings/HuntingCabin.png"},
	{"name": "FARM FIELD", "quantity": 1, "capacity_per_building": 2, "workers": 0, "outputs": [{"name": "wheat", "amount": 3, "type": "industry"}, {"name": "corn", "amount": 2, "type": "food"}, {"name": "potato", "amount": 2, "type": "food"}, {"name": "tomato", "amount": 2, "type": "food"}], "last": 0, "building": false, "build_progress": 0, "image": "food_buildings/farm.png"},
	{"name": "ORCHARD", "quantity": 1, "capacity_per_building": 2, "workers": 0, "outputs": [{"name": "apple", "amount": 3, "type": "food"}, {"name": "cherry", "amount": 2, "type": "food"}, {"name": "walnut", "amount": 2, "type": "food"}, {"name": "orange", "amount": 2, "type": "food"}], "last": 0, "building": false, "build_progress": 0, "image": "food_buildings/orchard.png"},
	{"name": "FISHING DOCK", "quantity": 1, "capacity_per_building": 2, "workers": 0, "outputs": [{"name": "fish", "amount": 5, "type": "food"}], "last": 0, "building": false, "build_progress": 0, "image": "food_buildings/fishingson.png"}
]

var craft_buildings := [
	{"name": "FIREWOOD CAMP", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": true, "output": "Firewood", "amount": 5, "harvest": false, "progress": 0, "total": 10, "costs": [{"name": "Wood", "count": 3, "type": "industry"}], "last": 0, "building": false, "build_progress": 0, "image": "wood.png"},
	{"name": "WORKSHOP", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": false, "selected": 0, "amount": 1, "products": [{"name": "Wooden Tool", "progress": 0, "total": 10, "costs": [{"name": "Wood", "count": 3, "type": "industry"}]}, {"name": "Stone Tool", "progress": 0, "total": 10, "costs": [{"name": "Wood", "count": 3, "type": "industry"}, {"name": "stone", "count": 3, "type": "industry"}]}], "last": 0, "building": false, "build_progress": 0, "image": "workshop.png"},
	{"name": "TAILOR", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": false, "selected": 0, "amount": 1, "products": [{"name": "Leather Clothes", "progress": 0, "total": 10, "costs": [{"name": "leather", "count": 3, "type": "industry"}]}, {"name": "Wool Clothes", "progress": 0, "total": 10, "costs": [{"name": "wool", "count": 3, "type": "industry"}]}, {"name": "Warm Clothes", "progress": 0, "total": 10, "costs": [{"name": "leather", "count": 3, "type": "industry"}, {"name": "wool", "count": 3, "type": "industry"}]}], "last": 0, "building": false, "build_progress": 0, "image": "tailor.png"},
	{"name": "BLACKSMITH", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": false, "selected": 0, "amount": 5, "products": [{"name": "Iron Tool", "progress": 0, "total": 10, "costs": [{"name": "Wood", "count": 3, "type": "industry"}, {"name": "iron", "count": 3, "type": "industry"}]}, {"name": "Steel Tool", "progress": 0, "total": 10, "costs": [{"name": "iron", "count": 3, "type": "industry"}, {"name": "coal", "count": 3, "type": "industry"}]}], "last": 0, "building": false, "build_progress": 0, "image": "forge.png"},
	{"name": "BREWERY", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": true, "output": "Beer", "amount": 5, "harvest": false, "progress": 0, "total": 10, "costs": [{"name": "wheat", "count": 3, "type": "industry"}], "last": 0, "building": false, "build_progress": 0, "image": "brewery.png"},
	{"name": "MILL", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": true, "output": "Flour", "amount": 5, "harvest": false, "progress": 0, "total": 10, "costs": [{"name": "wheat", "count": 3, "type": "industry"}], "last": 0, "building": false, "build_progress": 0, "image": "workshop.png"},
	{"name": "BAKERY", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": true, "output": "Bread", "amount": 5, "harvest": false, "progress": 0, "total": 10, "costs": [{"name": "Flour", "count": 3, "type": "crafted"}], "last": 0, "building": false, "build_progress": 0, "image": "box.png"},
	{"name": "STABLE", "quantity": 1, "capacity_per_building": 2, "workers": 0, "one_output": true, "output": "Horse", "amount": 1, "harvest": true, "progress": 0, "total": 10, "costs": [{"name": "wheat", "count": 3, "type": "industry"}], "last": 0, "building": false, "build_progress": 0, "image": "stable.png"}
]

var town_services := [
	{"name": "HOUSE", "quantity": 10, "capacity": 3, "effect": "shelter", "building": false, "build_progress": 0, "image": "ev.png"},
	{"name": "CHURCH", "quantity": 1, "capacity": 2, "effect": "happiness", "building": false, "build_progress": 0, "image": "CHURCH.png"},
	{"name": "TAVERN", "quantity": 1, "capacity": 2, "effect": "happiness", "building": false, "build_progress": 0, "image": "tavern.png"},
	{"name": "HOSPITAL", "quantity": 1, "capacity": 2, "effect": "health", "building": false, "build_progress": 0, "image": "hospital.png"},
	{"name": "WELL", "quantity": 0, "capacity": 2, "effect": "fire", "building": false, "build_progress": 0, "image": "well.png"}
]

var citizens := [
	{"id": 1, "name": "Tayfun Vural", "workarea": "unemployed", "health": 75, "happiness": 60, "efficiency": 80, "age": 75, "hunger": true, "shelter": false},
	{"id": 2, "name": "Batuhan Ozdemir", "workarea": "unemployed", "health": 75, "happiness": 60, "efficiency": 80, "age": 20, "hunger": true, "shelter": false},
	{"id": 3, "name": "Murat Demir", "workarea": "unemployed", "health": 90, "happiness": 80, "efficiency": 70, "age": 40, "hunger": true, "shelter": false},
	{"id": 4, "name": "Elif Kaya", "workarea": "unemployed", "health": 75, "happiness": 60, "efficiency": 80, "age": 20, "hunger": true, "shelter": false},
	{"id": 5, "name": "Ayse Yilmaz", "workarea": "unemployed", "health": 60, "happiness": 80, "efficiency": 40, "age": 50, "hunger": true, "shelter": false}
]

var events := ["Town founded."]
var placed_buildings := []

func tick_day() -> void:
	day += 1
	if day > 3:
		day = 1
		month += 1
		if month > 12:
			month = 1
			year += 1
			for citizen in citizens:
				citizen.age += 1

	_collect_industry()
	_collect_food()
	_collect_crafting()
	_consume_food()
	_advance_construction()
	_update_citizens()
	_random_event()
	save_game()
	changed.emit()

func set_running(value: bool) -> void:
	running = value
	changed.emit()

func total_food() -> int:
	var total := 0
	for value in food_resources.values():
		total += int(value)
	return total

func warehouse_fullness() -> int:
	var total := 0
	for value in industry_resources.values():
		total += int(value)
	for value in crafted_resources.values():
		total += int(value)
	return total

func storage_capacity(name: String) -> int:
	for storage in storages:
		if storage.name == name:
			return storage.quantity * storage.capacity_per_building
	return 0

func free_citizens() -> int:
	var count := 0
	for citizen in citizens:
		if citizen.workarea == "unemployed":
			count += 1
	return count

func global_health() -> int:
	return _average("health")

func global_happiness() -> int:
	return _average("happiness")

func add_worker(category: String, index: int) -> void:
	var building: Dictionary = _building_list(category)[index]
	if building.workers >= _capacity(building):
		return
	var citizen: Variant = _first_unemployed()
	if citizen == null:
		return
	citizen.workarea = building.name
	building.workers += 1
	changed.emit()

func remove_worker(category: String, index: int) -> void:
	var building: Dictionary = _building_list(category)[index]
	if building.workers <= 0:
		return
	for citizen in citizens:
		if citizen.workarea == building.name:
			citizen.workarea = "unemployed"
			building.workers -= 1
			changed.emit()
			return

func start_build(category: String, index: int) -> void:
	var building: Dictionary = _building_list(category)[index]
	if building.building:
		return
	building.building = true
	building.build_progress = 0
	events.push_front("%s construction started." % building.name)
	changed.emit()

func can_place_building(x: int, y: int) -> bool:
	return _placement_at(x, y).is_empty()

func placement_at(x: int, y: int) -> Dictionary:
	return _placement_at(x, y)

func place_building(category: String, index: int, x: int, y: int) -> bool:
	if not can_place_building(x, y):
		return false

	if not _is_build_category(category):
		return false

	var list := _building_list(category)
	if index < 0 or index >= list.size():
		return false

	var building: Dictionary = list[index]
	placed_buildings.append({
		"category": category,
		"index": index,
		"name": str(building.get("name", "Unknown")),
		"x": x,
		"y": y
	})
	return true

func demolish_placed_building(x: int, y: int) -> bool:
	for i in placed_buildings.size():
		var placement: Dictionary = placed_buildings[i]
		if int(placement.get("x", -1)) != x or int(placement.get("y", -1)) != y:
			continue

		var category := str(placement.get("category", ""))
		var index := int(placement.get("index", -1))
		var list := _building_list(category) if _is_build_category(category) else []
		if index >= 0 and index < list.size():
			var building: Dictionary = list[index]
			if bool(building.get("building", false)):
				building.building = false
				building.build_progress = 0
			if building.has("workers"):
				_release_workers_for_building(str(building.get("name", "")))
				building.workers = 0

		placed_buildings.remove_at(i)
		events.push_front("%s demolished." % str(placement.get("name", "Building")))
		save_game()
		changed.emit()
		return true
	return false

func assign_builder(category: String, index: int) -> void:
	if not _is_build_category(category):
		return
	var list := _building_list(category)
	if index < 0 or index >= list.size():
		return
	var building: Dictionary = list[index]
	if not building.building:
		start_build(category, index)
	var citizen: Variant = _first_unemployed()
	if citizen == null:
		return
	citizen.workarea = "builder:%s" % building.name
	changed.emit()

func remove_builder(category: String, index: int) -> void:
	if not _is_build_category(category):
		return
	var list := _building_list(category)
	if index < 0 or index >= list.size():
		return
	var building: Dictionary = list[index]
	for citizen in citizens:
		if citizen.workarea == "builder:%s" % building.name:
			citizen.workarea = "unemployed"
			changed.emit()
			return

func builder_count_for(category: String, index: int) -> int:
	if not _is_build_category(category):
		return 0
	var list := _building_list(category)
	if index < 0 or index >= list.size():
		return 0
	return _builder_count(str(list[index].get("name", "")))

func select_craft_product(index: int, product_index: int) -> void:
	if index < 0 or index >= craft_buildings.size():
		return
	var building: Dictionary = craft_buildings[index]
	if not building.has("products"):
		return
	building.selected = clampi(product_index, 0, building.products.size() - 1)
	changed.emit()

func save_game() -> void:
	var data := {
		"date": {"day": day, "month": month, "year": year},
		"industry_resources": industry_resources,
		"food_resources": food_resources,
		"crafted_resources": crafted_resources,
		"industry_buildings": industry_buildings,
		"food_buildings": food_buildings,
		"craft_buildings": craft_buildings,
		"town_services": town_services,
		"storages": storages,
		"citizens": citizens,
		"events": events,
		"placed_buildings": placed_buildings
	}
	var file: FileAccess = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		changed.emit()
		return
	var file: FileAccess = FileAccess.open("user://savegame.json", FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	day = parsed.date.day
	month = parsed.date.month
	year = parsed.date.year
	industry_resources = parsed.industry_resources
	food_resources = parsed.food_resources
	if parsed.has("crafted_resources"):
		crafted_resources = parsed.crafted_resources
	if parsed.has("industry_buildings"):
		industry_buildings = parsed.industry_buildings
	if parsed.has("food_buildings"):
		food_buildings = parsed.food_buildings
	if parsed.has("craft_buildings"):
		craft_buildings = parsed.craft_buildings
	if parsed.has("town_services"):
		town_services = parsed.town_services
	if parsed.has("storages"):
		storages = parsed.storages
	if parsed.has("citizens"):
		citizens = parsed.citizens
	if parsed.has("events"):
		events = parsed.events
	if parsed.has("placed_buildings"):
		placed_buildings = parsed.placed_buildings
	changed.emit()

func reset_save() -> void:
	if FileAccess.file_exists("user://savegame.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://savegame.json"))
	events.push_front("Save cleared. Restart the scene for default data.")
	changed.emit()

func _collect_industry() -> void:
	for building in industry_buildings:
		building.last = 0
		if building.workers <= 0:
			continue
		if warehouse_fullness() >= storage_capacity("WAREHOUSE"):
			building.last = "STORAGE FULL"
			continue
		var amount: int = max(1, roundi(building.amount * _efficiency_for(building.name) / 100.0))
		if building.harvest:
			building.progress += 1
			if building.progress < building.total:
				continue
			building.progress = 0
		industry_resources[building.output] += amount
		building.last = amount

func _collect_food() -> void:
	for building in food_buildings:
		building.last = 0
		if building.workers <= 0:
			continue
		var efficiency: float = _efficiency_for(building.name)
		for output in building.outputs:
			var amount: int = max(1, roundi(output.amount * efficiency / 100.0))
			if output.type == "food":
				if total_food() < storage_capacity("BARN"):
					food_resources[output.name] += amount
					building.last += amount
			else:
				if warehouse_fullness() < storage_capacity("WAREHOUSE"):
					industry_resources[output.name] += amount
					building.last += amount

func _collect_crafting() -> void:
	for building in craft_buildings:
		building.last = 0
		if building.workers <= 0:
			continue
		if warehouse_fullness() >= storage_capacity("WAREHOUSE"):
			building.last = "STORAGE FULL"
			continue
		var product: Dictionary = _active_craft_product(building)
		var costs: Array = product.costs
		if not _can_pay_costs(costs, building.workers):
			building.last = "NO INPUT"
			continue
		if building.get("harvest", true):
			_increment_craft_progress(building, product)
			var progress: int = _craft_progress(building, product)
			if progress < product.total:
				building.last = "IN PROGRESS %s/%s" % [progress, product.total]
				continue
			_reset_craft_progress(building, product)
		var amount: int = max(1, roundi(building.amount * _efficiency_for(building.name) / 100.0))
		_pay_costs(costs, building.workers)
		crafted_resources[product.name] += amount
		building.last = "%s %s" % [amount, product.name]

func _consume_food() -> void:
	for citizen in citizens:
		if total_food() >= 20:
			_remove_food(20)
			citizen.hunger = false
			citizen.health = min(100, citizen.health + 5)
		else:
			citizen.hunger = true
			citizen.health = max(0, citizen.health - 10)

func _advance_construction() -> void:
	for list in [industry_buildings, food_buildings, craft_buildings, town_services, storages]:
		for building in list:
			if not building.building:
				continue
			var builders: int = _builder_count(building.name)
			if builders <= 0:
				continue
			building.build_progress += builders
			if industry_resources.Wood > 0:
				industry_resources.Wood -= 1
			if industry_resources.stone > 0:
				industry_resources.stone -= 1
			if building.build_progress >= 80:
				building.building = false
				building.build_progress = 0
				building.quantity += 1
				_release_builders(building.name)
				events.push_front("%s completed." % building.name)

func _update_citizens() -> void:
	var shelter_capacity := 0
	for service in town_services:
		if service.name == "HOUSE":
			shelter_capacity = service.quantity * service.capacity
	var sheltered := 0
	for citizen in citizens:
		citizen.shelter = sheltered < shelter_capacity
		sheltered += 1
		var base_happiness: int = max(5, 45 - int(citizen.age / 10) * 5)
		var service_bonus := 0
		for service in town_services:
			if service.effect == "happiness":
				service_bonus += service.quantity * 2
			if service.effect == "health":
				citizen.health = min(100, citizen.health + service.quantity)
		citizen.happiness = clampi(base_happiness + service_bonus - (20 if citizen.hunger else 0), 0, 100)
		citizen.efficiency = clampi(int((citizen.health + citizen.happiness) / 2.0), 10, 100)

func _random_event() -> void:
	if randi_range(1, 100) <= 8:
		var found: int = randi_range(5, 20)
		food_resources.berries += found
		events.push_front("%s/%s/%s: Gatherers found %s berries." % [day, month, year, found])
	if events.size() > 30:
		events.resize(30)

func _remove_food(amount: int) -> void:
	var left := amount
	for key in food_resources.keys():
		var take: int = min(food_resources[key], left)
		food_resources[key] -= take
		left -= take
		if left <= 0:
			return

func _active_craft_product(building: Dictionary) -> Dictionary:
	if building.one_output:
		return {
			"name": building.output,
			"progress": building.progress,
			"total": building.total,
			"costs": building.costs
		}
	var selected: int = int(building.get("selected", 0))
	return building.products[selected]

func _increment_craft_progress(building: Dictionary, product: Dictionary) -> void:
	if building.one_output:
		building.progress += 1
	else:
		product.progress += 1

func _reset_craft_progress(building: Dictionary, product: Dictionary) -> void:
	if building.one_output:
		building.progress = 0
	else:
		product.progress = 0

func _craft_progress(building: Dictionary, product: Dictionary) -> int:
	if building.one_output:
		return int(building.progress)
	return int(product.progress)

func _can_pay_costs(costs: Array, workers: int) -> bool:
	for cost in costs:
		var required: int = int(cost.count) * workers
		if _resource_count(cost.type, cost.name) < required:
			return false
	return true

func _pay_costs(costs: Array, workers: int) -> void:
	for cost in costs:
		var required: int = int(cost.count) * workers
		if cost.type == "crafted":
			crafted_resources[cost.name] -= required
		else:
			industry_resources[cost.name] -= required

func _resource_count(type: String, name: String) -> int:
	if type == "crafted":
		return int(crafted_resources.get(name, 0))
	return int(industry_resources.get(name, 0))

func _efficiency_for(workarea: String) -> float:
	var total := 0.0
	var count := 0
	for citizen in citizens:
		if citizen.workarea == workarea:
			total += citizen.efficiency
			count += 1
	if count == 0:
		return 0.0
	return total / count

func _first_unemployed():
	for citizen in citizens:
		if citizen.workarea == "unemployed":
			return citizen
	return null

func _builder_count(building_name: String) -> int:
	var count := 0
	for citizen in citizens:
		if citizen.workarea == "builder:%s" % building_name:
			count += 1
	return count

func _release_builders(building_name: String) -> void:
	for citizen in citizens:
		if citizen.workarea == "builder:%s" % building_name:
			citizen.workarea = "unemployed"

func _release_workers_for_building(building_name: String) -> void:
	for citizen in citizens:
		if citizen.workarea == building_name:
			citizen.workarea = "unemployed"

func _capacity(building: Dictionary) -> int:
	if building.has("capacity_per_building"):
		return building.quantity * building.capacity_per_building
	return building.capacity

func _building_list(category: String) -> Array:
	if category == "industry":
		return industry_buildings
	if category == "food":
		return food_buildings
	if category == "craft":
		return craft_buildings
	if category == "town":
		return town_services
	return storages

func _is_build_category(category: String) -> bool:
	return category == "industry" or category == "food" or category == "craft" or category == "town" or category == "storage"

func _placement_at(x: int, y: int) -> Dictionary:
	for placement in placed_buildings:
		if int(placement.get("x", -1)) == x and int(placement.get("y", -1)) == y:
			return placement
	return {}

func _average(field: String) -> int:
	if citizens.is_empty():
		return 0
	var total := 0
	for citizen in citizens:
		total += int(citizen[field])
	return roundi(total / float(citizens.size()))
