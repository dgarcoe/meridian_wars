extends SceneTree
## Run with a real display/renderer (or Xvfb), never --headless.
## Produces genuine engine screenshots, not mockups.

const Main = preload("res://presentation/main.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600,1000)
	var main := Main.new()
	root.add_child(main)
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DirAccess.make_dir_recursive_absolute("res://build/screenshots")
	await _capture("01-command-deck")
	main._authorize()
	main._reinforce(1)
	main._advance()
	main._advance()
	await _capture("02-contact")
	main._launch()
	await process_frame
	var battle = main._screen.get_child(0)
	battle._focus_fire()
	for frame in range(90):
		battle.simulation.advance(.1)
		await process_frame
	await _capture("03-tactical-battle")
	battle.simulation.retreat()
	battle._finish()
	await _capture("04-debrief")
	main.queue_free()
	await process_frame
	print("Visual capture: four engine screenshots saved")
	quit(0)


func _capture(name: String) -> void:
	for frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Renderer produced no image")
		quit(1)
		return
	if image.save_png("res://build/screenshots/" + name + ".png") != OK:
		push_error("Cannot write screenshot")
		quit(1)
	if OS.get_cmdline_user_args().has("--log-preview"):
		# Optional CI preview transport; only generated game pixels, no user files.
		image.resize(1280,800)
		print("VISUAL_PREVIEW:" + name + ":" + Marshalls.raw_to_base64(image.save_jpg_to_buffer(.8)))
