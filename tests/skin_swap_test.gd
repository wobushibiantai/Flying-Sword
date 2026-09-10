extends SceneTree
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var wardrobe = root.get_node("CharacterSkins")
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	world.ground.set_process(false)
	world.ground.player.set_physics_process(false)
	world.ground.swarm.set_physics_process(false)
	var player = world.ground.player
	var position_before: Vector2 = player.position
	var key := InputEventKey.new()
	key.keycode = KEY_F2
	key.pressed = true
	var initial: int = wardrobe.selected
	var count: int = wardrobe.skins.size()
	for i in range(count):
		root.push_input(key, true)
		check(wardrobe.selected == (initial+i+1) % count, "F2 switches exactly once")
		check(player.skin == wardrobe.current() and world.flight_avatar.skin == player.skin, "Both avatars share selected skin")
		check(player.position == position_before, "Swap keeps player position")
	world.take_off()
	world.advance(4.3)
	root.push_input(key, true)
	check(wardrobe.selected == (initial+1)%count and world.flight_avatar.skin == wardrobe.current(), "F2 works in sky")
	world.ground.skin_picker.item_selected.emit(0)
	check(wardrobe.selected == 0, "Dropdown switches skins")
	var path := "user://skin_swap_test.png"
	var atlas: Image = wardrobe.current().atlas.get_image()
	atlas.save_png(path)
	check(wardrobe.load_external(path).is_empty(), "External PNG accepted")
	var old_texture = player.skin.atlas
	atlas.set_pixel(0, 0, Color.RED)
	atlas.save_png(path)
	check(wardrobe.reload_external().is_empty(), "Reload without restarting")
	check(player.skin.atlas != old_texture and player.skin.atlas.get_image().get_pixel(0, 0) == Color.RED, "Reload reads changed pixels")
	var selected_before: int = wardrobe.selected
	var malformed := Image.create(63, 80, false, Image.FORMAT_RGBA8)
	malformed.save_png(path)
	check(not wardrobe.load_external(path).is_empty() and wardrobe.selected == selected_before, "Invalid atlas preserves selection")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	wardrobe.select(0)
	if failures == 0: print("SKIN_SWAP_OK F2/dropdown ground/sky external_reload validation gameplay_preserved")
	quit(0 if failures == 0 else 1)
