extends Control
## Composition root and thin presenter. Game rules live in the application layer.

const Factory = preload("res://infrastructure/scenario_factory.gd")
const Service = preload("res://application/campaign_service.gd")
const Combat = preload("res://domain/combat.gd")
const StrategicAI = preload("res://domain/strategic_ai.gd")
const GalaxyMap = preload("res://presentation/galaxy_map.gd")

var _service: RefCounted
var _map: Control
var _status: Label
var _details: Label
var _fleet_picker: OptionButton
var _reports: RichTextLabel
var _selected_fleet: int = -1
var _end_button: Button


func _ready() -> void:
	_build_ui()
	_new_campaign()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "LAS GUERRAS DEL MERIDIANO  /  Prototipo 0.1"
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	_status = Label.new()
	column.add_child(_status)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	_map = GalaxyMap.new()
	_map.system_selected.connect(_select_system)
	body.add_child(_map)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 320
	sidebar.add_theme_constant_override("separation", 12)
	body.add_child(sidebar)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.text = "Mando de Veyra\nSelecciona una flota y pulsa un sistema vecino."
	sidebar.add_child(_details)
	_fleet_picker = OptionButton.new()
	_fleet_picker.item_selected.connect(_select_fleet)
	sidebar.add_child(_fleet_picker)
	_add_button(sidebar, "Reforzar: +4 naves / 10 créditos", _reinforce)
	_add_button(sidebar, "Cancelar órdenes", _cancel_orders)
	_end_button = _add_button(sidebar, "Resolver turno →", _end_turn)
	_add_button(sidebar, "Nueva campaña", _new_campaign)
	_reports = RichTextLabel.new()
	_reports.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(_reports)
	var legend := Label.new()
	legend.text = "DORADO: VEYRA   /   CIAN: LIGA   /   GRIS: NEUTRAL\nObjetivo: eliminar todas las flotas rivales."
	column.add_child(legend)


func _add_button(parent: Node, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _new_campaign() -> void:
	_service = Service.new(Factory.new().create(), Combat.new(), StrategicAI.new())
	_selected_fleet = 0
	_map.selected_system = -1
	_reports.text = "Crisis del Meridiano\nLa Liga avanza hacia los mundos neutrales.\n"
	_refresh()


func _refresh() -> void:
	var state: RefCounted = _service.state
	_status.text = "Turno %d  ·  Tesoro: %d  ·  Órdenes pendientes: %d" % [
		state.turn, state.credits.veyra, _service.pending_orders.size()
	]
	_end_button.disabled = not state.winner.is_empty()
	if not state.winner.is_empty():
		_status.text += "  ·  Resultado: " + state.winner
	_fleet_picker.clear()
	for fleet in state.fleets:
		if fleet.owner == "veyra":
			_fleet_picker.add_item("%s (%d)" % [fleet.name, fleet.ships], fleet.id)
			if fleet.id == _selected_fleet:
				_fleet_picker.select(_fleet_picker.item_count - 1)
	if state.fleet_by_id(_selected_fleet).is_empty():
		_selected_fleet = -1
		if _fleet_picker.item_count > 0:
			_selected_fleet = _fleet_picker.get_item_id(0)
	_fleet_picker.disabled = _fleet_picker.item_count == 0
	_map.campaign = state
	_map.orders = _service.pending_orders
	_map.queue_redraw()


func _select_fleet(index: int) -> void:
	_selected_fleet = _fleet_picker.get_item_id(index)
	var fleet: Dictionary = _service.state.fleet_by_id(_selected_fleet)
	_map.selected_system = fleet.system
	_map.queue_redraw()


func _select_system(id: int) -> void:
	_map.selected_system = id
	var system: Dictionary = _service.state.system_by_id(id)
	_details.text = "%s\nControl: %s · Ingresos: %d" % [system.name, system.owner, system.income]
	var error: String = _service.order_move(_selected_fleet, id)
	_reports.append_text(("Orden registrada." if error.is_empty() else error) + "\n")
	_refresh()


func _reinforce() -> void:
	var error: String = _service.reinforce(_selected_fleet)
	_reports.append_text(("Refuerzos incorporados." if error.is_empty() else error) + "\n")
	_refresh()


func _cancel_orders() -> void:
	_service.pending_orders.clear()
	_refresh()


func _end_turn() -> void:
	for report in _service.end_turn():
		_reports.append_text(report + "\n")
	_refresh()
