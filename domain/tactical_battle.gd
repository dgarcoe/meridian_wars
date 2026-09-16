extends RefCounted
## Fixed-step tactical simulation, independent of rendering and scene lifetime.

const Operation = preload("res://domain/operation.gd")
const STEP := 0.1
const SPEED := [8.0, 5.0, 3.8]
const RANGE := [22.0, 30.0, 43.0]
const HULL := [70.0, 110.0, 90.0]
const DAMAGE := [7.0, 10.0, 12.0]

var units: Array[Dictionary] = []
var elapsed: float = 0.0
var outcome: String = ""
var events: Array[Dictionary] = []
var _accumulator: float = 0.0
var _range_bonus: float = 1.0
var _speed_bonus: float = 1.0
var _timer_objective: bool = true


func _init(counts: Array[int], commander: int = 0, doctrine: String = "protect") -> void:
	_range_bonus = Operation.COMMANDERS[commander].range
	_speed_bonus = Operation.COMMANDERS[commander].speed
	_timer_objective = doctrine == "protect"
	for side in range(2):
		for squad in range(3):
			var count: int = counts[squad] if side == 0 else [6, 5, 4][squad]
			var point := Vector2(-44 if side == 0 else 44, (squad - 1) * 22)
			units.append({"id": side * 3 + squad, "side": side, "class": squad,
				"initial": count, "hp": count * HULL[squad], "position": point,
				"goal": point, "heading": Vector2.RIGHT if side == 0 else Vector2.LEFT,
				"target": -1, "cooldown": squad * 0.2, "hold": false})


func survivors() -> Array[int]:
	var counts: Array[int] = []
	for i in range(3):
		counts.append(ship_count(units[i]))
	return counts


func ship_count(unit: Dictionary) -> int:
	return maxi(0, ceili(unit.hp / HULL[unit.class]))


func effective_range(unit: Dictionary) -> float:
	return RANGE[unit.class] * (_range_bonus if unit.side == 0 else 1.0)


func move(id: int, point: Vector2) -> void:
	if id < 0 or id >= 3 or not outcome.is_empty():
		return
	units[id].goal = point.clamp(Vector2(-85, -65), Vector2(85, 65))
	units[id].target = -1
	units[id].hold = false


func attack(id: int, target: int) -> void:
	if id >= 0 and id < 3 and target >= 3 and target < 6 and outcome.is_empty():
		units[id].target = target
		units[id].hold = false


func hold(id: int) -> void:
	if id >= 0 and id < 3:
		units[id].goal = units[id].position
		units[id].target = -1
		units[id].hold = true


func retreat() -> void:
	if outcome.is_empty():
		outcome = "retreat"


func advance(delta: float) -> void:
	if delta <= 0 or not outcome.is_empty():
		return
	_accumulator += delta
	while _accumulator >= STEP and outcome.is_empty():
		_accumulator -= STEP
		_tick()


func _tick() -> void:
	elapsed += STEP
	var damage: Array[float] = [0, 0, 0, 0, 0, 0]
	for unit in units:
		if unit.hp <= 0:
			continue
		var target: int = unit.target
		if target < 0 or units[target].hp <= 0:
			target = _nearest_enemy(unit)
		if target < 0:
			continue
		var distance: float = unit.position.distance_to(units[target].position)
		var reach := effective_range(unit)
		if (unit.side == 1 or unit.target >= 0) and distance > reach * 0.85:
			unit.goal = units[target].position
		elif unit.side == 1 or unit.target >= 0:
			unit.goal = unit.position
		var direction: Vector2 = unit.goal - unit.position
		if direction.length() > 0.2 and not unit.hold:
			unit.heading = direction.normalized()
			unit.position = unit.position.move_toward(unit.goal, SPEED[unit.class] * STEP * (_speed_bonus if unit.side == 0 else 1.0))
		unit.cooldown -= STEP
		if distance <= reach and unit.cooldown <= 0:
			var bearing: Vector2 = (units[target].position - unit.position).normalized()
			var facing: float = 0.5 + 0.5 * maxf(0.0, unit.heading.dot(bearing))
			damage[target] += ship_count(unit) * DAMAGE[unit.class] * facing
			unit.cooldown = 2.0
			events.append({"from": unit.position, "to": units[target].position, "side": unit.side})
	for id in range(6):
		var previous: float = units[id].hp
		units[id].hp = maxf(0, previous - damage[id])
		if previous > 0 and units[id].hp <= 0:
			events.append({"explosion": units[id].position})
	if _side_alive(0) == 0:
		outcome = "defeat"
	elif _side_alive(1) == 0 or (_timer_objective and elapsed >= 120.0):
		outcome = "victory"
	elif elapsed >= 300.0:
		outcome = "retreat"


func _nearest_enemy(unit: Dictionary) -> int:
	var closest := -1
	var distance := INF
	for other in units:
		if other.side == unit.side or other.hp <= 0:
			continue
		var candidate: float = unit.position.distance_squared_to(other.position)
		if candidate < distance:
			closest = other.id
			distance = candidate
	return closest


func _side_alive(side: int) -> int:
	var count := 0
	for unit in units:
		if unit.side == side:
			count += ship_count(unit)
	return count
