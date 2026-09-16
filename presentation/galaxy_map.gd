extends Control
## Passive map: emits selections, never mutates campaign state.

signal system_selected(id: int)

var campaign: RefCounted
var selected_system: int = -1
var orders: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(640, 480)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)


func _draw() -> void:
	if campaign == null:
		return
	for route in campaign.routes:
		draw_line(_position(route.x), _position(route.y), Color("273b55"), 2.0)
	for fleet_id in orders:
		var fleet: Dictionary = campaign.fleet_by_id(fleet_id)
		draw_line(_position(fleet.system), _position(orders[fleet_id]), Color("efc66b"), 4.0)
	for system in campaign.systems:
		_draw_system(system)


func _draw_system(system: Dictionary) -> void:
	var point := _position(system.id)
	var color := Color("718095")
	if system.owner == "veyra":
		color = Color("efc66b")
	elif system.owner == "league":
		color = Color("62cadd")
	if selected_system == system.id:
		draw_arc(point, 20, 0, TAU, 40, Color.WHITE, 2.0)
	draw_circle(point, 9, color)
	var font := ThemeDB.fallback_font
	draw_string(font, point + Vector2(-30, -28), system.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
	var offset := 32
	for fleet in campaign.fleets:
		if fleet.system == system.id:
			var label: String = "%s · %d" % [fleet.owner, fleet.ships]
			draw_string(font, point + Vector2(-36, offset), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
			offset += 20


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for system in campaign.systems:
			if event.position.distance_to(_position(system.id)) < 25:
				system_selected.emit(system.id)
				accept_event()
				return


func _position(id: int) -> Vector2:
	return campaign.system_by_id(id).position * size
