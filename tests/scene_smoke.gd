extends SceneTree
## Exercises the real screen lifecycle without human input, including the 3D scene.

const Main = preload("res://presentation/main.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main := Main.new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	main._choose_leader(1)
	main._authorize()
	main._reinforce(0)
	main._advance()
	main._advance()
	await process_frame
	main._launch()
	await process_frame
	var battle = main._screen.get_child(0)
	battle._focus_fire()
	battle._toggle_pause()
	for frame in range(30):
		battle.simulation.advance(.5)
		await process_frame
	battle.simulation.retreat()
	battle._finish()
	await process_frame
	if main.operation.phase != "debrief":
		push_error("Mission did not reach debrief")
		quit(1)
		return
	print("Scene smoke: briefing → deployment → 3D battle → debrief OK")
	main.queue_free()
	await process_frame
	quit(0)
