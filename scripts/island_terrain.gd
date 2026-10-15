extends Node2D
## Three layered Aseprite landscapes; cached as one sprite draw per island.
@export_range(0, 2) var region: int = 0
const ISLANDS: Array[Texture2D] = [
	preload("res://assets/pixel/world/island_0.png"),
	preload("res://assets/pixel/world/island_1.png"),
	preload("res://assets/pixel/world/island_2.png")]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	draw_texture_rect(ISLANDS[clampi(region, 0, 2)], Rect2(-1600, -1300, 4096, 3584), false)
