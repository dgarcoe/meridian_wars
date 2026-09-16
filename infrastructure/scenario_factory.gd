extends RefCounted
## Original placeholder setting. Factory creates independent campaign instances.

const Campaign = preload("res://domain/campaign.gd")


func create() -> RefCounted:
	var state := Campaign.new()
	var names := [
		"Veyra", "Lumen", "Orial", "Sereva", "Nártex", "Talren",
		"Cendra", "Ivara", "Dorsal", "Edris", "Marea", "Velis"
	]
	for id in range(names.size()):
		var owner := "neutral"
		if id < 4:
			owner = "veyra"
		elif id > 7:
			owner = "league"
		state.systems.append({
			"id": id, "name": names[id], "owner": owner, "income": 2,
			"position": Vector2(0.13 + (id % 4) * 0.24, 0.2 + floori(id / 4.0) * 0.3)
		})
	for id in range(12):
		if id % 4 < 3:
			state.routes.append(Vector2i(id, id + 1))
		if id < 8:
			state.routes.append(Vector2i(id, id + 4))
	state.fleets = [
		_fleet(0, "Primera flota", "veyra", 0, 12),
		_fleet(1, "Guardia del Meridiano", "veyra", 3, 10),
		_fleet(2, "Expedición de la Liga", "league", 8, 12),
		_fleet(3, "Flota de Velis", "league", 11, 10),
	]
	return state


func _fleet(id: int, title: String, owner: String, system: int, ships: int) -> Dictionary:
	return {
		"id": id, "name": title, "owner": owner, "system": system,
		"ships": ships, "supply": 3
	}
