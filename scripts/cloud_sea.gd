extends Node2D
## Clouds below the island rims, distinct from the cloud layer crossed in flight.
func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41027
	for i in range(58):
		var center := Vector2(rng.randf_range(-2400,7700),rng.randf_range(-3600,6700))
		for j in range(5):
			var p := center + Vector2(j*190,rng.randf_range(-80,80))
			draw_set_transform(p,0,Vector2(1,0.45))
			draw_circle(Vector2.ZERO,rng.randf_range(210,440),Color(0.84,0.91,0.93,0.38))
			draw_circle(Vector2(-30,-60),rng.randf_range(140,240),Color(0.96,0.98,0.97,0.32))
	draw_set_transform(Vector2.ZERO)
