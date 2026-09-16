extends RefCounted
## Plans one hop toward the closest hostile/neutral territory using BFS.


func plan(state: RefCounted, owner: String) -> Dictionary:
	var orders: Dictionary = {}
	for fleet in state.fleets:
		if fleet.owner != owner or fleet.supply <= 0:
			continue
		var destination := _next_step(state, fleet.system, owner)
		if destination != -1:
			orders[fleet.id] = destination
	return orders


func _next_step(state: RefCounted, origin: int, owner: String) -> int:
	var queue: Array[int] = [origin]
	var previous: Dictionary = {origin: -1}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current != origin and state.system_by_id(current).owner != owner:
			while previous[current] != origin:
				current = previous[current]
			return current
		for neighbor in state.neighbors(current):
			if not previous.has(neighbor):
				previous[neighbor] = current
				queue.append(neighbor)
	return -1
