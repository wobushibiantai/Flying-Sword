extends SceneTree
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var wardrobe = root.get_node("CharacterSkins")
	var hd: CharacterSkin = load("res://assets/character/hd.tres")
	check(hd.validation_error().is_empty(), "HD resource validates all five pages")
	check(hd.frame_size == Vector2i(384,640), "Native HD frame size preserved")
	check(hd.frames_per_direction == 24 and hd.animation_fps == 30.0, "HD actions have 24 frames at 30 FPS")
	for action in range(5):
		var page := hd.texture_for_state(action)
		var regions := {}
		for direction in range(8):
			for frame in range(hd.frames_per_direction):
				var r := hd.frame_region(action,direction,frame)
				check(Rect2(Vector2.ZERO,page.get_size()).encloses(r),"Every HD frame fits its action page")
				check(not regions.has(r.position), "Packed directions never overlap or repeat frames")
				regions[r.position] = true
		var fps := hd.idle_fps if action == 0 else hd.animation_fps
		for frame in range(24):
			check(hd.frame_at_time(action, (frame+0.5)/fps) == frame, "Every in-between frame plays in order")
		check(hd.frame_at_time(action,24.01/fps) == 0,"Loop wraps directly from frame 23 to frame 0")
	check(is_equal_approx(24.0/hd.animation_fps,0.8),"Added frames retain the original action cycle duration")
	var classic: CharacterSkin = load("res://assets/character/classic.tres")
	check(classic.validation_error().is_empty() and classic.frame_at_time(1,0.75) == 7,"Classic eight-frame playback stays compatible")
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	world.ground.set_process(false)
	wardrobe.select(2)
	check(world.ground.player.skin == hd and world.flight_avatar.skin == hd, "HD selected for both avatars")
	world.ground._open_skin_detail()
	check(world.ground.detail_canvas.skin == hd,"Detail viewer uses native HD resource")
	var controls = world.ground.detail_window.get_child(0).get_child(0)
	controls.get_child(0).select(2)
	controls.get_child(0).item_selected.emit(2)
	controls.get_child(1).select(4)
	controls.get_child(1).item_selected.emit(4)
	check(world.ground.detail_canvas.action == 2 and world.ground.detail_canvas.direction == 4, "Preview action/direction controls update the rendered frame")
	controls.get_child(2).pressed.emit()
	check(world.ground.detail_canvas.skin == wardrobe.current() and wardrobe.current() != hd, "Preview skin button updates displayed resource")
	wardrobe.select(2)
	controls.get_child(1).select(2)
	controls.get_child(1).item_selected.emit(2)
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		world.ground.detail_window.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reference/hd-in-game-preview.png"))
	world.ground.detail_window.hide()
	if failures==0: print("HD_CHARACTER_OK 384x640 pages5 frames960 24_per_direction 30fps packing=ok loop=ok preview=ok")
	quit(0 if failures==0 else 1)
