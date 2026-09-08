extends Node2D
enum State { GROUND, ASCENDING, SKY, CRUISING, DESCENDING }
const REGIONS := ["青岚岛", "赤霞岛", "寒玉岛"]
const OFFSETS := [Vector2.ZERO, Vector2(4200,-1400), Vector2(2700,3100)]
const SKY_CENTER := Vector2(2550,1300)
const SKY_ZOOM := 0.12
const FLIGHT_SECONDS := 4.2
var state: State = State.GROUND
var current_region: int = 0
var selected_region: int = 0
var phase: float = 0.0
var clock: float = 0.0
var ground: Node2D
var camera: Camera2D
var sky_ui: CanvasLayer
var flight_avatar: Swordsman
var cloud: ColorRect
var cloud_material: ShaderMaterial
var travel_button: Button
var land_button: Button
var title: Label
var hint: Label
var island_buttons: Array[Button] = []
var flight_position := Vector2.ZERO
var flight_start := Vector2.ZERO
var camera_start := Vector2.ZERO
var ascent_avatar_start := Vector2.ZERO
var saved_pause: bool = false
var saved_controls: bool = true
var region_saves: Dictionary = {}
var capture_stage: String = ""
var capture_frames: int = 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("7396a5"))
	var clouds := Node2D.new()
	clouds.set_script(preload("res://scripts/cloud_sea.gd"))
	clouds.z_index = -20
	add_child(clouds)
	for i in range(3):
		var terrain := Node2D.new()
		terrain.set_script(preload("res://scripts/island_terrain.gd"))
		terrain.region = i
		terrain.position = OFFSETS[i]
		terrain.z_index = -10
		add_child(terrain)
	ground = preload("res://main.tscn").instantiate()
	ground.show_background = false
	add_child(ground)
	camera = Camera2D.new()
	camera.position = Vector2(720,450)
	add_child(camera)
	camera.make_current()
	_build_ui()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--travel-capture="): capture_stage = arg.get_slice("=",1)
	_update_ui()

func _button(parent: Node, text: String, action: Callable) -> Button:
	var b: Button = ground._button(parent, text, action)
	return b

func _build_ui() -> void:
	sky_ui = CanvasLayer.new()
	sky_ui.layer = 10
	add_child(sky_ui)
	cloud = ColorRect.new()
	cloud.size = Vector2(1440,900)
	cloud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cloud_material = ShaderMaterial.new()
	cloud_material.shader = preload("res://shaders/travel_clouds.gdshader")
	cloud.material = cloud_material
	sky_ui.add_child(cloud)
	flight_avatar = preload("res://player.tscn").instantiate()
	sky_ui.add_child(flight_avatar)
	flight_avatar.set_physics_process(false)
	flight_avatar.visible = false
	var mount := Polygon2D.new()
	mount.polygon = PackedVector2Array([Vector2(-42,8),Vector2(35,5),Vector2(49,8),Vector2(34,11),Vector2(-42,11)])
	mount.color = Color("d8edac")
	flight_avatar.add_child(mount)
	travel_button = _button(sky_ui, "御剑升空 · Tab", take_off)
	travel_button.position = Vector2(24,24)
	title = ground._label(sky_ui, "", 28, Color("eff7e4"))
	title.position = Vector2(32,30)
	hint = ground._label(sky_ui, "", 15, Color("e0ece8"))
	hint.position = Vector2(32,74)
	land_button = _button(sky_ui, "降落 · Enter", land)
	land_button.position = Vector2(1110,24)
	land_button.custom_minimum_size.x = 300
	for i in range(3):
		var b := _button(sky_ui, "%d  %s" % [i+1,REGIONS[i]], fly_to.bind(i))
		b.custom_minimum_size.x = 170
		island_buttons.append(b)

func take_off() -> void:
	if state != State.GROUND: return
	saved_pause = ground.swarm.paused
	saved_controls = ground.controls.visible
	region_saves[current_region] = {"position": ground.player.position, "targets": ground.swarm.targets.duplicate(true)}
	ground.swarm.recall()
	ground.swarm.paused = true
	ground.player.paused = true
	ground.player.input_enabled = false
	ground.controls.hide()
	ground.set_process_input(false)
	ground.set_process_unhandled_input(false)
	ground.player.hide()
	ground.placing = false
	ground.drag_center = false
	camera_start = camera.position
	flight_position = ground.position + ground.player.position
	flight_start = flight_position
	ascent_avatar_start = project_to_screen(flight_position)
	flight_avatar.show()
	selected_region = current_region
	_set_state(State.ASCENDING)

func fly_to(index: int) -> void:
	if state != State.SKY: return
	selected_region = clampi(index,0,2)
	flight_start = flight_position
	_set_state(State.CRUISING)

func land() -> void:
	if state != State.SKY or selected_region < 0: return
	current_region = selected_region
	ground.position = OFFSETS[current_region]
	var saved: Dictionary = region_saves.get(current_region,{})
	ground.player.position = saved.get("position", Vector2(520,445))
	ground.swarm.targets.clear()
	if saved.has("targets"): ground.swarm.targets.assign(saved.targets.duplicate(true))
	else:
		for p in [Vector2(285,345),Vector2(775,365),Vector2(560,650)]: ground._add_target(p)
	ground.swarm.focus = ground.player.position
	ground.swarm.skill = SwordSwarm.Skill.NONE
	# Re-form the same number of swords on the new island, without stale trails.
	for i in range(ground.swarm.swords.size()):
		var s: SwordSwarm.Sword = ground.swarm.swords[i]
		var a: float = float(i)/ground.swarm.swords.size()*TAU
		s.p = ground.player.position + Vector2(cos(a)*180,sin(a)*130)
		s.v = Vector2(-sin(a),cos(a))*ground.swarm.speed
		s.angle = s.v.angle()
		s.samples = 0
		s.target = -1
	ground.swarm.sparks.clear()
	ground.swarm._update_render()
	flight_start = flight_position
	camera_start = camera.position
	_set_state(State.DESCENDING)

func _set_state(value: State) -> void:
	state = value
	phase = 0.0
	_update_ui()

func project_to_screen(p: Vector2) -> Vector2:
	return (p-camera.position)*camera.zoom + Vector2(720,450)

func _process(delta: float) -> void:
	advance(delta)
	if not capture_stage.is_empty():
		capture_frames += 1
		if capture_frames == 60: take_off()
		if capture_stage == "clouds" and state == State.ASCENDING and phase > 2.1: _capture.call_deferred()
		elif capture_stage == "sky" and state == State.SKY: _capture.call_deferred()
		elif capture_stage == "ground" and capture_frames == 40: _capture.call_deferred()

func advance(delta: float) -> void:
	var previous_flight := flight_position
	clock += delta
	phase += delta
	var cover := 0.0
	match state:
		State.ASCENDING:
			var t := clampf(phase/FLIGHT_SECONDS,0,1)
			var ease := smoothstep(0.0,1.0,t)
			camera.position = camera_start.lerp(SKY_CENTER,ease)
			camera.zoom = Vector2.ONE * exp(lerpf(0.0,log(SKY_ZOOM),ease))
			flight_avatar.position = ascent_avatar_start.lerp(project_to_screen(flight_position),ease)+Vector2(0,-sin(t*PI)*75)
			flight_avatar.scale = Vector2.ONE*lerpf(1.0,0.65,ease)
			cover = sin(t*PI)*0.98 + t*0.13
			ground.swarm.visible = t < 0.4
			if t >= 1: _set_state(State.SKY)
		State.SKY:
			var direction := Input.get_vector("ui_left","ui_right","ui_up","ui_down")
			direction += Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
			flight_position += direction.limit_length(1)*1450*delta
			flight_position = flight_position.clamp(Vector2(-1800,-2600),Vector2(6600,5300))
			selected_region = -1
			for i in range(3):
				if flight_position.distance_to(OFFSETS[i]+Vector2(560,450)) < 1200: selected_region = i
			flight_avatar.position = project_to_screen(flight_position)+Vector2(0,sin(clock*2)*4)
			cover = 0.13
		State.CRUISING:
			var t := clampf(phase/1.35,0,1)
			flight_position = flight_start.lerp(OFFSETS[selected_region]+Vector2(520,445),smoothstep(0,1,t))
			flight_avatar.position = project_to_screen(flight_position)+Vector2(0,-sin(t*PI)*30)
			cover = 0.13
			if t >= 1: _set_state(State.SKY)
		State.DESCENDING:
			var t := clampf(phase/FLIGHT_SECONDS,0,1)
			var ease := smoothstep(0.0,1.0,t)
			camera.position = camera_start.lerp(OFFSETS[current_region]+Vector2(720,450),ease)
			camera.zoom = Vector2.ONE*exp(lerpf(log(SKY_ZOOM),0.0,ease))
			flight_position = flight_start.lerp(ground.position+ground.player.position,ease)
			flight_avatar.position = project_to_screen(flight_position)+Vector2(0,-sin(t*PI)*60)
			flight_avatar.scale = Vector2.ONE*lerpf(0.65,1.0,ease)
			cover = sin(t*PI)*0.98+(1-t)*0.13
			ground.swarm.visible = t > 0.85
			if t >= 1:
				ground.player.show()
				ground.swarm.show()
				ground.player.input_enabled = true
				ground.swarm.paused = saved_pause
				ground.player.paused = saved_pause
				ground.controls.visible = saved_controls
				ground.set_process_input(true)
				ground.set_process_unhandled_input(true)
				flight_avatar.hide()
				_set_state(State.GROUND)
	cloud_material.set_shader_parameter("cover",cover)
	cloud_material.set_shader_parameter("drift",clock)
	var flight_delta := flight_position - previous_flight
	if flight_delta.length_squared() > 0.01:
		flight_avatar.facing = posmod(roundi(flight_delta.angle()/(PI/4.0)),8)
	elif state == State.ASCENDING: flight_avatar.facing = 6
	elif state == State.DESCENDING: flight_avatar.facing = 2
	flight_avatar.walking = state != State.GROUND
	flight_avatar.animation_time = clock
	flight_avatar.queue_redraw()
	_update_ui()

func _update_ui() -> void:
	if not is_instance_valid(title): return
	travel_button.visible = state == State.GROUND
	title.visible = state != State.GROUND
	hint.visible = state != State.GROUND
	land_button.visible = state == State.SKY
	land_button.disabled = selected_region < 0
	for i in range(3):
		island_buttons[i].visible = state in [State.SKY,State.CRUISING]
		island_buttons[i].disabled = state != State.SKY
		island_buttons[i].position = project_to_screen(OFFSETS[i]+Vector2(560,450))+Vector2(-85,110)
	title.text = ["", "御剑升空", "云海 · 浮岛", "御剑巡航", "降落 · "+REGIONS[current_region]][state]
	hint.text = "WASD / 方向键飞行 · 点击岛名或按 1 / 2 / 3 前往 · Enter 降落" if state in [State.SKY,State.CRUISING] else "穿越云层中…"
	if state == State.SKY and selected_region >= 0: land_button.text = "降落 "+REGIONS[selected_region]+" · Enter"
	elif state == State.SKY: land_button.text = "请先靠近浮岛"

func _input(event: InputEvent) -> void:
	if state == State.GROUND:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
			take_off()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey:
		if event.pressed and not event.echo and state == State.SKY:
			match event.keycode:
				KEY_1: fly_to(0)
				KEY_2: fly_to(1)
				KEY_3: fly_to(2)
				KEY_ENTER,KEY_KP_ENTER: land()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if state == State.SKY and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			for i in range(3):
				var center := project_to_screen(OFFSETS[i]+Vector2(560,450))
				if event.position.distance_to(center) < 150:
					fly_to(i)
					get_viewport().set_input_as_handled()
		# Let sky UI buttons handle their own clicks, but suppress ground handlers.
		ground.set_process_unhandled_input(false)

func _capture() -> void:
	var name := capture_stage
	capture_stage = ""
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../reference/travel-"+name+".png"))
	get_tree().quit()
