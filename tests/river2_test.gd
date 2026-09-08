extends SceneTree
const Swarm = preload("res://scripts/sword_swarm.gd")
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func simulate(variant: int, thickness: float, fill: float) -> Dictionary:
	var s := Swarm.new()
	s.sword_count = 48
	s.river_band_thickness = thickness
	s.river_fill_ratio = fill
	root.add_child(s)
	s.set_physics_process(false)
	s.begin_river(Vector2(180, 450), Vector2(1000, 450), variant)
	for frame in range(180): s._physics_process(1.0 / 60)
	# Beyond the ring-to-river entry, test the same phase one wavelength downstream.
	s.targets = [{"p": Vector2(680, 450)}]
	s.release_river()
	var snapshot := PackedVector2Array()
	for frame in range(230):
		s._physics_process(1.0 / 60)
		if frame == 120:
			for blade in s.swords: snapshot.append(blade.p)
	var result := {"positions": snapshot, "hits": s.hits}
	for frame in range(2700): s._physics_process(1.0 / 60)
	check(s.skill == Swarm.Skill.NONE, "Type II must return after casting")
	s.free()
	return result

func _run() -> void:
	var pure := simulate(1, 0, 0)
	var thin := simulate(2, 0, 0.65)
	var wide := simulate(2, 160, 0)
	var wide_fill := simulate(2, 160, 0.65)
	var spread := 0
	for i in range(48):
		check(pure.positions[i].distance_to(thin.positions[i]) < 0.01, "Zero thickness must reproduce pure helices")
		check(wide.positions[i].distance_to(wide_fill.positions[i]) < 0.01, "Type II must ignore type I fill")
		var delta: Vector2 = wide.positions[i] - pure.positions[i]
		check(absf(delta.x) < 0.01, "Thickening must preserve forward progression")
		check(absf(delta.y) <= 80.01, "Swords must stay in requested band")
		if absf(delta.y) > 20: spread += 1
	check(spread >= 24, "Actual sword positions must spread across the band")
	check(thin.hits == 0 and wide.hits > 0, "Thicker paths must gain actual hit coverage")
	print("RIVER2_RESULTS thin_hits=", thin.hits, " wide_hits=", wide.hits, " spread_swords=", spread)
	if failures == 0: print("RIVER2_OK pure_helix=ok no_fill=ok physical_thickness=ok hit_coverage=ok recall=ok")
	quit(0 if failures == 0 else 1)
