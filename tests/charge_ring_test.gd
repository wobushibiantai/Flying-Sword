extends SceneTree
var failures: int = 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	game.swarm.set_physics_process(false)
	var swarm: SwordSwarm = game.swarm
	check(swarm.z_index > game.player.z_index, "Swords must render above player")
	for variant in range(3):
		if variant == 0: swarm.begin_charge(game.player.position)
		else: swarm.begin_river(game.player.position, Vector2(1000, 450), variant)
		# Include a sword initially inside the player's body.
		swarm.swords[0].p = swarm.charge_orbit_center()
		for frame in range(360):
			if frame > 180 and frame < 240:
				game.player.step_movement(Vector2.RIGHT, 1.0 / 60)
			swarm._physics_process(1.0 / 60)
			for blade in swarm.swords:
				# Sword reaches at most 24 pixels inward; the body fits inside 60.
				check(blade.p.distance_to(swarm.charge_orbit_center()) >= 87.99, "Charging sword must clear body even while caster moves")
		var sectors := {}
		for blade in swarm.swords:
			var offset: Vector2 = blade.p - swarm.charge_orbit_center()
			check(absf(offset.length() - swarm.charge_radius) < 6.0, "Ring must settle at requested radius")
			sectors[posmod(floori(offset.angle() / TAU * 8), 8)] = true
		check(sectors.size() == 8, "Charging ring must surround all sides")
		var old_position: Vector2 = swarm.swords[0].p
		for frame in range(40): swarm._physics_process(1.0 / 60)
		check(old_position.distance_to(swarm.swords[0].p) > 15, "Ring must rotate while held")
		if variant == 0:
			swarm.release_charge()
			for blade in swarm.swords:
				check((blade.p - swarm.charge_orbit_center()).dot(blade.v) > 0, "Burst must fly outward from ring")
		else:
			swarm.release_river()
			swarm._physics_process(1.0 / 60)
			check(swarm.swords[-1].p.distance_to(swarm.charge_orbit_center()) >= 88, "Waiting river swords must stay outside body")
	if failures == 0: print("CHARGE_RING_OK layering=ok body_clearance=ok moving_caster=ok full_circle=ok rotation=ok burst=ok river_wait=ok")
	quit(0 if failures == 0 else 1)
