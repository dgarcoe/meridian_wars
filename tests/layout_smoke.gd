extends SceneTree
## Layout bounds can be checked headlessly; this does not verify visual rendering.

const Main = preload("res://presentation/main.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600,1000)
	var main := Main.new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for phase in ["briefing","deployment","contact","debrief"]:
		main.operation.phase = phase
		main._show_deck()
		await process_frame
		await process_frame
		_check_bounds(main._screen, Rect2(Vector2.ZERO, Vector2(1600,1000)), phase)
	main.queue_free()
	await process_frame
	print("Layout bounds: %d failures" % failures)
	quit(0 if failures == 0 else 1)


func _check_bounds(node: Node, bounds: Rect2, phase: String) -> void:
	if node is Control and node.visible:
		var rect: Rect2 = node.get_global_rect()
		if not bounds.grow(2).encloses(rect):
			failures += 1
			push_error("%s: %s outside bounds: %s" % [phase,node.get_class(),rect])
	for child in node.get_children():
		_check_bounds(child,bounds,phase)
