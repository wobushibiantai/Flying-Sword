extends SceneTree
var failures := 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.swarm.set_physics_process(false)
	var origin: Vector2 = game.player.position
	for skill_key in [KEY_Q, KEY_E, KEY_V]:
		var key := InputEventKey.new()
		key.keycode = skill_key
		key.pressed = true
		game._input(key)
		for direction in range(8):
			var target := origin + Vector2.from_angle(direction * PI / 4.0) * 200.0
			var motion := InputEventMouseMotion.new()
			motion.position = game.get_global_transform_with_canvas() * target
			root.push_input(motion, true)
			game._process(0.0)
			check(game.player.facing == direction, "Held skill %s must follow mouse direction %s" % [skill_key, direction])
			check(game.player.animation_state_index() == 2, "All directions use casting frames")
			check(game.player.position == origin, "Stationary caster rotates without movement")
			if skill_key != KEY_Q:
				check(game.swarm.skill == SwordSwarm.Skill.RIVER_AIM, "Rotation must not release held skill")
		key.pressed = false
		game._input(key)
		game.swarm.recall()
	if failures == 0: print("CAST_DIRECTION_OK Q/E/V held mouse8 stationary pose=ok")
	quit(0 if failures == 0 else 1)
