class_name Swordsman
extends Node2D
## Aseprite Lua-authored animation atlas, feet-origin, eight directions.
signal moved
@export_range(30.0, 900.0) var move_speed: float = 240.0
var movement_bounds := Rect2(50, 115, 985, 725)
var paused: bool = false
var input_enabled: bool = true
var casting: bool = false
var flying: bool = false
var flight_moving: bool = true
var aim := Vector2.RIGHT
var facing: int = 2
var walking: bool = false
var animation_time: float = 0.0
var velocity := Vector2.ZERO
var skin: CharacterSkin

func _ready() -> void:
	get_node("/root/CharacterSkins").changed.connect(_refresh_skin)
	_refresh_skin()

func _refresh_skin() -> void:
	skin = get_node("/root/CharacterSkins").current()
	queue_redraw()

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO
	if input_enabled:
		direction.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
		direction.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	step_movement(direction, delta)

func step_movement(direction: Vector2, delta: float) -> void:
	if paused:
		velocity = Vector2.ZERO
		return
	direction = direction.limit_length(1.0)
	var previous := position
	position = (position + direction * move_speed * delta).clamp(movement_bounds.position, movement_bounds.end)
	velocity = (position - previous) / maxf(delta, 0.00001)
	walking = velocity.length_squared() > 1.0
	animation_time += delta
	var look := aim if casting else direction
	if look.length_squared() > 0.01:
		facing = posmod(roundi(look.angle() / (PI / 4.0)), 8)
	if position != previous: moved.emit()
	queue_redraw()

func _draw() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not flying: draw_ellipse_shadow()
	var state_index := animation_state_index()
	var fps := 10.0 if state_index > 0 else (1.0 / 0.18)
	var frame := posmod(int(animation_time * fps), 8)
	if skin == null: return
	var size := Vector2(skin.frame_size)
	var region := Rect2(Vector2(frame, state_index * 8 + facing) * size, size)
	# Foot pivot stays fixed; sprite height fits the existing charge-ring clearance.
	draw_texture_rect_region(skin.atlas, Rect2(-skin.foot_pivot * skin.display_scale, size * skin.display_scale), region)

func animation_state_index() -> int:
	if flying: return 3 if flight_moving else 4
	return 2 if casting else (1 if walking else 0)

func update_cast_pose(active: bool, target: Vector2) -> void:
	casting = active
	aim = target - position
	# Refresh immediately even while stationary, independently of movement ticks.
	if casting and not paused and aim.length_squared() > 0.01:
		facing = posmod(roundi(aim.angle() / (PI / 4.0)), 8)
	queue_redraw()

func draw_ellipse_shadow() -> void:
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.28))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.20))
	draw_set_transform(Vector2.ZERO)
