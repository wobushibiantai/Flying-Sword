extends SceneTree
const Swarm = preload("res://scripts/sword_swarm.gd")

func _initialize() -> void: _run.call_deferred()

func simulate(ratio: float) -> Dictionary:
	var swarm := Swarm.new()
	swarm.sword_count = 48
	swarm.river_fill_ratio = ratio
	root.add_child(swarm)
	swarm.set_physics_process(false)
	swarm.begin_river(Vector2(180, 450), Vector2(1000, 450))
	for frame in range(180): swarm._physics_process(1.0 / 60)
	# Center at a helix crest; outer lanes near a helix crossing.
	var tally := [0, 0, 0]
	swarm.targets = [{"p": Vector2(280, 450)}, {"p": Vector2(340, 525)}, {"p": Vector2(340, 375)}]
	swarm.target_hit.connect(func(index: int, _p: Vector2) -> void: tally[index] += 1)
	swarm.release_river()
	var positions := PackedVector2Array()
	for frame in range(230):
		swarm._physics_process(1.0 / 60)
		if frame == 120:
			for blade in swarm.swords:
				positions.append(blade.p)
	var result := {"hits": tally, "positions": positions}
	swarm.free()
	return result

func _run() -> void:
	var old := simulate(0.0)
	var mixed := simulate(0.35)
	# Compare actual trajectories with the pure simulation, including its smoothing.
	var body := 0
	for i in range(48):
		if old.positions[i].distance_to(mixed.positions[i]) < 0.5: body += 1
	print("COVERAGE_COMPARISON pure_hits=", old.hits, " mixed_hits=", mixed.hits, " preserved_helix=", body, " fill=", 48 - body)
	var ok := true
	for index in range(3):
		if old.hits[index] != 0 or mixed.hits[index] <= 0:
			ok = false
			push_error("Previously empty lane must gain real swept-hit coverage: " + str(index))
	if body <= 24 or 48 - body < 8:
		ok = false
		push_error("Keep a majority on the helices and a visible minority off them")
	if ok: print("RIVER_COVERAGE_OK center_and_flanks_hit=3/3 majority_helix=ok")
	quit(0 if ok else 1)
