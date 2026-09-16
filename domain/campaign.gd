extends RefCounted
## Mutable campaign aggregate. No scene tree, UI, filesystem or global services.

const PLAYER := "veyra"
const ENEMY := "league"
const NEUTRAL := "neutral"

var turn: int = 1
var systems: Array[Dictionary] = []
var fleets: Array[Dictionary] = []
var routes: Array[Vector2i] = []
var credits: Dictionary = {PLAYER: 30, ENEMY: 30}
var winner: String = ""


func system_by_id(id: int) -> Dictionary:
	for system in systems:
		if system.id == id:
			return system
	return {}


func fleet_by_id(id: int) -> Dictionary:
	for fleet in fleets:
		if fleet.id == id:
			return fleet
	return {}


func neighbors(id: int) -> Array[int]:
	var result: Array[int] = []
	for route in routes:
		if route.x == id:
			result.append(route.y)
		elif route.y == id:
			result.append(route.x)
	return result
