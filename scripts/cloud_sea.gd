extends Node2D
## Pixel cloud banks authored in Aseprite. Drawn below the islands and cached.
const BANK = preload("res://assets/pixel/world/cloud_bank.png")

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41027
	for i in range(58):
		var center := Vector2(rng.randf_range(-2400, 7700), rng.randf_range(-3600, 6700)).round()
		var frame := i % 4
		for j in range(2):
			var p := center + Vector2(j * 260, rng.randi_range(-85, 85))
			draw_texture_rect_region(BANK, Rect2(p - Vector2(350, 175), Vector2(700, 350)), Rect2(frame * 256, 0, 256, 128))
