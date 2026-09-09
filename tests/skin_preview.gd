extends SceneTree

func _initialize() -> void: capture.call_deferred()

func capture() -> void:
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	var game = world.ground
	game.player.input_enabled = false
	game.count_slider.value = 24
	var ancestor: Node = game.skin_picker
	while ancestor != null and not ancestor is TabContainer: ancestor = ancestor.get_parent()
	if ancestor is TabContainer: ancestor.current_tab = 2
	for i in range(45): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reference/skin-switch-preview.png"))
	quit()
