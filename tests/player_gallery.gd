extends SceneTree

func _initialize() -> void: _capture.call_deferred()

func _capture() -> void:
	root.content_scale_size = Vector2i(1000, 240)
	DisplayServer.window_set_size(Vector2i(1000, 240))
	for i in range(8):
		var p := load("res://player.tscn").instantiate() as Swordsman
		root.add_child(p)
		p.set_physics_process(false)
		p.position = Vector2(80 + i * 120, 175)
		p.facing = i
		p.walking = true
		p.animation_time = 0.4
		p.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reference/player-directions.png"))
	quit()
