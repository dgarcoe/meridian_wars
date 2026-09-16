extends RefCounted
## Use cases shared by UI and tests. Dependencies are explicitly injected.

const PLAYER := "veyra"
const ENEMY := "league"
const MAX_SUPPLY := 3
const REINFORCEMENT_COST := 10
const REINFORCEMENT_SHIPS := 4

var state: RefCounted
var pending_orders: Dictionary = {}
var _combat: RefCounted
var _ai: RefCounted


func _init(campaign: RefCounted, combat: RefCounted, ai: RefCounted) -> void:
	state = campaign
	_combat = combat
	_ai = ai


func order_move(fleet_id: int, destination: int) -> String:
	if not state.winner.is_empty():
		return "La campaña ha terminado."
	var fleet: Dictionary = state.fleet_by_id(fleet_id)
	if fleet.is_empty() or fleet.owner != PLAYER:
		return "Selecciona una flota propia."
	if destination not in state.neighbors(fleet.system):
		return "El destino debe estar conectado por una ruta."
	if fleet.supply <= 0:
		return "La flota no tiene suministros."
	pending_orders[fleet_id] = destination
	return ""


func reinforce(fleet_id: int) -> String:
	if not state.winner.is_empty():
		return "La campaña ha terminado."
	var fleet: Dictionary = state.fleet_by_id(fleet_id)
	if fleet.is_empty() or fleet.owner != PLAYER:
		return "Selecciona una flota propia."
	if state.system_by_id(fleet.system).owner != PLAYER:
		return "Necesitas un sistema propio para recibir refuerzos."
	if state.credits[PLAYER] < REINFORCEMENT_COST:
		return "Créditos insuficientes."
	state.credits[PLAYER] -= REINFORCEMENT_COST
	fleet.ships += REINFORCEMENT_SHIPS
	return ""


func end_turn() -> Array[String]:
	var reports: Array[String] = []
	if not state.winner.is_empty():
		return reports
	var orders: Dictionary = _ai.plan(state, ENEMY)
	orders.merge(pending_orders, true)
	_move_fleets(orders)
	pending_orders.clear()
	for system in state.systems:
		var report: String = _combat.resolve(state.fleets, system.id)
		if not report.is_empty():
			reports.append("%s: %s" % [system.name, report])
	_remove_destroyed_fleets()
	_capture_and_resupply(reports)
	for system in state.systems:
		if state.credits.has(system.owner):
			state.credits[system.owner] += system.income
	state.turn += 1
	_check_victory()
	return reports


func _move_fleets(orders: Dictionary) -> void:
	# Orders are planned before movement. Crossing fleets do not intercept in v0.1.
	for fleet in state.fleets:
		if orders.has(fleet.id):
			fleet.system = orders[fleet.id]
			fleet.supply -= 1


func _remove_destroyed_fleets() -> void:
	for index in range(state.fleets.size() - 1, -1, -1):
		if state.fleets[index].ships <= 0:
			state.fleets.remove_at(index)


func _capture_and_resupply(reports: Array[String]) -> void:
	for fleet in state.fleets:
		var system: Dictionary = state.system_by_id(fleet.system)
		if system.owner != fleet.owner:
			system.owner = fleet.owner
			reports.append("%s pasa a control de %s." % [system.name, fleet.owner])
		# Local resupply only. Connected logistics is a later milestone.
		fleet.supply = MAX_SUPPLY


func _check_victory() -> void:
	var player_alive := false
	var enemy_alive := false
	for fleet in state.fleets:
		player_alive = player_alive or fleet.owner == PLAYER
		enemy_alive = enemy_alive or fleet.owner == ENEMY
	if not player_alive and not enemy_alive:
		state.winner = "draw"
	elif not player_alive:
		state.winner = ENEMY
	elif not enemy_alive:
		state.winner = PLAYER
