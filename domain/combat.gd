extends RefCounted
## Deterministic, simultaneous damage; deliberately simple prototype rules.


func resolve(fleets: Array[Dictionary], system_id: int) -> String:
	var sides: Dictionary = {}
	for fleet in fleets:
		if fleet.system == system_id:
			sides[fleet.owner] = int(sides.get(fleet.owner, 0)) + int(fleet.ships)
	if sides.size() < 2:
		return ""
	var owners: Array = sides.keys()
	owners.sort()
	var first: String = owners[0]
	var second: String = owners[1]
	var first_power: int = sides[first]
	var second_power: int = sides[second]
	_apply_losses(fleets, system_id, first, second_power)
	_apply_losses(fleets, system_id, second, first_power)
	return "Combate: %s (%d) contra %s (%d)." % [first, first_power, second, second_power]


func _apply_losses(fleets: Array[Dictionary], system_id: int, owner: String, loss: int) -> void:
	# Stable fleet order makes replays reproducible, including allocation of losses.
	for fleet in fleets:
		if fleet.system != system_id or fleet.owner != owner:
			continue
		var casualties: int = mini(fleet.ships, loss)
		fleet.ships -= casualties
		loss -= casualties
