extends RefCounted
## A complete, deliberately bounded campaign mission. No UI or disk access.

const COMMANDERS := [
	{"name": "ALENA VOSS", "role": "Doctrina de precisión", "detail": "+15% alcance de armas", "range": 1.15, "speed": 1.0},
	{"name": "DARÍO SEN", "role": "Guerra de maniobra", "detail": "+20% velocidad de escuadra", "range": 1.0, "speed": 1.2}
]

var phase: String = "briefing"
var commander: int = 0
var doctrine: String = "protect"
var credits: int = 120
var support: int = 62
var turn: int = 1
var location: int = 0
var ships: Array[int] = [6, 5, 4]
var supply: int = 100
var log: Array[String] = ["Prioridad alta · Señales hostiles en el corredor de Nártex."]
var result: String = ""


func prepare(choice: String, leader: int) -> bool:
	if phase != "briefing" or choice not in ["protect", "interdict"] or leader not in [0, 1]:
		return false
	doctrine = choice
	commander = leader
	phase = "deployment"
	log.append("Consejo: proteger el convoy." if choice == "protect" else "Consejo: interceptar la fuerza enemiga.")
	return true


func reinforce(index: int) -> bool:
	if phase != "deployment" or index < 0 or index >= ships.size() or credits < 30 or ships[index] >= 8:
		return false
	credits -= 30
	ships[index] += 1
	return true


func advance() -> bool:
	if phase != "deployment":
		return false
	location += 1
	turn += 1
	supply -= 15
	log.append("Salto confirmado · posición %d del corredor." % location)
	if location == 2:
		phase = "contact"
	return true


func launch() -> bool:
	if phase != "contact":
		return false
	phase = "battle"
	return true


func resolve(outcome: String, survivors: Array[int]) -> bool:
	if phase != "battle" or outcome not in ["victory", "defeat", "retreat"] or survivors.size() != 3:
		return false
	for i in range(3):
		if survivors[i] < 0 or survivors[i] > ships[i]:
			return false
	var losses: int = total_ships() - survivors.reduce(func(a: int, b: int) -> int: return a + b, 0)
	ships.assign(survivors)
	result = outcome
	phase = "debrief"
	if outcome == "victory":
		credits += 60
		support = clampi(support + (12 if doctrine == "protect" else 5) - losses, 0, 100)
	else:
		support = maxi(0, support - (12 if outcome == "retreat" else 22))
	log.append("Operación cerrada · %s · %d bajas navales." % [outcome, losses])
	return true


func total_ships() -> int:
	var total := 0
	for count in ships:
		total += count
	return total


func to_data() -> Dictionary:
	return {"version": 1, "phase": phase, "commander": commander, "doctrine": doctrine,
		"credits": credits, "support": support, "turn": turn, "location": location,
		"ships": ships.duplicate(), "supply": supply, "log": log.duplicate(), "result": result}


func restore(data: Dictionary) -> bool:
	# Validate the entire document before mutating anything. Battle saves are not supported.
	for key in to_data():
		if not data.has(key):
			return false
	if data.version != 1 or data.phase not in ["briefing", "deployment", "contact", "debrief"]:
		return false
	if not _whole_number(data.commander) or data.commander < 0 or data.commander > 1 or data.doctrine not in ["protect", "interdict"]:
		return false
	for key in ["credits", "support", "turn", "location", "supply"]:
		if not _whole_number(data[key]) or data[key] < 0:
			return false
	if data.credits > 1000 or data.support > 100 or data.supply > 100:
		return false
	if data.location > 2 or data.turn != data.location + 1 or data.supply != 100 - 15 * data.location:
		return false
	if typeof(data.ships) != TYPE_ARRAY or data.ships.size() != 3 or typeof(data.log) != TYPE_ARRAY:
		return false
	for count in data.ships:
		if not _whole_number(count) or count < 0 or count > 8:
			return false
	if data.log.size() > 100:
		return false
	for entry in data.log:
		if typeof(entry) != TYPE_STRING or entry.length() > 1000:
			return false
	if data.phase == "briefing" and data.location != 0:
		return false
	if data.phase == "deployment" and data.location > 1:
		return false
	if data.phase in ["contact", "debrief"] and data.location != 2:
		return false
	if data.phase == "debrief":
		if data.result not in ["victory", "defeat", "retreat"]:
			return false
	else:
		if data.result != "":
			return false
		for count in data.ships:
			if count == 0:
				return false
	phase = data.phase
	commander = int(data.commander)
	doctrine = data.doctrine
	credits = int(data.credits)
	support = int(data.support)
	turn = int(data.turn)
	location = int(data.location)
	supply = int(data.supply)
	ships.clear()
	for count in data.ships:
		ships.append(int(count))
	log.assign(data.log)
	result = data.result
	return true


func _whole_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value))
