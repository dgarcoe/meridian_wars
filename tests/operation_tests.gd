extends SceneTree

const Operation = preload("res://domain/operation.gd")
const Battle = preload("res://domain/tactical_battle.gd")
const Store = preload("res://infrastructure/operation_store.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	_test_operation()
	_test_persistence()
	_test_tactics()
	print("Operation suite: %d checks; %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func _test_operation() -> void:
	var operation := Operation.new()
	check(not operation.launch(), "Cannot skip briefing")
	check(not operation.reinforce(0), "Cannot reinforce before authorization")
	check(not operation.prepare("invalid",0), "Reject invalid doctrine")
	check(operation.prepare("protect",1), "Authorize chosen commander")
	check(not operation.prepare("interdict",0), "No double authorization")
	check(operation.reinforce(0), "Reinforce valid squad")
	check(operation.credits == 90 and operation.ships[0] == 7, "Reinforcement cost and count")
	check(operation.reinforce(0) and not operation.reinforce(0), "Squad capacity enforced")
	check(not operation.reinforce(-1), "Invalid squad rejected")
	check(operation.advance() and operation.location == 1, "First jump")
	check(operation.advance() and operation.phase == "contact", "Second jump encounters enemy")
	check(not operation.advance() and operation.supply == 70, "Contact blocks further movement")
	check(operation.launch(), "Launch tactical battle")
	check(not operation.resolve("victory",[99,5,4]), "Reject impossible survivors")
	check(operation.resolve("victory",[5,4,3]), "Accept battle outcome")
	check(operation.total_ships() == 12 and operation.phase == "debrief", "Persist survivors")
	var credits: int = operation.credits
	check(not operation.resolve("victory",[5,4,3]) and operation.credits == credits, "No duplicate rewards")


func _test_persistence() -> void:
	var operation := Operation.new()
	var restored := Operation.new()
	check(restored.restore(operation.to_data()), "Roundtrip initial data")
	var invalid: Dictionary = operation.to_data()
	invalid.ships = [1,-5,0]
	check(not restored.restore(invalid), "Reject negative ships")
	check(restored.total_ships() == 15, "Invalid restore does not partially mutate")
	invalid = operation.to_data()
	invalid.turn = "broken"
	check(not restored.restore(invalid), "Reject wrong scalar type")
	invalid = operation.to_data()
	invalid.location = 2
	check(not restored.restore(invalid), "Reject inconsistent phase/location")
	invalid = operation.to_data()
	invalid.credits = 3.5
	check(not restored.restore(invalid), "Reject fractional credits")
	invalid = operation.to_data()
	invalid.erase("ships")
	check(not restored.restore(invalid), "Reject missing schema keys")
	var path := "user://test_operation_%d.json" % Time.get_ticks_usec()
	var store := Store.new()
	check(store.save(operation,path) == OK, "Write versioned save")
	operation.prepare("interdict",1)
	operation.advance()
	check(store.save(operation,path) == OK, "Replace existing save")
	var loaded = store.load_operation(path)
	check(loaded != null and loaded.location == 1 and loaded.commander == 1, "Load replaced save")
	operation.advance()
	operation.launch()
	check(store.save(operation,path) == ERR_BUSY, "Block battle saves")
	DirAccess.remove_absolute(path)
	check(store.load_operation(path) == null, "Missing save is safe")


func _test_tactics() -> void:
	var battle := Battle.new([6,5,4],0,"protect")
	check(battle.units.size() == 6, "Six tactical squads")
	battle.move(0,Vector2(999,999))
	check(battle.units[0].goal == Vector2(85,65), "Clamp orders to battlefield")
	var before: Vector2 = battle.units[0].position
	battle.advance(0)
	check(battle.units[0].position == before, "Zero delta does not advance")
	battle.hold(0)
	battle.advance(1)
	check(battle.units[0].position == before, "Hold keeps position")
	battle.attack(0,3)
	battle.advance(1)
	check(battle.units[0].position != before, "Attack approaches target")
	battle.retreat()
	var elapsed: float = battle.elapsed
	battle.advance(10)
	check(battle.outcome == "retreat" and battle.elapsed == elapsed, "Terminal state immutable")
	var a := Battle.new([6,5,4],0,"interdict")
	var b := Battle.new([6,5,4],0,"interdict")
	for id in range(3):
		a.attack(id,3)
		b.attack(id,3)
	for i in range(3000):
		a.advance(.1)
		b.advance(.1)
		a.events.clear()
		b.events.clear()
	check(a.outcome == b.outcome and a.survivors() == b.survivors(), "Deterministic tactical replay")
	check(not a.outcome.is_empty(), "Battle reaches a terminal state")
	for unit in a.units:
		check(unit.hp >= 0 and a.ship_count(unit) <= unit.initial, "Health/count invariant")
	var standard := Battle.new([6,5,4],0)
	var fast := Battle.new([6,5,4],1)
	standard.move(0,Vector2(-10,-22))
	fast.move(0,Vector2(-10,-22))
	standard.advance(1)
	fast.advance(1)
	check(fast.units[0].position.x > standard.units[0].position.x, "Commander speed bonus applied")
	var convoy := Battle.new([6,5,4],0,"protect")
	for i in range(3,6):
		convoy.units[i].hold = true
	convoy.advance(121)
	check(convoy.outcome == "victory", "Convoy evacuation timer victory")
	var destroyed := Battle.new([6,5,4])
	for i in range(3):
		destroyed.units[i].hp = 0
	destroyed.advance(.2)
	check(destroyed.outcome == "defeat", "Player annihilation is defeat")
