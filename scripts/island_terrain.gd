extends Node2D
## Static terrain is drawn once and cached by CanvasItem; no per-frame tile rebuild.
@export var region: int = 0
const PALETTES := [
	[Color("304f3c"), Color("385d43"), Color("779271"), Color("202f30")],
	[Color("645140"), Color("77583e"), Color("c8a775"), Color("3f3033")],
	[Color("526f78"), Color("62838a"), Color("b6d7d6"), Color("344557")]]

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260908 + region * 123
	var colors: Array = PALETTES[region]
	var center := Vector2(560, 450)
	var rim := PackedVector2Array()
	for i in range(28):
		var a := float(i) / 28 * TAU
		var r := rng.randf_range(0.90, 1.06)
		rim.append(center + Vector2(cos(a) * 1620, sin(a) * 1230) * r)
	var cliff := PackedVector2Array()
	for p in rim: cliff.append(p + Vector2(0, 290))
	draw_colored_polygon(cliff, colors[3])
	for i in range(rim.size()):
		var next := (i + 1) % rim.size()
		if rim[i].y > center.y:
			draw_colored_polygon(PackedVector2Array([rim[i], rim[next], cliff[next], cliff[i]]), colors[3].lightened(0.04 * (i % 3)))
	draw_colored_polygon(rim, colors[0])
	var edge := rim.duplicate()
	edge.append(rim[0])
	draw_polyline(edge, colors[2].darkened(0.3), 18, false)
	# Patches, rock chips and grasses leave the playable center open.
	for i in range(600):
		var p := center + Vector2(rng.randf_range(-1450, 1450), rng.randf_range(-1080, 1080))
		if not Geometry2D.is_point_in_polygon(p, rim): continue
		p = p.snapped(Vector2(8, 8))
		var w := rng.randi_range(2, 10) * 8
		draw_rect(Rect2(p, Vector2(w, rng.randi_range(1, 4) * 8)), Color(colors[1], 0.5))
		if i % 4 == 0:
			draw_rect(Rect2(p, Vector2(4, 9)), Color(colors[2], 0.20))
			draw_rect(Rect2(p + Vector2(7, 3), Vector2(4, 6)), Color(colors[2], 0.15))
	# Worn stepping stones through the training ground.
	for i in range(19):
		var p := Vector2(110 + i * 54, 485 + sin(i * 0.8) * 24).snapped(Vector2(4, 4))
		draw_rect(Rect2(p, Vector2(40, 24)), Color(colors[2], 0.18))
		draw_line(p + Vector2(4, 22), p + Vector2(35, 22), Color(colors[3], 0.35), 3)
	# Landmarks outside the fighting area become legible from the sky.
	for p in [Vector2(-350, 150), Vector2(250,-300), Vector2(1390, 350), Vector2(620, 1140), Vector2(-150, 930)]:
		if region == 2:
			for j in range(4):
				var q: Vector2 = p + Vector2(j * 37, (j % 2) * 25)
				draw_colored_polygon(PackedVector2Array([q, q+Vector2(25,-105-j*12), q+Vector2(50,0), q+Vector2(23,28)]), Color("a2ced2"))
				draw_colored_polygon(PackedVector2Array([q+Vector2(25,-105-j*12), q+Vector2(50,0), q+Vector2(23,28)]), Color("689eaf"))
		else:
			draw_rect(Rect2(p + Vector2(-13,-20),Vector2(26,95)), Color("463d2c"))
			var leaf := Color("486838") if region == 0 else Color("ba7946")
			for j in range(3):
				draw_rect(Rect2(p + Vector2(-90+j*16,-135-j*32),Vector2(180-j*32,75)), leaf.lightened(j * 0.05))
	# Ancient landing platform, large enough to read as an island landmark.
	var pad := center + Vector2(0, -380)
	draw_rect(Rect2(pad-Vector2(190,100),Vector2(380,200)), colors[3].lightened(0.15))
	draw_rect(Rect2(pad-Vector2(164,78),Vector2(328,156)), colors[0].lightened(0.15))
	draw_arc(pad, 56, 0, TAU, 32, colors[2], 8, false)
	draw_line(pad-Vector2(32,0),pad+Vector2(32,0), colors[2], 6)
