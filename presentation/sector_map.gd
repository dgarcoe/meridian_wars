extends Control
## Original vector cartography; zoom/pan affect presentation only.

signal system_selected(id: int)

const UI = preload("res://presentation/deck_theme.gd")
const NAMES := ["VEYRA", "SEREVA", "NÁRTEX", "TALREN", "LUMEN", "ORIAL", "CENDRA", "EDRIS", "IVARA", "VELIS", "MAREA", "DORSAL"]
const POINTS := [Vector2(.16,.55), Vector2(.38,.44), Vector2(.61,.51), Vector2(.83,.35), Vector2(.12,.25), Vector2(.32,.19), Vector2(.45,.72), Vector2(.77,.76), Vector2(.62,.23), Vector2(.90,.59), Vector2(.22,.82), Vector2(.51,.9)]
const LINKS := [Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(0,4),Vector2i(4,5),Vector2i(5,1),Vector2i(1,6),Vector2i(6,2),Vector2i(2,8),Vector2i(8,3),Vector2i(3,9),Vector2i(9,7),Vector2i(6,11),Vector2i(0,10),Vector2i(10,11),Vector2i(11,7)]

var operation: RefCounted
var selected: int = 2
var _zoom: float = 1.0
var _pan := Vector2.ZERO
var _clock: float = 0


func _ready() -> void:
	custom_minimum_size = Vector2(480, 400)
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	clip_contents = true
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _point(id: int) -> Vector2:
	return (POINTS[id] - Vector2(.5,.5)) * size * _zoom + size / 2 + _pan


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("090f1d"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 915
	for i in range(240):
		var star := Vector2(rng.randf(), rng.randf()) * size
		draw_circle(star, rng.randf_range(.4,1.3), Color(.6,.75,.9,rng.randf_range(.08,.4)))
	for x in range(0, int(size.x), 60):
		draw_line(Vector2(x,0), Vector2(x,size.y), Color(.3,.6,.8,.045))
	for y in range(0, int(size.y), 60):
		draw_line(Vector2(0,y), Vector2(size.x,y), Color(.3,.6,.8,.045))
	draw_circle(_point(0), 140 * _zoom, Color(.85,.64,.3,.035))
	draw_circle(_point(3), 170 * _zoom, Color(.2,.7,.85,.035))
	for link in LINKS:
		draw_line(_point(link.x), _point(link.y), UI.EDGE, 1.0, true)
	for i in range(2):
		draw_dashed_line(_point(i), _point(i+1), Color(UI.GOLD,.65), 2.0, 7.0, true)
	for i in range(12):
		_draw_system(i)
	if operation != null:
		var p := _point(operation.location) + Vector2(0, -34)
		draw_colored_polygon(PackedVector2Array([p+Vector2(-9,8),p+Vector2(0,-9),p+Vector2(9,8),p+Vector2(0,4)]), UI.GOLD)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(22,30), "SECTOR 07  /  CORREDOR DEL MERIDIANO", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UI.MUTED)
	draw_string(font, Vector2(22,size.y-20), "RUEDA: ZOOM · BOTÓN CENTRAL: DESPLAZAR · CLIC: INSPECCIONAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.MUTED)


func _draw_system(id: int) -> void:
	var point := _point(id)
	var color := UI.GOLD if id in [0,1,4,5,10] else UI.CYAN
	if id in [2,6,11]:
		color = UI.MUTED
	if id == 2 and operation != null and operation.result == "victory":
		color = UI.GOLD
	if id == selected:
		draw_circle(point, 30, Color(color,.06))
		draw_arc(point, 24, 0, TAU, 48, Color(color,.6), 1, true)
	if id == 2 and (operation == null or operation.result != "victory"):
		draw_arc(point, 36 + sin(_clock*2)*3, 0, TAU, 48, Color(UI.RED,.4), 1, true)
	draw_circle(point, 5 if id != 0 else 8, color)
	draw_circle(point, 2, Color.WHITE)
	draw_string(ThemeDB.fallback_font, point + Vector2(13,5), NAMES[id], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	if id == 2:
		draw_string(ThemeDB.fallback_font, point + Vector2(-30,51), "OBJETIVO", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UI.RED)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_pan += event.relative
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = minf(2.0, _zoom + .1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = maxf(.7, _zoom - .1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			for id in range(12):
				if event.position.distance_to(_point(id)) < 24:
					selected = id
					system_selected.emit(id)
		accept_event()
