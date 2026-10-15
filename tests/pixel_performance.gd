extends SceneTree
func _initialize() -> void: run.call_deferred()

func run() -> void:
	var world = load("res://world.tscn").instantiate()
	root.add_child(world)
	for i in range(90): await process_frame
	var started := Time.get_ticks_usec()
	for i in range(180): await process_frame
	var seconds := float(Time.get_ticks_usec() - started) / 1000000.0
	print("PIXEL_PERF ground_fps=%.1f draw_calls=%d" % [180.0 / seconds, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	quit()
