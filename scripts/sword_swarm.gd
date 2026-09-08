class_name SwordSwarm
extends Node2D
## Positions and bounds are local. Blade and trail rendering each use one MultiMesh.
signal target_hit(index: int, position: Vector2)
enum Mode { FOLLOW, HUNT, ORBIT }
enum Skill { NONE, CHARGE, BURST, RETURN, RIVER_AIM, RIVER }
const TRAIL_CAP := 128
const SAMPLE_DT := 1.0 / 30.0
const BLADE_SHADER = preload("res://shaders/blade.gdshader")
const TRAIL_SHADER = preload("res://shaders/trail.gdshader")
const BLADE_TEXTURE = preload("res://assets/blade.svg")

class Sword extends RefCounted:
	var p := Vector2.ZERO
	var v := Vector2.ZERO
	var angle: float = 0.0
	var phase: float = 0.0
	var radius: float = 150.0
	var pace: float = 1.0
	var tint: float = 0.0
	var angular_speed: float = 0.0
	var loop_wait: float = 0.0
	var loop_left: float = 0.0 # Remaining angular distance, radians.
	var loop_sign: float = 1.0
	var roll: float = 0.0
	var roll_left: float = 0.0
	var roll_wait: float = 0.0
	var roll_duration: float = 1.8
	var cooldown: float = 0.0
	var target: int = -1
	var seek_wait: float = 0.0
	var trail := PackedVector2Array()
	var head: int = -1
	var samples: int = 0
	var returned: bool = false

@export_range(1, 1024) var sword_count: int = 48:
	set(value):
		sword_count = clampi(value, 1, 1024)
		if is_node_ready(): _sync_count()
@export_range(10.0, 2500.0) var speed: float = 330.0
## Maximum heading change, degrees per second; lower = wider, slower turns.
@export_range(5.0, 1080.0) var turn_rate: float = 95.0
@export_range(0.0, 5.0) var wander_amount: float = 0.35
@export_range(0.0, 10.0) var roll_amount: float = 0.65
@export_range(0.0, 10.0) var loop_amount: float = 0.15
@export_range(0.02, 4.0) var trail_lifetime: float = 0.48:
	set(value):
		trail_lifetime = clampf(value, 0.02, 4.0)
		if is_node_ready(): _resize_render_buffers()
@export_range(200.0, 6000.0) var burst_speed: float = 1800.0
@export_range(96.0, 400.0) var charge_radius: float = 112.0
@export_range(50.0, 1000.0) var return_speed: float = 280.0
@export_range(30.0, 800.0) var river_width: float = 180.0
@export_range(80.0, 1600.0) var river_wavelength: float = 400.0
@export_range(100.0, 4000.0) var river_speed: float = 650.0
@export_range(1.0, 12.0) var river_duration: float = 4.0
## Preserve the main helices; distribute a minority across their empty interior.
@export_range(0.0, 0.65) var river_fill_ratio: float = 0.35
@export_range(0.0, 400.0) var river_band_thickness: float = 60.0
var river_variant: int = 1
var skill: Skill = Skill.NONE
var skill_center := Vector2.ZERO
var skill_direction := Vector2.RIGHT
var skill_time: float = 0.0
var river_distance: float = 0.0
var mode: Mode = Mode.ORBIT
var focus := Vector2(520, 445)
var return_anchor: Node2D
var bounds := Rect2(45, 140, 990, 670)
var targets: Array[Dictionary] = []
var swords: Array[Sword] = []
var sparks: Array[Dictionary] = []
var elapsed: float = 0.0
var paused: bool = false
var hits: int = 0
var rng := RandomNumberGenerator.new()
var blade_mesh: MultiMesh
var trail_mesh: MultiMesh
var blade_buffer := PackedFloat32Array()
var trail_buffer := PackedFloat32Array()
var sample_clock: float = 0.0
var trail_stride: int = 1
var render_trail_cap: int = 36

func _ready() -> void:
	rng.seed = 84932
	trail_mesh = _make_multimesh(TRAIL_SHADER, true, null)
	blade_mesh = _make_multimesh(BLADE_SHADER, false, BLADE_TEXTURE)
	_sync_count()

func _make_multimesh(shader: Shader, colors: bool, texture: Texture2D) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_2D
	mm.use_colors = colors
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(48, 20) if texture != null else Vector2.ONE
	mm.mesh = quad
	mm.custom_aabb = AABB(Vector3(-10000, -10000, -1), Vector3(20000, 20000, 2))
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = mm
	instance.texture = texture
	var mat := ShaderMaterial.new()
	mat.shader = shader
	instance.material = mat
	add_child(instance)
	return mm

func _sync_count() -> void:
	while swords.size() < sword_count:
		var s := Sword.new()
		var a := rng.randf_range(0, TAU)
		s.p = focus + Vector2(cos(a), sin(a) * 0.70) * rng.randf_range(85, 230)
		s.angle = a + PI / 2
		s.v = Vector2.from_angle(s.angle) * speed
		s.phase = rng.randf_range(0, TAU)
		s.radius = rng.randf_range(95, 235)
		s.pace = rng.randf_range(0.82, 1.18)
		s.loop_wait = rng.randf_range(2, 9)
		s.roll_wait = rng.randf_range(0.1, 3.5)
		s.roll_duration = rng.randf_range(1.4, 2.4)
		s.seek_wait = rng.randf_range(0, 0.18)
		s.tint = rng.randf()
		s.trail.resize(TRAIL_CAP)
		swords.append(s)
	while swords.size() > sword_count: swords.pop_back()
	if blade_mesh == null: return
	_resize_render_buffers()

func _resize_render_buffers() -> void:
	if blade_mesh == null: return
	# Keep every sword; only historical trail detail adapts at high counts.
	trail_stride = 1 if sword_count <= 160 else (2 if sword_count <= 384 else (4 if sword_count <= 768 else 8))
	render_trail_cap = ceili(trail_lifetime / (SAMPLE_DT * trail_stride)) + 2
	blade_mesh.instance_count = sword_count
	trail_mesh.instance_count = sword_count * render_trail_cap
	blade_buffer.resize(sword_count * 12)
	trail_buffer.resize(sword_count * render_trail_cap * 16)
	trail_buffer.fill(0)
	# Unchanging identity transforms are allocated only when count changes.
	for i in range(sword_count * render_trail_cap):
		trail_buffer[i * 16] = 1.0
		trail_buffer[i * 16 + 5] = 1.0
		trail_buffer[i * 16 + 11] = 1.0
	_update_render()

func set_mode(value: int) -> void:
	mode = value as Mode
	for s in swords:
		s.target = -1
		s.seek_wait = 0.0
		s.loop_left = 0.0

func begin_charge(center: Vector2) -> void:
	if paused: return
	skill = Skill.CHARGE
	skill_center = center
	skill_time = 0.0
	for s in swords: s.returned = false

func release_charge() -> void:
	if skill != Skill.CHARGE: return
	skill = Skill.BURST
	skill_time = 0.0
	for i in range(swords.size()):
		var s := swords[i]
		s.angle = float(i) / swords.size() * TAU + elapsed * 0.55
		s.v = Vector2.from_angle(s.angle) * burst_speed
		s.angular_speed = 0.0
		s.cooldown = 0.0

func begin_river(center: Vector2, aim: Vector2, variant: int = 1) -> void:
	if paused: return
	river_variant = 2 if variant == 2 else 1
	skill = Skill.RIVER_AIM
	skill_center = center
	aim_river(aim)
	skill_time = 0.0

func aim_river(aim: Vector2) -> void:
	if aim.distance_squared_to(skill_center) > 4.0:
		skill_direction = (aim - skill_center).normalized()

func release_river() -> void:
	if skill != Skill.RIVER_AIM: return
	skill = Skill.RIVER
	skill_time = 0.0
	river_distance = 0.0
	for s in swords:
		s.returned = false
		s.cooldown = 0.0

func recall() -> void:
	if skill == Skill.NONE: return
	if is_instance_valid(return_anchor): skill_center = return_anchor.position
	skill = Skill.RETURN
	skill_time = 0.0
	focus = skill_center
	for s in swords: s.returned = false

func flourish() -> void:
	for s in swords: s.loop_wait = rng.randf_range(0.0, 0.65) * loop_amount

func roll_blades() -> void:
	for s in swords: s.roll_wait = rng.randf_range(0.0, 0.5) * roll_amount

func _physics_process(delta: float) -> void:
	if paused: return
	elapsed += delta
	if skill == Skill.RETURN and is_instance_valid(return_anchor):
		skill_center = return_anchor.position
		focus = skill_center
	if skill != Skill.NONE:
		skill_time += delta
		if skill == Skill.RIVER: river_distance += river_speed * delta
		if (skill == Skill.BURST and skill_time >= 1.1) or (skill == Skill.RIVER and skill_time >= river_duration): recall()
	sample_clock += delta
	var sample_now := sample_clock >= SAMPLE_DT - 0.00001
	if sample_now: sample_clock = fmod(sample_clock, SAMPLE_DT)
	for i in range(swords.size()):
		var s := swords[i]
		if skill == Skill.NONE: _step_sword(s, i, delta)
		else: _step_skill(s, i, delta)
		if sample_now:
			s.head = (s.head + 1) % TRAIL_CAP
			s.trail[s.head] = s.p - Vector2.from_angle(s.angle) * 14.0
			s.samples = mini(s.samples + 1, TRAIL_CAP)
	if skill == Skill.RETURN:
		var all_returned := true
		for s in swords:
			if not s.returned: all_returned = false
		if all_returned: skill = Skill.NONE
	for i in range(sparks.size() - 1, -1, -1):
		sparks[i].life -= delta
		sparks[i].p += sparks[i].v * delta
		sparks[i].v *= exp(-delta * 3.5)
		if sparks[i].life <= 0: sparks.remove_at(i)
	_update_render()
	queue_redraw()

func _step_skill(s: Sword, index: int, dt: float) -> void:
	var previous := s.p
	s.cooldown = maxf(0.0, s.cooldown - dt)
	match skill:
		Skill.CHARGE, Skill.RIVER_AIM:
			_step_charge_ring(s, index, dt)
		Skill.BURST:
			s.p += s.v * dt # Deliberately no arena boundary force.
			_skill_hits(s, previous, s.p)
		Skill.RIVER:
			# Two opposite helices share a longitudinal axis. Each pair is spaced
			# along it; every sword moves forward, with no wrap or teleport.
			var pair := index / 2
			var train_length := minf(river_speed * river_duration * 0.75, maxf(500.0, river_wavelength * 2.0))
			var spacing := train_length / maxf(1.0, ceilf(swords.size() / 2.0) - 1.0)
			var x := river_distance - float(pair) * spacing
			var normal := skill_direction.orthogonal()
			var entry := smoothstep(0.0, river_wavelength * 0.35, maxf(0.0, x))
			if x <= 0.0:
				_step_charge_ring(s, index, dt)
				_step_roll(s, dt)
				return
			var destination := skill_center + skill_direction * maxf(x, 0.0) + normal * _river_lateral(index, x) * river_width * 0.5 * entry
			var blend := 1.0 - exp(-dt * 16.0)
			# Soft capture from the current position makes even a quick tap continuous.
			s.p = s.p.lerp(destination, blend)
			s.v = (s.p - previous) / dt
			if s.v.length_squared() > 1.0: s.angle = s.v.angle()
			_skill_hits(s, previous, s.p)
		Skill.RETURN:
			if s.returned:
				_step_sword(s, index, dt)
				return
			var diff := skill_center - s.p
			var cap := deg_to_rad(maxf(45.0, minf(turn_rate, 120.0)))
			s.angular_speed = move_toward(s.angular_speed, clampf(wrapf(diff.angle() - s.angle, -PI, PI) * 2.0, -cap, cap), cap * dt * 2.0)
			s.angle += s.angular_speed * dt
			var cruise := minf(return_speed, maxf(60.0, diff.length() * 1.2))
			s.v = Vector2.from_angle(s.angle) * move_toward(s.v.length(), cruise, maxf(burst_speed, river_speed) * dt * 3.0)
			s.p += s.v * dt
			if diff.length() < 170.0: s.returned = true
	_step_roll(s, dt)

func charge_orbit_center() -> Vector2:
	# Player coordinates are at the feet; surround the torso, including the head.
	return skill_center + (Vector2(0, -46) if is_instance_valid(return_anchor) else Vector2.ZERO)

func _step_charge_ring(s: Sword, index: int, dt: float) -> void:
	var center := charge_orbit_center()
	var radius := maxf(charge_radius, 96.0)
	var a := float(index) / swords.size() * TAU + elapsed * 0.55
	var offset := s.p - center
	var polar := offset.angle() if offset.length_squared() > 0.01 else a
	# Approach a nearby point on the ring before rotating to the assigned slot,
	# rather than taking a shortcut through the character to the opposite side.
	var waypoint := polar + clampf(wrapf(a - polar, -PI, PI), -0.4, 0.4)
	var destination := center + Vector2.from_angle(waypoint) * radius
	var desired := ((destination - s.p) * 6.0).limit_length(maxf(speed * 2.0, 900.0))
	s.v = s.v.lerp(desired, 1.0 - exp(-dt * 9.0))
	s.p += s.v * dt
	var separation := s.p - center
	if separation.length() < 88.0:
		var outward := separation.normalized() if separation.length_squared() > 0.01 else Vector2.from_angle(a)
		s.p = center + outward * 88.0
		s.v -= outward * minf(s.v.dot(outward), 0.0)
		# Clear old history on ejection so no trail chord crosses the body.
		s.samples = 0
	s.angle = lerp_angle(s.angle, (s.p - center).angle(), 1.0 - exp(-dt * 7.0))

func _river_lateral(index: int, distance: float) -> float:
	var pair: int = index / 2
	var side := 1.0 if index % 2 == 0 else -1.0
	if river_variant == 2:
		# All swords remain on parallel sinusoidal paths. Low-discrepancy offsets
		# spread neighboring sword pairs across a thick band, not a straight fill.
		var lane := fposmod(float(pair) * 0.61803398875 + 0.5, 1.0) * 2.0 - 1.0
		return side * (sin(distance * TAU / river_wavelength) + lane * river_band_thickness / maxf(river_width, 1.0))
	var ratio := clampf(river_fill_ratio, 0.0, 0.65)
	var rank := floori(float(pair + 1) * ratio)
	if rank > floori(float(pair) * ratio):
		# Interleave fill pairs throughout the train, with lanes covering its width.
		var total := maxi(1, floori(ceilf(swords.size() / 2.0) * ratio))
		var lane := (float(rank) - 0.5) / float(total)
		var drift := sin(distance * TAU / river_wavelength + float(rank) * 2.39996) * 0.035
		return side * clampf(lane + drift, 0.0, 0.98)
	return side * sin(distance * TAU / river_wavelength)

func _skill_hits(s: Sword, start: Vector2, end: Vector2) -> void:
	if s.cooldown > 0.0: return
	var did_hit := false
	for j in range(targets.size()):
		if targets[j].get("respawn", 0.0) > 0.0: continue
		var p: Vector2 = targets[j].p
		if Geometry2D.get_closest_point_to_segment(p, start, end).distance_squared_to(p) < 529.0:
			hits += 1
			_emit_sparks(p, s.v)
			target_hit.emit(j, p)
			did_hit = true
	if did_hit: s.cooldown = 0.15

func _step_sword(s: Sword, index: int, dt: float) -> void:
	var p := s.p
	var desired := Vector2.ZERO
	s.cooldown = maxf(0.0, s.cooldown - dt)
	s.seek_wait -= dt
	if mode == Mode.HUNT:
		if s.target >= targets.size() or (s.target >= 0 and targets[s.target].get("respawn", 0.0) > 0.0):
			s.target = -1
		if s.seek_wait <= 0.0:
			var best: float = INF
			s.seek_wait = 0.18 + float(index % 5) * 0.008
			var selected := -1
			for j in range(targets.size()):
				if targets[j].get("respawn", 0.0) > 0.0: continue
				var score: float = p.distance_squared_to(targets[j].p)
				score *= 0.8 + 0.4 * sin(float(index * 13 + j * 7))
				if s.target == j: score *= 0.65
				if score < best:
					best = score
					selected = j
			s.target = selected
	var target_index := s.target if mode == Mode.HUNT else -1
	if target_index >= 0 and s.cooldown <= 0.0:
		var difference: Vector2 = targets[target_index].p - p
		var weave := difference.normalized().orthogonal() * sin(elapsed * 2.0 + s.phase) * minf(28.0, difference.length() * 0.12) * wander_amount
		desired = (difference + weave).normalized() * speed * s.pace
	else:
		var center := focus
		if target_index >= 0: center = targets[target_index].p
		var offset := p - center
		var elliptical := Vector2(offset.x, offset.y / 0.70)
		var radial := elliptical.normalized()
		if elliptical.length_squared() < 1.0: radial = Vector2.from_angle(s.phase)
		var r := s.radius + sin(elapsed * 0.8 + s.phase) * 32.0 * wander_amount
		if mode == Mode.FOLLOW: r *= 0.61
		if mode == Mode.HUNT: r *= 0.55
		var tangent := Vector2(-radial.y, radial.x * 0.70)
		desired = tangent * speed * s.pace - Vector2(radial.x, radial.y * 0.70) * (elliptical.length() - r) * 2.5
		desired += Vector2(sin(elapsed * 1.3 + s.phase), cos(elapsed * 1.7 + s.phase)) * 48.0 * wander_amount
	# Anticipate the arena edge, but never snap/clamp position or bypass turn limits.
	var max_turn := deg_to_rad(turn_rate)
	var margin := minf(speed / max_turn * 0.85 + 25.0, 200.0)
	var pressure := Vector2.ZERO
	if p.x < bounds.position.x + margin: pressure.x += (bounds.position.x + margin - p.x) / margin
	if p.x > bounds.end.x - margin: pressure.x -= (p.x - bounds.end.x + margin) / margin
	if p.y < bounds.position.y + margin: pressure.y += (bounds.position.y + margin - p.y) / margin
	if p.y > bounds.end.y - margin: pressure.y -= (p.y - bounds.end.y + margin) / margin
	desired += pressure * speed * 4.0
	s.loop_wait -= dt * loop_amount
	if loop_amount <= 0.0: s.loop_left = 0.0
	elif s.loop_wait <= 0.0:
		s.loop_left = TAU
		s.loop_sign = -1.0 if rng.randf() < 0.3 else 1.0
		s.loop_wait = rng.randf_range(2.5, 7.0)
	var angle_error := wrapf(desired.angle() - s.angle, -PI, PI)
	var requested_turn := clampf(angle_error * 2.2, -max_turn, max_turn)
	if s.loop_left > 0.0 and pressure.length_squared() < 0.04:
		requested_turn = max_turn * s.loop_sign
		s.loop_left = maxf(0, s.loop_left - absf(s.angular_speed) * dt)
	s.angular_speed = move_toward(s.angular_speed, requested_turn, max_turn * 2.0 * dt)
	s.angular_speed = clampf(s.angular_speed, -max_turn, max_turn)
	s.angle = wrapf(s.angle + s.angular_speed * dt, -PI, PI)
	var cruise := speed * s.pace
	# Slow at the boundary to fit broad turns inside the finite demonstration arena.
	cruise *= lerpf(1.0, 0.22, clampf(pressure.length(), 0.0, 1.0))
	var velocity := Vector2.from_angle(s.angle) * move_toward(s.v.length(), cruise, speed * dt * 1.8)
	var next := p + velocity * dt
	if target_index >= 0 and s.cooldown <= 0.0:
		var tp: Vector2 = targets[target_index].p
		if Geometry2D.get_closest_point_to_segment(tp, p, next).distance_squared_to(tp) < 529.0:
			s.cooldown = rng.randf_range(0.55, 1.05)
			s.target = -1
			s.seek_wait = 0.0
			hits += 1
			_emit_sparks(tp, velocity)
			target_hit.emit(target_index, tp)
	s.p = next
	s.v = velocity
	_step_roll(s, dt)

func _step_roll(s: Sword, dt: float) -> void:
	# Axial rolling has its own scheduler and does not change heading or trajectory.
	if roll_amount <= 0.0:
		s.roll = 0.0
		s.roll_left = 0.0
	else:
		s.roll_wait -= dt * roll_amount
		if s.roll_wait <= 0.0 and s.roll_left <= 0.0:
			s.roll_left = s.roll_duration
			s.roll_wait = rng.randf_range(1.0, 4.0)
		if s.roll_left > 0.0:
			s.roll_left = maxf(0, s.roll_left - dt)
			var progress := 1.0 - s.roll_left / s.roll_duration
			s.roll = TAU * (progress * progress * (3.0 - 2.0 * progress))
		else: s.roll = 0.0

func _update_render() -> void:
	var segment_count := 0
	var inverse_lifetime := 1.0 / maxf(trail_lifetime, 0.01)
	for i in range(swords.size()):
		var s := swords[i]
		var direction := Vector2.from_angle(s.angle)
		var b := i * 12
		blade_buffer[b] = direction.x
		blade_buffer[b + 1] = -direction.y
		blade_buffer[b + 2] = 0.0
		blade_buffer[b + 3] = s.p.x
		blade_buffer[b + 4] = direction.y
		blade_buffer[b + 5] = direction.x
		blade_buffer[b + 6] = 0.0
		blade_buffer[b + 7] = s.p.y
		blade_buffer[b + 8] = s.roll
		blade_buffer[b + 9] = s.tint
		var start := s.p - direction * 14.0
		var strength := 1.0
		for j in range(0, mini(s.samples, ceili(trail_lifetime / SAMPLE_DT) + trail_stride), trail_stride):
			var age := sample_clock + float(j) * SAMPLE_DT
			var end := s.trail[(s.head - j + TRAIL_CAP) % TRAIL_CAP]
			var end_strength := maxf(0.0, 1.0 - age * inverse_lifetime)
			if start.distance_squared_to(end) > 0.0001:
				var k := segment_count * 16
				trail_buffer[k + 8] = strength
				trail_buffer[k + 9] = end_strength
				trail_buffer[k + 10] = s.tint
				trail_buffer[k + 12] = start.x
				trail_buffer[k + 13] = start.y
				trail_buffer[k + 14] = end.x
				trail_buffer[k + 15] = end.y
				segment_count += 1
			start = end
			strength = end_strength
			if age >= trail_lifetime: break
	blade_mesh.buffer = blade_buffer
	trail_mesh.buffer = trail_buffer
	trail_mesh.visible_instance_count = segment_count

func _emit_sparks(p: Vector2, direction: Vector2) -> void:
	for k in range(5):
		if sparks.size() >= 200: break
		var v := direction.normalized().rotated(rng.randf_range(-1.8, 1.8)) * rng.randf_range(45, 170)
		sparks.append({"p": p, "v": v, "life": rng.randf_range(0.15, 0.45)})

func _draw() -> void:
	for spark in sparks:
		draw_line(spark.p, spark.p - spark.v * 0.035, Color(0.85, 1.0, 0.62, clampf(spark.life * 3.0, 0, 1)), 1.5, true)
