extends SceneTree
## Rendered, fixed simulation workload. Run with --fixed-fps 60, not --headless.
var frame: int = 0
var previous: int = 0
var samples: Array[float] = []
var draw_calls: Array[float] = []
var scene: Node
var count: int = 160
var lifetime: float = 0.48
var flight_mode: int = 2
var skill_name: String = "none"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bench-count="): count = int(arg.get_slice("=", 1))
		if arg.begins_with("--bench-trail="): lifetime = float(arg.get_slice("=", 1))
		if arg.begins_with("--bench-mode="): flight_mode = int(arg.get_slice("=", 1))
		if arg.begins_with("--bench-skill="): skill_name = arg.get_slice("=", 1)
	_setup.call_deferred()

func _setup() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.count_slider.value = count
	scene.swarm.trail_lifetime = lifetime
	scene._select_mode(flight_mode)
	if skill_name == "river":
		scene.swarm.river_duration = 12.0
		scene.swarm.begin_river(Vector2(100, 450), Vector2(1000, 450))
		scene.swarm.release_river()
	previous = Time.get_ticks_usec()

func _process(_dt: float) -> bool:
	if previous == 0: return false
	var now := Time.get_ticks_usec()
	var ms := float(now - previous) / 1000.0
	previous = now
	frame += 1
	if frame > 90:
		samples.append(ms)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if frame == 390:
		var total := 0.0
		var calls := 0.0
		for value in samples: total += value
		for value in draw_calls: calls += value
		samples.sort()
		print("BENCHMARK ", JSON.stringify({"count": count, "trail": lifetime, "mode": flight_mode, "skill": skill_name,
			"frames": samples.size(), "mean_ms": total / samples.size(),
			"p95_ms": samples[int(samples.size() * 0.95)], "draw_calls": calls / draw_calls.size(),
			"renderer": RenderingServer.get_video_adapter_name()}))
		quit()
	return false
