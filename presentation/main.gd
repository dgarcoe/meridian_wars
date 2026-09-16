extends Control
## Composition root for the operation, campaign deck, persistence and tactical view.

const UI = preload("res://presentation/deck_theme.gd")
const Operation = preload("res://domain/operation.gd")
const Store = preload("res://infrastructure/operation_store.gd")
const SectorMap = preload("res://presentation/sector_map.gd")
const BattleView = preload("res://presentation/battle_view.gd")

var operation = Operation.new()
var _store = Store.new()
var _screen: Control
var _notice: String = "Enlace de mando establecido."
var _selected_system: int = 2
var _leader: int = 0
var _choice: String = "protect"


func _ready() -> void:
	theme = UI.create()
	_show_deck()


func _clear_screen() -> void:
	if is_instance_valid(_screen):
		remove_child(_screen)
		_screen.queue_free()
	_screen = MarginContainer.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		_screen.add_theme_constant_override("margin_" + side, 24)
	add_child(_screen)


func _show_deck() -> void:
	_clear_screen()
	var column := VBoxContainer.new()
	_screen.add_child(column)
	_build_header(column)
	var body := HBoxContainer.new()
	body.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(body)
	_build_fleet_panel(body)
	_build_map_panel(body)
	_build_operation_panel(body)
	_build_footer(column)


func _build_header(parent: Node) -> void:
	var header := HBoxContainer.new()
	parent.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(UI.label("M E R I D I A N  /  W A R S", 25, UI.GOLD))
	brand.add_child(UI.label("COMANDO ESTRATÉGICO   /   CORONA DE VEYRA", 12, UI.MUTED))
	for metric in [["TESORO", "%03d CR" % operation.credits], ["APOYO CIVIL", "%d%%" % operation.support], ["CICLO", "%02d" % operation.turn]]:
		var box := UI.panel(header)
		box.add_child(UI.label(metric[0], 11, UI.MUTED))
		box.add_child(UI.label(metric[1], 22))
	header.add_child(UI.button("Guardar", _save))
	header.add_child(UI.button("Cargar", _load))
	header.add_child(UI.button("Reiniciar", _confirm_restart))


func _build_fleet_panel(parent: Node) -> void:
	var column := UI.panel(parent, 240)
	column.add_child(UI.label("01  /  FUERZA EXPEDICIONARIA", 12, UI.GOLD))
	column.add_child(UI.label("Grupo Aurora", 25))
	column.add_child(UI.paragraph("%d naves · %d%% suministros" % [operation.total_ships(), operation.supply]))
	column.add_child(UI.bar(operation.supply))
	column.add_child(HSeparator.new())
	var commander: Dictionary = Operation.COMMANDERS[operation.commander]
	column.add_child(UI.label("OFICIAL AL MANDO", 11, UI.MUTED))
	column.add_child(UI.label(commander.name, 20))
	column.add_child(UI.paragraph(commander.role + "\n" + commander.detail, UI.GOLD))
	column.add_child(HSeparator.new())
	var titles := ["01  VANGUARDIA", "02  LÍNEA DE BATALLA", "03  APOYO DE FUEGO"]
	var classes := ["Fragatas", "Cruceros", "Porta-lanzas"]
	for i in range(3):
		column.add_child(UI.label(titles[i], 12, UI.MUTED))
		column.add_child(UI.label("%s  /  %02d" % [classes[i], operation.ships[i]], 19))
		column.add_child(UI.bar(operation.ships[i] * 12.5))
		var reinforce := UI.button("+1 nave · 30 CR", _reinforce.bind(i))
		reinforce.disabled = operation.phase != "deployment" or operation.credits < 30 or operation.ships[i] >= 8
		column.add_child(reinforce)


func _build_map_panel(parent: Node) -> void:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = SIZE_EXPAND_FILL
	parent.add_child(column)
	var title := HBoxContainer.new()
	column.add_child(title)
	var label := UI.label("TEATRO DE OPERACIONES", 14, UI.MUTED)
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_child(label)
	title.add_child(UI.label("●  INTEL ACTUALIZADA", 11, UI.CYAN))
	var map := SectorMap.new()
	map.operation = operation
	map.selected = _selected_system
	map.system_selected.connect(_inspect)
	column.add_child(map)
	var details := UI.panel(column)
	details.add_child(UI.label(SectorMap.NAMES[_selected_system] + "  /  " + ("PUNTO DE CONTACTO" if _selected_system == 2 else "SISTEMA ESTELAR"), 17))
	details.add_child(UI.paragraph("Nártex controla el paso del convoy civil. Tres escuadras de la Liga convergen sobre el corredor." if _selected_system == 2 else "Nodo cartográfico del sector. La misión actual sigue el corredor Veyra → Sereva → Nártex."))


func _build_operation_panel(parent: Node) -> void:
	var column := UI.panel(parent, 290)
	column.add_child(UI.label("02  /  OPERACIÓN ACTIVA", 12, UI.GOLD))
	column.add_child(UI.label("El paso de Nártex", 25))
	column.add_child(UI.label("CRISIS FRONTERIZA  /  001", 12, UI.RED))
	column.add_child(HSeparator.new())
	match operation.phase:
		"briefing":
			_briefing(column)
		"deployment":
			column.add_child(UI.paragraph("La fuerza está lista. Asigna refuerzos y avanza por el corredor. Cada salto consume 15% de suministros."))
			column.add_child(UI.label("RUTA ASIGNADA", 12, UI.GOLD))
			column.add_child(UI.paragraph("Veyra → Sereva → Nártex"))
			column.add_child(UI.button("Saltar a " + ("Sereva" if operation.location == 0 else "Nártex") + " →", _advance, true))
		"contact":
			column.add_child(UI.paragraph("Contacto confirmado. Quince naves de la Liga bloquean el paso. La formación espera tus órdenes."))
			column.add_child(UI.paragraph("Protección: resistir 120 segundos o eliminar al enemigo." if operation.doctrine == "protect" else "Interdicción: eliminar al enemigo antes de 300 segundos.", UI.GOLD))
			column.add_child(UI.button("Asumir mando táctico →", _launch, true))
		"debrief":
			_debrief(column)
	var spacer := Control.new()
	spacer.size_flags_vertical = SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(HSeparator.new())
	column.add_child(UI.label("DOCTRINA OPERACIONAL", 11, UI.MUTED))
	column.add_child(UI.paragraph("La victoria militar no compensa cualquier coste civil. Decide qué estás dispuesto a perder."))


func _briefing(column: VBoxContainer) -> void:
	column.add_child(UI.paragraph("Un convoy civil cruza Nártex. La Liga se aproxima. El Consejo exige una respuesta: proteger la evacuación o destruir la fuerza rival."))
	column.add_child(UI.label("ELIGE AL COMANDANTE", 11, UI.MUTED))
	for i in range(2):
		var commander: Dictionary = Operation.COMMANDERS[i]
		column.add_child(UI.button(("● " if _leader == i else "○ ") + commander.name, _choose_leader.bind(i)))
	column.add_child(UI.paragraph(Operation.COMMANDERS[_leader].detail, UI.GOLD))
	column.add_child(UI.button(("● " if _choice == "protect" else "○ ") + "Proteger el convoy", _choose_doctrine.bind("protect")))
	column.add_child(UI.button(("● " if _choice == "interdict" else "○ ") + "Interceptar a la Liga", _choose_doctrine.bind("interdict")))
	column.add_child(UI.button("Autorizar operación →", _authorize, true))


func _debrief(column: VBoxContainer) -> void:
	var titles := {"victory": "OBJETIVO CUMPLIDO", "defeat": "FUERZA PERDIDA", "retreat": "RETIRADA CONFIRMADA"}
	column.add_child(UI.label(titles.get(operation.result, "INFORME"), 17, UI.GOLD))
	column.add_child(UI.paragraph("%d naves regresan.\nApoyo civil: %d%%.\nTesoro: %d CR." % [operation.total_ships(), operation.support, operation.credits]))
	column.add_child(UI.paragraph("Nártex queda bajo protección de Veyra." if operation.result == "victory" else "El corredor permanece bajo amenaza de la Liga."))
	column.add_child(UI.paragraph("Fin de esta misión. Puedes guardar el resultado o reiniciar con otra doctrina y comandante."))


func _build_footer(parent: Node) -> void:
	var column := UI.panel(parent)
	var row := HBoxContainer.new()
	column.add_child(row)
	var title := UI.label("REGISTRO DE OPERACIONES", 11, UI.GOLD)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(UI.label(_notice, 12, UI.MUTED))
	var text := ""
	for i in range(maxi(0, operation.log.size() - 2), operation.log.size()):
		text += "›  " + operation.log[i] + "\n"
	column.add_child(UI.label(text.strip_edges(), 14, UI.MUTED))


func _choose_leader(id: int) -> void:
	_leader = id
	_show_deck()


func _choose_doctrine(choice: String) -> void:
	_choice = choice
	_show_deck()


func _authorize() -> void:
	operation.prepare(_choice, _leader)
	_show_deck()


func _reinforce(id: int) -> void:
	operation.reinforce(id)
	_show_deck()


func _advance() -> void:
	operation.advance()
	_selected_system = operation.location
	_show_deck()


func _inspect(id: int) -> void:
	_selected_system = id
	_show_deck()


func _launch() -> void:
	if not operation.launch():
		return
	_clear_screen()
	var battle := BattleView.new()
	battle.configure(operation.ships, operation.commander, operation.doctrine)
	battle.finished.connect(_battle_finished)
	_screen.add_child(battle)


func _battle_finished(outcome: String, survivors: Array[int]) -> void:
	if operation.resolve(outcome, survivors):
		_notice = "Informe táctico recibido."
		_show_deck()


func _save() -> void:
	_notice = "Partida guardada." if _store.save(operation) == OK else "No se pudo guardar la partida."
	_show_deck()


func _load() -> void:
	var loaded = _store.load_operation()
	if loaded == null:
		_notice = "No hay una partida válida."
	else:
		operation = loaded
		_leader = operation.commander
		_choice = operation.doctrine
		_notice = "Partida restaurada."
	_show_deck()


func _confirm_restart() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "¿Reiniciar la operación? El progreso no guardado se perderá."
	dialog.confirmed.connect(func() -> void:
		operation = Operation.new()
		_notice = "Nueva operación."
		_show_deck()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()
