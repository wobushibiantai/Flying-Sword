extends SceneTree
## Verify the art used by live nodes, not just the existence of PNGs.
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error(what)

func run() -> void:
	var skins = root.get_node("CharacterSkins")
	check(skins.current().display_name == "像素 · 墨衣行者", "Pixel character is startup skin")
	check(skins.current().validation_error().is_empty(), "Pixel character atlas is valid")
	check(skins.current().frames_per_direction == 24, "Each facing has 24 animated poses")
	var terrain_script = load("res://scripts/island_terrain.gd")
	for i in range(3):
		var terrain := Node2D.new()
		terrain.set_script(terrain_script)
		terrain.region = i
		root.add_child(terrain)
		check(terrain.ISLANDS[i].get_size() == Vector2(2048, 1792), "Island %d uses raster art" % i)
		terrain.free()
	var game = load("res://world.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	check(game.flight_avatar.skin == skins.current() and game.ground.player.skin == skins.current(), "Ground and sky use the pixel skin")
	check(game.cloud_material.get_shader_parameter("cloud_texture") != null, "Travel shader uses the pixel cloud source")
	check(game.ground.swarm.blade_mesh != null and game.ground.swarm.trail_mesh != null, "Pixel sword and trail batches are built")
	check(game.ground.controls.theme != null, "Pixel UI theme is active")
	check(game.ground.swarm.get_child(1).texture == preload("res://assets/pixel/combat/blade.png"), "Batched swords use Aseprite texture")
	if failures == 0: print("PIXEL_ART_OK islands=3 character=24x8x5 swords/trail/ui/cloud=assets")
	quit(0 if failures == 0 else 1)
