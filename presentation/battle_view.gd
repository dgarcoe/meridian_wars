extends VBoxContainer
## Tactical presentation and input adapter. Simulation stays in TacticalBattle.

signal finished(outcome: String, survivors: Array[int])

const UI = preload("res://presentation/deck_theme.gd")
const Battle = preload("res://domain/tactical_battle.gd")
const Ship = preload("res://presentation/ship_visual.gd")
const NAMES := ["VANGUARDIA", "LÍNEA DE BATALLA", "APOYO DE FUEGO"]
const CLASSES := ["Fragatas", "Cruceros", "Porta-lanzas"]

var simulation: RefCounted
var _world: Node3D
var _viewport: SubViewport
var _camera: Camera3D
var _squads: Array[Node3D] = []
var _labels: Array[Label3D] = []
var _rings: Array[MeshInstance3D] = []
var _squad_buttons: Array[Button] = []
var _selected: int = 0
var _paused: bool = true
var _speed: float = 1.0
var _yaw: float = 0.0
var _distance: float = 145.0
var _focus := Vector3.ZERO
var _status: Label
var _selection: Label
var _orders: Label
var _pause_button: Button
var _return_button: Button
var _progress: ProgressBar
var _doctrine: String
var _effects: Array[Dictionary] = []


func configure(counts: Array[int], commander: int, doctrine: String) -> void:
	simulation = Battle.new(counts, commander, doctrine)
	_doctrine = doctrine


func _ready() -> void:
	_build_ui()
	_build_world()
	_sync_visuals()


func _build_ui() -> void:
	var header := HBoxContainer.new()
	add_child(header)
	var title := UI.label("NÁRTEX  /  MANDO TÁCTICO", 25, UI.GOLD)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(title)
	_status = UI.label("ÓRDENES INICIALES", 16, UI.CYAN)
	header.add_child(_status)
	_pause_button = UI.button("▶ Iniciar combate", _toggle_pause, true)
	header.add_child(_pause_button)
	for speed in [1.0,2.0,4.0]:
		header.add_child(UI.button("×%d" % speed, _set_speed.bind(speed)))
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	add_child(body)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(700,450)
	container.size_flags_horizontal = SIZE_EXPAND_FILL
	container.size_flags_vertical = SIZE_EXPAND_FILL
	container.gui_input.connect(_battle_input)
	body.add_child(container)
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(1000,650)
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(_viewport)
	var side := UI.panel(body, 270)
	side.add_child(UI.label("OBJETIVO DE LA OPERACIÓN", 12, UI.GOLD))
	side.add_child(UI.paragraph("Mantén al menos una nave operativa durante 120 s para cubrir la evacuación, o elimina a la Liga." if _doctrine == "protect" else "Elimina todas las escuadras de la Liga. Límite de operación: 300 s."))
	_progress = UI.bar(0)
	side.add_child(_progress)
	side.add_child(HSeparator.new())
	side.add_child(UI.label("ESCUADRAS  /  TECLAS 1–3", 12, UI.MUTED))
	for id in range(3):
		var button := UI.button(NAMES[id], _select.bind(id))
		_squad_buttons.append(button)
		side.add_child(button)
	_selection = UI.paragraph("")
	side.add_child(_selection)
	side.add_child(UI.button("Mantener posición [H]", _hold))
	side.add_child(UI.button("Concentrar fuego", _focus_fire))
	side.add_child(UI.button("Retirada de emergencia", _confirm_retreat))
	side.add_child(HSeparator.new())
	_orders = UI.paragraph("En pausa. Selecciona una escuadra y da órdenes antes de iniciar.", UI.GOLD)
	side.add_child(_orders)
	_return_button = UI.button("Volver al centro de mando →", _finish, true)
	_return_button.visible = false
	side.add_child(_return_button)
	var help := UI.panel(self)
	help.add_child(UI.label("CLIC: SELECCIONAR  ·  CLIC DERECHO: MOVER / ATACAR  ·  ESPACIO: PAUSA  ·  H: MANTENER", 13, UI.MUTED))
	help.add_child(UI.label("BOTÓN CENTRAL: ORBITAR  ·  RUEDA: ZOOM  ·  WASD: DESPLAZAR CÁMARA  ·  F: CENTRAR", 12, UI.MUTED))


func _build_world() -> void:
	_world = Node3D.new()
	_viewport.add_child(_world)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("030916")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("7b9dbb")
	environment.environment.ambient_light_energy = .8
	_world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-30,0)
	sun.light_color = Color("b8dcff")
	sun.light_energy = 1.4
	_world.add_child(sun)
	_camera = Camera3D.new()
	_camera.fov = 55
	_camera.far = 1800
	_world.add_child(_camera)
	_camera.current = true
	_camera_position()
	_grid()
	_stars_and_planet()
	for unit in simulation.units:
		var squad := Node3D.new()
		_world.add_child(squad)
		_squads.append(squad)
		for i in range(unit.initial):
			var ship := Ship.create(unit.class, UI.GOLD if unit.side == 0 else UI.CYAN)
			ship.position = Vector3(-(i / 3) * 6.5, 0, ((i % 3) - 1) * 5.0)
			squad.add_child(ship)
		var label := Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.pixel_size = .07
		label.modulate = UI.GOLD if unit.side == 0 else UI.CYAN
		_world.add_child(label)
		_labels.append(label)
		var ring := MeshInstance3D.new()
		var mesh := TorusMesh.new()
		mesh.inner_radius = 10.0
		mesh.outer_radius = 10.25
		mesh.rings = 40
		mesh.ring_segments = 8
		ring.mesh = mesh
		ring.material_override = Ship.material(UI.GOLD, true)
		_world.add_child(ring)
		_rings.append(ring)


func _grid() -> void:
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, Ship.material(Color("112c40"), true))
	for i in range(-100,101,10):
		lines.surface_add_vertex(Vector3(i,-3,-75))
		lines.surface_add_vertex(Vector3(i,-3,75))
	for i in range(-70,71,10):
		lines.surface_add_vertex(Vector3(-100,-3,i))
		lines.surface_add_vertex(Vector3(100,-3,i))
	lines.surface_end()
	var instance := MeshInstance3D.new()
	instance.mesh = lines
	_world.add_child(instance)


func _stars_and_planet() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 71
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_POINTS, Ship.material(Color("8ba5ba"), true))
	for i in range(1600):
		mesh.surface_add_vertex(Vector3(rng.randf_range(-650,650), rng.randf_range(-150,250), rng.randf_range(-650,-170)))
	mesh.surface_end()
	var stars := MeshInstance3D.new()
	stars.mesh = mesh
	_world.add_child(stars)
	var planet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 65
	sphere.height = 130
	planet.mesh = sphere
	planet.material_override = Ship.material(Color("213f58"))
	planet.position = Vector3(140,-95,-260)
	_world.add_child(planet)


func _process(delta: float) -> void:
	if simulation == null or _camera == null:
		return
	_camera_controls(delta)
	if not _paused:
		simulation.advance(minf(delta,.1) * _speed)
	for event in simulation.events:
		_effect(event)
	simulation.events.clear()
	for i in range(_effects.size()-1,-1,-1):
		_effects[i].life -= delta
		if _effects[i].life <= 0:
			_effects[i].node.queue_free()
			_effects.remove_at(i)
	_sync_visuals()


func _sync_visuals() -> void:
	for unit in simulation.units:
		var squad := _squads[unit.id]
		squad.position = Vector3(unit.position.x,0,unit.position.y)
		squad.rotation.y = -unit.heading.angle()
		var count: int = simulation.ship_count(unit)
		for i in range(squad.get_child_count()):
			squad.get_child(i).visible = i < count
		var label := _labels[unit.id]
		label.position = squad.position + Vector3(0,5,0)
		var squad_name: String = NAMES[unit.class] if unit.side == 0 else "LIGA %d" % (unit["class"] + 1)
		label.text = "%s · %02d" % [squad_name, count]
		label.visible = count > 0
		_rings[unit.id].position = squad.position + Vector3(0,-2.5,0)
		_rings[unit.id].visible = unit.id == _selected and count > 0
		if unit.side == 0:
			_squad_buttons[unit.id].text = ("● " if unit.id == _selected else "") + "%s · %d" % [CLASSES[unit.class], count]
			_squad_buttons[unit.id].disabled = count == 0
	var unit: Dictionary = simulation.units[_selected]
	_selection.text = "%s\nIntegridad: %d%% · Alcance: %d\nOrientación de proa mejora el daño." % [NAMES[_selected], int(100 * unit.hp / (unit.initial * Battle.HULL[unit.class])), simulation.effective_range(unit)]
	_status.text = "%03d s  /  %s  /  ×%d" % [simulation.elapsed, "PAUSA" if _paused else "EN COMBATE", _speed]
	_progress.value = simulation.elapsed / (120.0 if _doctrine == "protect" else 300.0) * 100
	if not simulation.outcome.is_empty():
		_paused = true
		_pause_button.disabled = true
		_return_button.visible = true
		var titles := {"victory": "OBJETIVO CUMPLIDO", "defeat": "DERROTA", "retreat": "RETIRADA"}
		_orders.text = titles[simulation.outcome] + "\nLas bajas se transferirán a la campaña."


func _battle_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		_yaw -= event.relative.x * .006
		_camera_position()
	if event is not InputEventMouseButton or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_distance = maxf(45, _distance-8)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_distance = minf(240, _distance+8)
	else:
		var point: Variant = Plane(Vector3.UP,0).intersects_ray(_camera.project_ray_origin(event.position), _camera.project_ray_normal(event.position))
		if point == null:
			return
		var position := Vector2(point.x,point.z)
		if event.button_index == MOUSE_BUTTON_LEFT:
			for unit in simulation.units:
				if unit.side == 0 and unit.hp > 0 and unit.position.distance_to(position) < 12:
					_select(unit.id)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			for unit in simulation.units:
				if unit.side == 1 and unit.hp > 0 and unit.position.distance_to(position) < 12:
					simulation.attack(_selected,unit.id)
					_orders.text = "Ataque asignado a " + NAMES[_selected] + "."
					return
			simulation.move(_selected,position)
			_orders.text = "Destino asignado a " + NAMES[_selected] + "."
	_camera_position()


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: _select(0)
		KEY_2: _select(1)
		KEY_3: _select(2)
		KEY_SPACE: _toggle_pause()
		KEY_H: _hold()
		KEY_F:
			var p: Vector2 = simulation.units[_selected].position
			_focus = Vector3(p.x,0,p.y)
		_: return
	get_viewport().set_input_as_handled()


func _camera_controls(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_A): direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D): direction.x += 1
	if Input.is_physical_key_pressed(KEY_W): direction.z -= 1
	if Input.is_physical_key_pressed(KEY_S): direction.z += 1
	_focus += direction.rotated(Vector3.UP,_yaw) * delta * 40
	_focus.x = clampf(_focus.x,-90,90)
	_focus.z = clampf(_focus.z,-65,65)
	_camera_position()


func _camera_position() -> void:
	_camera.position = _focus + Vector3(sin(_yaw)*_distance*.6,_distance*.8,cos(_yaw)*_distance*.6)
	_camera.look_at(_focus)


func _select(id: int) -> void:
	_selected = id


func _toggle_pause() -> void:
	if not simulation.outcome.is_empty():
		return
	_paused = not _paused
	_pause_button.text = "▶ Continuar" if _paused else "Ⅱ Pausa"


func _set_speed(speed: float) -> void:
	_speed = speed


func _hold() -> void:
	simulation.hold(_selected)
	_orders.text = NAMES[_selected] + " mantiene posición."


func _focus_fire() -> void:
	for unit in simulation.units:
		if unit.side == 1 and unit.hp > 0:
			for id in range(3):
				simulation.attack(id,unit.id)
			_orders.text = "Todas las escuadras concentran fuego en Liga %d." % (unit["class"] + 1)
			return


func _confirm_retreat() -> void:
	if not simulation.outcome.is_empty():
		return
	_paused = true
	_pause_button.text = "▶ Continuar"
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "¿Abandonar la operación? Conservarás las naves supervivientes, pero perderás apoyo civil."
	dialog.confirmed.connect(func() -> void:
		simulation.retreat()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()


func _finish() -> void:
	if not simulation.outcome.is_empty():
		finished.emit(simulation.outcome,simulation.survivors())


func _effect(event: Dictionary) -> void:
	var node := MeshInstance3D.new()
	if event.has("explosion"):
		var mesh := SphereMesh.new()
		mesh.radius = 3.5
		mesh.height = 7
		node.mesh = mesh
		node.position = Vector3(event.explosion.x,0,event.explosion.y)
		node.material_override = Ship.material(UI.GOLD,true)
	else:
		var start := Vector3(event.from.x,0,event.from.y)
		var end := Vector3(event.to.x,0,event.to.y)
		var mesh := CylinderMesh.new()
		mesh.top_radius = .10
		mesh.bottom_radius = .10
		mesh.height = start.distance_to(end)
		node.mesh = mesh
		node.position = (start+end)/2
		node.material_override = Ship.material(UI.GOLD if event.side == 0 else UI.CYAN,true)
		var direction := (end-start).normalized()
		if direction.length() > .01:
			node.quaternion = Quaternion(Vector3.UP,direction)
	_world.add_child(node)
	_effects.append({"node":node,"life":.45 if event.has("explosion") else .13})
