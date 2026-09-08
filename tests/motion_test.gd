extends SceneTree
const Swarm = preload("res://scripts/sword_swarm.gd")
var failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func make_swarm() -> SwordSwarm:
	var result := Swarm.new()
	result.sword_count = 1
	root.add_child(result)
	result.set_physics_process(false)
	return result

func _run() -> void:
	var a := make_swarm()
	var b := make_swarm()
	a.wander_amount = 0
	a.loop_amount = 0
	a.roll_amount = 0
	b.wander_amount = 0
	b.loop_amount = 0
	b.roll_amount = 1
	b.swords[0].roll_wait = 0
	var saw_roll := false
	for frame in range(240):
		a.elapsed += 1.0 / 60
		b.elapsed += 1.0 / 60
		a._step_sword(a.swords[0], 0, 1.0 / 60)
		b._step_sword(b.swords[0], 0, 1.0 / 60)
		check(a.swords[0].p.is_equal_approx(b.swords[0].p), "Axial roll must not alter path")
		check(a.swords[0].roll == 0.0, "Zero roll must disable axial motion")
		check(a.swords[0].loop_left == 0.0, "Zero loop must disable trajectory loops")
		saw_roll = saw_roll or b.swords[0].roll > PI
	check(saw_roll, "Independent axial roll must expose the rear face")
	b.roll_amount = 0
	b._step_sword(b.swords[0], 0, 1.0 / 60)
	check(b.swords[0].roll == 0, "Disabling roll must settle the blade")
	for mode in range(3):
		a.set_mode(mode)
		a.targets = [{"p": Vector2(800, 450), "respawn": 0.0}]
		for rate in [30.0, 95.0, 360.0]:
			a.turn_rate = rate
			a.loop_amount = 1
			a.swords[0].loop_wait = 0
			for frame in range(180):
				var s: SwordSwarm.Sword = a.swords[0]
				var before := s.angle
				a._step_sword(s, 0, 1.0 / 60)
				check(absf(wrapf(s.angle - before, -PI, PI)) <= deg_to_rad(rate) / 60.0 + 0.00001, "Heading exceeded angular speed cap")
				check(absf(wrapf(s.v.angle() - s.angle, -PI, PI)) < 0.00001, "Blade must be tangent to motion")
				check(is_finite(s.p.x) and is_finite(s.p.y), "Motion must remain finite")
	# Ring storage remains bounded at the largest supported count and trail length.
	a.sword_count = 160
	a.trail_lifetime = 1.1
	for frame in range(150): a._physics_process(1.0 / 60)
	check(a.trail_mesh.visible_instance_count <= 160 * Swarm.TRAIL_CAP, "Trail exceeded fixed allocation")
	check(a.blade_mesh.instance_count == 160, "Blade instance count mismatch")
	for s in a.swords: check(s.trail.size() == Swarm.TRAIL_CAP, "Ring storage grew")
	a.sword_count = 1
	check(a.trail_mesh.instance_count == a.render_trail_cap, "Shrinking count must resize render capacity")
	if failures == 0: print("MOTION_TEST_OK angular_cap=3_modes/3_rates tangent=ok axial_independence=ok disabled_features=ok bounded_buffers=ok")
	quit(1 if failures else 0)
