extends SceneTree
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	var player: Swordsman = game.player
	player.set_physics_process(false)
	game.swarm.set_physics_process(false)
	var origin := Vector2(520, 445)
	for direction in range(8):
		player.position = origin
		player.step_movement(Vector2.from_angle(direction * PI / 4), 0.1)
		check(player.facing == direction, "Missing facing direction " + str(direction))
		check(absf(player.position.distance_to(origin) - 24) < 0.01, "All directions must have equal speed")
	player.position = origin
	key(KEY_W, true)
	key(KEY_D, true)
	player._physics_process(0.1)
	check(player.position.x > origin.x and player.position.y < origin.y, "W+D must move diagonally")
	check(absf(player.position.distance_to(origin) - 24) < 0.01, "Diagonal input must be normalized")
	key(KEY_W, false)
	key(KEY_D, false)
	var stopped := player.position
	player._physics_process(0.1)
	check(player.position == stopped, "Key release must stop movement")
	key(KEY_LEFT, true)
	player._physics_process(0.1)
	check(player.position.x < stopped.x, "Arrow keys must move player")
	key(KEY_LEFT, false)
	game._toggle_pause()
	stopped = player.position
	player.step_movement(Vector2.RIGHT, 1.0)
	check(player.position == stopped, "Pause must stop character")
	game._toggle_pause()
	player.position = origin
	player.step_movement(Vector2.ONE, 100.0)
	check(player.position.x <= player.movement_bounds.end.x and player.position.y <= player.movement_bounds.end.y, "Stay inside arena")
	player.position = origin
	player.step_movement(Vector2.RIGHT, 0.1)
	check(game.swarm.focus == player.position, "Default orbit must follow player")
	game.follow_toggle.button_pressed = false
	var fixed: Vector2 = game.swarm.focus
	player.step_movement(Vector2.RIGHT, 0.1)
	check(game.swarm.focus == fixed, "Fixed-point orbit must remain available")
	game.swarm.begin_charge(game._cast_position())
	check(game.swarm.skill_center == player.position, "Charge must originate from player")
	player.step_movement(Vector2.RIGHT, 0.1)
	check(game.swarm.skill_center == player.position, "Charge must follow moving caster")
	game.swarm.release_charge()
	var launch: Vector2 = game.swarm.skill_center
	player.step_movement(Vector2.RIGHT, 0.1)
	check(game.swarm.skill_center == launch, "Released cast must stay in world space")
	game.swarm.recall()
	player.step_movement(Vector2.DOWN, 0.1)
	game.swarm._physics_process(1.0 / 60)
	check(game.swarm.skill_center == player.position, "Recall must follow moving character")
	if failures == 0: print("PLAYER_TEST_OK facing8=ok diagonal_speed=ok WASD/arrows=ok key_release=ok pause=ok bounds=ok orbit=ok cast_anchor=ok recall=ok")
	quit(0 if failures == 0 else 1)
