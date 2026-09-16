extends SceneTree
## Dependency-free test runner: godot --headless --path . --script tests/run_tests.gd

const Factory = preload("res://infrastructure/scenario_factory.gd")
const Service = preload("res://application/campaign_service.gd")
const Combat = preload("res://domain/combat.gd")
const StrategicAI = preload("res://domain/strategic_ai.gd")

var _failures: int = 0
var _checks: int = 0


func _initialize() -> void:
	_test_scenario()
	_test_orders()
	_test_economy()
	_test_combat()
	_test_campaign()
	print("%d checks; %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _new_service() -> RefCounted:
	return Service.new(Factory.new().create(), Combat.new(), StrategicAI.new())


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _test_scenario() -> void:
	var first: RefCounted = Factory.new().create()
	var second: RefCounted = Factory.new().create()
	_check(first.systems.size() == 12, "12 systems")
	_check(first.fleets.size() == 4, "4 fleets")
	first.fleets[0].ships = 1
	_check(second.fleets[0].ships == 12, "Factories do not share mutable state")
	for system in first.systems:
		_check(not first.neighbors(system.id).is_empty(), "No isolated systems")


func _test_orders() -> void:
	var service := _new_service()
	_check(not service.order_move(999, 1).is_empty(), "Reject missing fleet")
	_check(not service.order_move(2, 4).is_empty(), "Reject enemy fleet")
	_check(not service.order_move(0, 11).is_empty(), "Reject non-adjacent move")
	_check(service.order_move(0, 4).is_empty(), "Accept adjacent move")
	_check(service.state.fleets[0].system == 0, "Order does not move immediately")
	_check(service.order_move(0, 1).is_empty(), "Replace pending order")
	_check(service.pending_orders.size() == 1, "One order per fleet")
	service.end_turn()
	_check(service.state.fleet_by_id(0).system == 1, "Apply queued move")
	_check(service.pending_orders.is_empty(), "Clear orders after resolution")
	service.state.fleet_by_id(0).supply = 0
	_check(not service.order_move(0, 0).is_empty(), "Reject move without supply")


func _test_economy() -> void:
	var service := _new_service()
	_check(service.reinforce(0).is_empty(), "Reinforce owned fleet")
	_check(service.state.credits.veyra == 20, "Charge exact reinforcement cost")
	_check(service.state.fleets[0].ships == 16, "Add reinforcement ships")
	service.state.credits.veyra = 0
	_check(not service.reinforce(0).is_empty(), "Reject unaffordable reinforcement")
	service.end_turn()
	_check(service.state.credits.veyra == 8, "Collect income from four worlds")


func _test_combat() -> void:
	var fleets: Array[Dictionary] = [
		{"system": 0, "owner": "veyra", "ships": 10},
		{"system": 0, "owner": "league", "ships": 6}
	]
	Combat.new().resolve(fleets, 0)
	_check(fleets[0].ships == 4, "Winner receives simultaneous losses")
	_check(fleets[1].ships == 0, "Loser destroyed")
	var service := _new_service()
	service.order_move(0, 4)
	service.order_move(1, 7)
	var reports: Array[String] = service.end_turn()
	_check(not reports.is_empty(), "Combat generates reports")
	_check(service.state.winner == "draw", "Equal forces annihilate on both fronts")
	_check(service.state.fleets.is_empty(), "Remove all destroyed fleets")
	_check(not service.order_move(0, 1).is_empty(), "Reject orders after game over")
	var final_turn: int = service.state.turn
	service.end_turn()
	_check(service.state.turn == final_turn, "Game over freezes simulation")


func _test_campaign() -> void:
	var service := _new_service()
	for index in range(20):
		service.end_turn()
		for fleet in service.state.fleets:
			_check(fleet.ships > 0, "Only living fleets remain")
			_check(not service.state.system_by_id(fleet.system).is_empty(), "Fleet location exists")
	_check(service.state.turn > 1, "Simulation advances")
