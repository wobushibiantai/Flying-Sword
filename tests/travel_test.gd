extends SceneTree
var failures: int = 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	world.set_process(false)
	var ground = world.ground
	ground.set_process(false)
	ground.player.set_physics_process(false)
	ground.swarm.set_physics_process(false)
	ground.count_slider.value = 96
	ground.swarm.river_band_thickness = 125
	ground._add_target(Vector2(400,250))
	var home_target_count: int = ground.swarm.targets.size()
	for destination in [1,2,0]:
		world.take_off()
		check(world.state == world.State.ASCENDING,"Takeoff begins")
		check(world.flight_avatar.flying and world.flight_avatar.animation_state_index() == 3,"Takeoff uses hands-behind-back flight pose")
		check(ground.swarm.paused and not ground.player.input_enabled,"Combat frozen during travel")
		check(not ground.is_processing_input(),"Ground hotkeys disabled in sky")
		world.advance(1.5)
		check(world.camera.zoom.x > world.SKY_ZOOM and world.camera.zoom.x < 1,"Map shrinks continuously")
		check(world.cloud_material.get_shader_parameter("cover") > 0.5,"Ascent crosses dense cloud layer")
		world.advance(3.0)
		check(world.state == world.State.SKY,"Reach high-altitude selection")
		check(not world.flight_avatar.walking and world.flight_avatar.animation_state_index() == 3,"Sky flight never plays walking")
		var choose := InputEventKey.new()
		choose.keycode = KEY_1 + destination
		choose.pressed = true
		world._input(choose)
		world.advance(1.4)
		check(world.state == world.State.SKY,"Cruise arrives before landing")
		check(world.flight_position.distance_to(world.OFFSETS[destination]+Vector2(520,445)) < 1,"Flight arrives at selected island")
		choose.keycode = KEY_ENTER
		world._input(choose)
		check(world.current_region == destination and world.state == world.State.DESCENDING,"Land on selected region")
		world.advance(2.1)
		check(world.cloud_material.get_shader_parameter("cover") > 0.7,"Descent crosses clouds")
		world.advance(2.2)
		check(world.state == world.State.GROUND,"Landing restores gameplay")
		check(ground.position == world.OFFSETS[destination],"Correct region origin")
		check(ground.player.visible and ground.player.input_enabled and ground.is_processing_input(),"Ground input and character restored")
		check(not ground.swarm.paused and ground.swarm.sword_count == 96 and ground.swarm.river_band_thickness == 125,"Settings persist")
		check(world.camera.zoom.is_equal_approx(Vector2.ONE),"Ground camera returns to normal scale")
		world.camera.force_update_scroll()
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = ground.get_global_transform_with_canvas()*Vector2(450,350)
		ground._unhandled_input(click)
		check(ground.swarm.focus.distance_to(Vector2(450,350)) < 0.1,"Mouse remains local after changing islands")
	check(ground.swarm.targets.size() == home_target_count,"Original island target layout restored")
	ground._toggle_pause()
	world.take_off()
	world.advance(4.3)
	world.fly_to(0)
	world.advance(1.4)
	world.land()
	world.advance(4.3)
	check(ground.swarm.paused,"Existing pause preference restored")
	if failures == 0: print("TRAVEL_TEST_OK islands=3 ascent_zoom=ok clouds=ok flight=ok landing=ok saved_regions=ok input=ok parameters=ok pause=ok")
	quit(0 if failures == 0 else 1)
