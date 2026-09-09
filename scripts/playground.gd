extends Node2D

const SwarmScript = preload("res://scripts/sword_swarm.gd")
const INK := Color("091719")
const MUTED := Color("708c88")
const TEXT := Color("dce8dc")
const ACCENT := Color("d3ef8b")
const MODE_NAMES := ["游龙随行", "逐影追击", "万剑归宗"]
var swarm: SwordSwarm
var font: Font
var mode_buttons: Array[Button] = []
var count_label: Label
var mode_label: Label
var status_label: Label
var count_slider: HSlider
var pause_button: Button
var placing: bool = false
var drag_center: bool = false
var clock: float = 0.0
var target_serial: int = 0
var test_frame: int = 0
var test_enabled: bool = false
var capture_enabled: bool = false
var test_hits: int = 0
var paused_position := Vector2.ZERO
var perf_label: Label
var status_clock: float = 0.0
var controls: PanelContainer
var skill_label: Label
var pointer_skill: bool = false
var capture_kind: String = ""
var show_background: bool = true
var player: Swordsman
var follow_player: bool = true
var follow_toggle: CheckButton
var pointer_viewport := Vector2.ZERO
var pointer_received := false

func _ready() -> void:
	var system_font := SystemFont.new()
	system_font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC"])
	font = system_font
	player = preload("res://player.tscn").instantiate()
	player.position = Vector2(520, 445)
	player.z_index = 2
	add_child(player)
	player.moved.connect(_sync_player)
	swarm = SwarmScript.new()
	swarm.z_index = 3 # Flying weapons remain visible above the character (z = 2).
	add_child(swarm)
	swarm.return_anchor = player
	swarm.bounds = Rect2(30, 30, 1030, 840)
	swarm.target_hit.connect(_on_hit)
	_build_ui()
	_reset_targets()
	_select_mode(2)
	test_enabled = "--self-test" in OS.get_cmdline_user_args()
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	player.input_enabled = not test_enabled and not capture_enabled
	for kind in ["river", "river2", "burst", "charge"]:
		if "--capture-" + kind in OS.get_cmdline_user_args():
			capture_enabled = true
			capture_kind = kind
			player.input_enabled = false
			count_slider.value = 96
			swarm.focus = Vector2(220, 450) if kind.begins_with("river") else Vector2(540, 450)
			player.position = swarm.focus
			swarm.trail_lifetime = 0.9
			if kind.begins_with("river"):
				swarm.begin_river(swarm.focus, Vector2(1000, 450), 2 if kind == "river2" else 1)
			else: swarm.begin_charge(swarm.focus)

func _process(delta: float) -> void:
	_sync_player()
	if not swarm.paused:
		clock += delta
		for target in swarm.targets:
			target.flash = maxf(0.0, target.flash - delta * 3.0)
			if target.respawn > 0:
				target.respawn = maxf(0, target.respawn - delta)
				if target.respawn == 0:
					target.hp = 16
	var mouse := _pointer_position()
	if swarm.skill == SwordSwarm.Skill.RIVER_AIM and capture_kind.is_empty():
		swarm.aim_river(mouse)
	if swarm.bounds.has_point(mouse) and not placing and swarm.skill == SwordSwarm.Skill.NONE:
		if swarm.mode == SwordSwarm.Mode.FOLLOW or drag_center:
			swarm.focus = mouse.clamp(Vector2(105, 205), Vector2(975, 745))
	status_clock += delta
	if status_clock >= 0.25:
		status_clock = 0.0
		status_label.text = "%03d  飞剑     /     %02d  靶子     /     %04d  命中" % [swarm.sword_count, swarm.targets.size(), swarm.hits]
		perf_label.text = "%d FPS  /  %d DRAW CALLS" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]
		skill_label.text = ["Q 按住聚剑，松开散射\nE 按住瞄准，松开剑河", "天女散花 · 蓄力中，松开 Q 发射", "天女散花 · 爆射中", "飞剑回归中 · 可再次施放", "剑河 · 移动鼠标瞄准，松开 E", "剑河 · 双螺旋穿刺中"][swarm.skill]
		if swarm.skill == SwordSwarm.Skill.NONE:
			skill_label.text = "Q 天女散花 · E 剑河一型\nV 剑河二型 · 按住瞄准，松开释放"
		elif swarm.river_variant == 2 and swarm.skill in [SwordSwarm.Skill.RIVER_AIM, SwordSwarm.Skill.RIVER]:
			skill_label.text = "剑河二型 · 松开 V 释放" if swarm.skill == SwordSwarm.Skill.RIVER_AIM else "剑河二型 · 螺旋剑带穿刺中"
	queue_redraw()
	if test_enabled:
		_run_test()
	if capture_enabled:
		test_frame += 1
		if test_frame == 120 and not capture_kind.is_empty() and capture_kind != "charge":
			swarm.release_charge()
			swarm.release_river()
		var capture_frame := 210 if capture_kind.begins_with("river") else (240 if capture_kind == "charge" else (138 if capture_kind == "burst" else 120))
		if test_frame == capture_frame:
			_capture.call_deferred()

func _sync_player() -> void:
	if not is_instance_valid(swarm): return
	player.paused = swarm.paused
	player.update_cast_pose(swarm.skill in [SwordSwarm.Skill.CHARGE, SwordSwarm.Skill.RIVER_AIM, SwordSwarm.Skill.RIVER], _pointer_position())
	if swarm.skill in [SwordSwarm.Skill.CHARGE, SwordSwarm.Skill.RIVER_AIM]:
		swarm.skill_center = player.position
	if swarm.skill == SwordSwarm.Skill.NONE and (swarm.mode == SwordSwarm.Mode.HUNT or (swarm.mode == SwordSwarm.Mode.ORBIT and follow_player)):
		swarm.focus = player.position

func _pointer_position() -> Vector2:
	if pointer_received:
		return get_global_transform_with_canvas().affine_inverse() * pointer_viewport
	return get_local_mouse_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		event = event.duplicate()
		event.position = get_global_transform_with_canvas().affine_inverse() * event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			drag_center = false
		elif swarm.bounds.has_point(event.position):
			if placing:
				_add_target(event.position)
			elif swarm.skill == SwordSwarm.Skill.NONE:
				follow_toggle.button_pressed = false
				swarm.focus = event.position
				drag_center = swarm.mode == SwordSwarm.Mode.ORBIT
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if swarm.bounds.has_point(event.position):
			for i in range(swarm.targets.size() - 1, -1, -1):
				if event.position.distance_to(swarm.targets[i].p) < 32:
					swarm.targets.remove_at(i)
					break

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		pointer_viewport = event.position
		pointer_received = true
		_sync_player()
	if event is InputEventKey and event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		# Movement polling still sees these keys; stop UI navigation consuming arrows.
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and pointer_skill:
		pointer_skill = false
		swarm.release_charge()
		swarm.release_river()
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_Q:
			if event.pressed: swarm.begin_charge(_cast_position())
			else: swarm.release_charge()
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_E, KEY_V]:
			var variant := 2 if event.keycode == KEY_V else 1
			if event.pressed: swarm.begin_river(player.position, get_local_mouse_position(), variant)
			elif swarm.river_variant == variant: swarm.release_river()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: _select_mode(0)
			KEY_2: _select_mode(1)
			KEY_3: _select_mode(2)
			KEY_SPACE: _toggle_pause()
			KEY_F: swarm.flourish()
			KEY_G: swarm.roll_blades()
			KEY_T: _toggle_placing()
			KEY_R: _reset_targets()
			KEY_H: controls.visible = not controls.visible
			KEY_ESCAPE:
				placing = false
				swarm.recall()
				_update_hint()
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD: count_slider.value += 8
			KEY_MINUS, KEY_KP_SUBTRACT: count_slider.value -= 8
			_: return
		get_viewport().set_input_as_handled()

func _cast_position() -> Vector2:
	return player.position

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(swarm):
		# Losing focus must never leave a held-key skill stuck charging.
		if swarm.skill in [SwordSwarm.Skill.CHARGE, SwordSwarm.Skill.RIVER_AIM]: swarm.recall()

func _on_hit(index: int, _p: Vector2) -> void:
	if index >= swarm.targets.size():
		return
	var target: Dictionary = swarm.targets[index]
	target.flash = 1.0
	target.hp -= 1
	if target.hp <= 0:
		target.respawn = 2.5

func _add_target(p: Vector2) -> void:
	if swarm.targets.size() >= 64:
		return
	target_serial += 1
	swarm.targets.append({"p": p, "hp": 16, "flash": 0.0, "respawn": 0.0, "id": target_serial})

func _reset_targets() -> void:
	swarm.targets.clear()
	for p in [Vector2(285, 345), Vector2(775, 365), Vector2(560, 650)]:
		_add_target(p)

func _select_mode(index: int) -> void:
	swarm.set_mode(index)
	for i in range(mode_buttons.size()):
		mode_buttons[i].set_pressed_no_signal(i == index)
	_update_hint()

func _update_hint() -> void:
	if placing:
		mode_label.text = "布置靶子  /  左键放置 · 右键移除 · Esc 结束"
	else:
		mode_label.text = ["移动鼠标牵引剑群", "自动寻敌，技能回归主角", "环绕跟随主角" if follow_player else "定点环绕 · 点击或拖动改变中心"][swarm.mode]

func _toggle_placing() -> void:
	placing = not placing
	_update_hint()

func _toggle_pause() -> void:
	swarm.paused = not swarm.paused
	player.paused = swarm.paused
	pause_button.text = "继续演示    Space" if swarm.paused else "暂停演示    Space"

func _label(parent: Node, text: String, size: int, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 40
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", font)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_pressed_color", ACCENT)
	button.add_theme_stylebox_override("normal", _style(Color("11282b"), Color("29413e")))
	button.add_theme_stylebox_override("hover", _style(Color("1e3837"), Color("719478")))
	button.add_theme_stylebox_override("pressed", _style(Color("293c2d"), Color("91b473")))
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _gap(parent: Node, height: float) -> void:
	var control := Control.new()
	control.custom_minimum_size.y = height
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)

func _slider(parent: Node, caption: String, low: float, high: float, initial: float, step: float, action: Callable) -> HSlider:
	var label := _label(parent, caption + "  ·  " + str(initial), 12, MUTED)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = initial
	slider.custom_minimum_size.y = 19
	slider.value_changed.connect(action)
	slider.value_changed.connect(func(v: float) -> void: label.text = caption + "  ·  " + str(snappedf(v, 0.01)))
	parent.add_child(slider)
	return slider

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	controls = PanelContainer.new()
	controls.position = Vector2(1080, 16)
	controls.size = Vector2(344, 868)
	controls.add_theme_stylebox_override("panel", _style(Color("0d2023"), Color("2b403d")))
	layer.add_child(controls)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	controls.add_child(root)
	_label(root, "飞剑                         H 隐藏面板", 15)
	var buttons := HBoxContainer.new()
	root.add_child(buttons)
	var burst := _button(buttons, "天女散花 · Q", func() -> void: pass)
	burst.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	burst.button_down.connect(func() -> void:
		pointer_skill = true
		swarm.begin_charge(player.position))
	burst.button_up.connect(swarm.release_charge)
	var river := _button(buttons, "剑河 · E", func() -> void: pass)
	river.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	river.button_down.connect(func() -> void:
		pointer_skill = true
		swarm.begin_river(player.position, get_local_mouse_position()))
	river.button_up.connect(swarm.release_river)
	var river2 := _button(root, "剑河二型 · V · 按住瞄准", func() -> void: pass)
	river2.button_down.connect(func() -> void:
		pointer_skill = true
		swarm.begin_river(player.position, get_local_mouse_position(), 2))
	river2.button_up.connect(swarm.release_river)
	skill_label = _label(root, "Q 按住聚剑，松开散射\nE 按住瞄准，松开剑河", 12, ACCENT)
	_label(root, "Esc 召回   ·   1 / 2 / 3 切换移动", 12, MUTED)
	_label(root, "WASD / 方向键 · 八方向移动主角", 12, ACCENT)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_theme_font_override("font", font)
	tabs.add_theme_font_size_override("font_size", 14)
	root.add_child(tabs)
	var general := _tab(tabs, "飞剑")
	for i in range(3):
		var button := _button(general, ["1  跟随鼠标", "2  自动追击", "3  主角 / 定点环绕"][i], _select_mode.bind(i))
		button.toggle_mode = true
		mode_buttons.append(button)
	count_label = _label(general, "48 柄", 16, ACCENT)
	count_slider = _slider(general, "飞剑数量 · 1–1024", 1, 1024, 48, 1, func(v: float) -> void:
		swarm.sword_count = int(v)
		count_label.text = "%d 柄" % int(v))
	_slider(general, "飞行速度", 10, 2500, 330, 10, func(v: float) -> void: swarm.speed = v)
	_slider(general, "转弯速度 °/s", 5, 1080, 95, 5, func(v: float) -> void: swarm.turn_rate = v)
	_slider(general, "轴向翻转频率 · 0 关闭", 0, 10, 0.65, 0.05, func(v: float) -> void: swarm.roll_amount = v)
	_slider(general, "游走幅度 · 0 关闭", 0, 5, 0.35, 0.05, func(v: float) -> void: swarm.wander_amount = v)
	_slider(general, "轨迹回旋频率 · 0 关闭", 0, 10, 0.15, 0.05, func(v: float) -> void: swarm.loop_amount = v)
	_slider(general, "拖尾时长 / 秒", 0.02, 4, 0.48, 0.02, func(v: float) -> void: swarm.trail_lifetime = v)
	var skills := _tab(tabs, "技能")
	_label(skills, "天女散花", 16, ACCENT)
	_label(skills, "在场内按住 Q，在鼠标处聚剑。\n松开后全向爆射，飞出场地再回归。", 12, MUTED)
	_slider(skills, "爆射速度", 200, 6000, 1800, 50, func(v: float) -> void: swarm.burst_speed = v)
	_slider(skills, "蓄力环绕半径", 96, 400, 112, 4, func(v: float) -> void: swarm.charge_radius = v)
	_slider(skills, "回归速度", 50, 1000, 280, 10, func(v: float) -> void: swarm.return_speed = v)
	_gap(skills, 10)
	_label(skills, "剑河", 16, ACCENT)
	_label(skills, "以中心光点为起点，按住 E 瞄准。\n松开后沿双螺旋前进并穿刺靶子。", 12, MUTED)
	_slider(skills, "剑河宽度", 30, 800, 180, 10, func(v: float) -> void: swarm.river_width = v)
	_slider(skills, "空隙填充比例 · 0 恢复纯螺旋", 0, 0.65, 0.35, 0.05, func(v: float) -> void: swarm.river_fill_ratio = v)
	_label(skills, "二型：纯螺旋剑带，不使用空隙填充", 12, ACCENT)
	_slider(skills, "二型螺旋带粗细 / px", 0, 400, 60, 5, func(v: float) -> void: swarm.river_band_thickness = v)
	_slider(skills, "螺旋波长", 80, 1600, 400, 20, func(v: float) -> void: swarm.river_wavelength = v)
	_slider(skills, "剑河前进速度", 100, 4000, 650, 50, func(v: float) -> void: swarm.river_speed = v)
	_slider(skills, "剑河持续 / 秒", 1, 12, 4, 0.5, func(v: float) -> void: swarm.river_duration = v)
	var arena := _tab(tabs, "角色 / 靶场")
	_slider(arena, "主角移动速度", 30, 900, 240, 10, func(v: float) -> void: player.move_speed = v)
	follow_toggle = CheckButton.new()
	follow_toggle.text = "环绕跟随主角"
	follow_toggle.button_pressed = true
	follow_toggle.add_theme_font_override("font", font)
	follow_toggle.add_theme_font_size_override("font_size", 14)
	follow_toggle.toggled.connect(func(value: bool) -> void:
		follow_player = value
		_update_hint())
	arena.add_child(follow_toggle)
	_button(arena, "布置靶子 · T", _toggle_placing)
	_button(arena, "重置靶子 · R", _reset_targets)
	_button(arena, "清空靶子", func() -> void: swarm.targets.clear())
	_button(arena, "轴向翻转 · G", swarm.roll_blades)
	_button(arena, "轨迹回旋 · F", swarm.flourish)
	_label(arena, "右键移除靶子 · 最多 64 个\n击破后 2.5 秒重生", 12, MUTED)
	mode_label = _label(root, "", 10, MUTED)
	pause_button = _button(root, "暂停演示    Space", _toggle_pause)
	status_label = _label(root, "", 10, MUTED)
	perf_label = _label(root, "", 10, MUTED)

func _tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 7)
	scroll.add_child(column)
	return column

func _draw() -> void:
	if show_background: draw_rect(Rect2(0, 0, 1440, 900), INK)
	if not is_instance_valid(swarm):
		return
	if swarm.skill == SwordSwarm.Skill.RIVER_AIM:
		var origin := swarm.skill_center
		var axis := swarm.skill_direction
		var thickness := swarm.river_band_thickness if swarm.river_variant == 2 else 0.0
		var normal := axis.orthogonal() * (swarm.river_width + thickness) * 0.5
		var end := origin + axis * 2800.0
		draw_colored_polygon(PackedVector2Array([origin - normal, end - normal, end + normal, origin + normal]), Color(0.35, 0.8, 0.65, 0.035))
		draw_line(origin - normal, end - normal, Color(0.55, 0.9, 0.65, 0.3), 1, true)
		draw_line(origin + normal, end + normal, Color(0.55, 0.9, 0.65, 0.3), 1, true)
		draw_line(origin, end, Color(0.65, 0.95, 0.75, 0.2), 1, true)
	var focus: Vector2 = swarm.skill_center if swarm.skill != SwordSwarm.Skill.NONE else swarm.focus
	_draw_ellipse(focus, 29, Color(0.7, 0.85, 0.54, 0.3), clock * 0.4, clock * 0.4 + TAU * 0.76)
	draw_circle(focus, 4, ACCENT)
	draw_circle(focus, 10, Color(0.75, 0.93, 0.55, 0.1))
	draw_line(focus + Vector2(-17, 0), focus + Vector2(-9, 0), ACCENT, 1)
	draw_line(focus + Vector2(9, 0), focus + Vector2(17, 0), ACCENT, 1)
	for target in swarm.targets:
		_draw_target(target)
	if placing and swarm.bounds.has_point(get_local_mouse_position()):
		draw_arc(get_local_mouse_position(), 22, 0, TAU, 48, Color(0.85, 0.8, 0.58, 0.65), 1, true)

func _draw_ellipse(center: Vector2, radius: float, color: Color, start: float, end: float) -> void:
	var points := PackedVector2Array()
	for i in range(97):
		var a := lerpf(start, end, float(i) / 96)
		points.append(center + Vector2(cos(a), sin(a) * 0.70) * radius)
	draw_polyline(points, color, 1.0, true)

func _draw_target(target: Dictionary) -> void:
	var p: Vector2 = target.p
	var inactive: bool = target.respawn > 0
	var color := Color("ba8e69").lerp(Color("f0ffd2"), target.flash)
	if inactive:
		color.a = 0.18
	draw_circle(p + Vector2(0, 9), 24, Color(0, 0, 0, 0.16))
	draw_arc(p, 22, 0, TAU, 40, Color(color, color.a * 0.6), 1, true)
	draw_arc(p, 13, 0, TAU, 32, color, 1, true)
	var diamond := PackedVector2Array([p + Vector2(0, -7), p + Vector2(7, 0), p + Vector2(0, 7), p + Vector2(-7, 0), p + Vector2(0, -7)])
	draw_polyline(diamond, color, 1.5, true)
	for a in [0.0, PI / 2, PI, PI * 1.5]:
		draw_line(p + Vector2.from_angle(a) * 19, p + Vector2.from_angle(a) * 27, color, 1, true)
	draw_line(p + Vector2(-20, 35), p + Vector2(20, 35), Color("273a34"), 2)
	draw_line(p + Vector2(-20, 35), p + Vector2(-20 + 40.0 * maxf(target.hp, 0) / 16.0, 35), color, 2)
	if target.flash > 0:
		draw_arc(p, 22 + (1 - target.flash) * 30, 0, TAU, 48, Color(0.84, 0.95, 0.62, target.flash * 0.55), 1, true)

func _run_test() -> void:
	test_frame += 1
	if test_frame == 1:
		seed(42)
		mode_buttons[0].pressed.emit()
		assert(swarm.mode == SwordSwarm.Mode.FOLLOW)
		_toggle_placing()
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = Vector2(400, 250)
		_unhandled_input(click)
		assert(swarm.targets.size() == 4)
		click.button_index = MOUSE_BUTTON_RIGHT
		_unhandled_input(click)
		assert(swarm.targets.size() == 3)
		_toggle_placing()
	if test_frame == 90:
		count_slider.value = 160
		_select_mode(1)
	if test_frame == 450:
		assert(swarm.hits > 0, "Pursuit must hit targets")
		test_hits = swarm.hits
		swarm.targets.clear()
	if test_frame == 490:
		_reset_targets()
		_select_mode(2)
		swarm.flourish()
	if test_frame == 560:
		count_slider.value = 1
	if test_frame == 580:
		assert(swarm.swords.size() == 1)
		_toggle_pause()
		paused_position = swarm.swords[0].p
	if test_frame == 600:
		assert(swarm.swords[0].p == paused_position, "Pause must freeze simulation")
		_toggle_pause()
		count_slider.value = 48
	if test_frame >= 660:
		assert(swarm.swords.size() == 48)
		for s in swarm.swords:
			assert(is_finite(s.p.x) and is_finite(s.p.y))
		var key := InputEventKey.new()
		key.keycode = KEY_Q
		key.pressed = true
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.CHARGE)
		key.pressed = false
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.BURST)
		key.keycode = KEY_E
		key.pressed = true
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RIVER_AIM)
		key.pressed = false
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RIVER)
		key.keycode = KEY_V
		key.pressed = true
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RIVER_AIM and swarm.river_variant == 2)
		key.keycode = KEY_E
		key.pressed = false
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RIVER_AIM)
		key.keycode = KEY_V
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RIVER and swarm.river_variant == 2)
		key.keycode = KEY_ESCAPE
		key.pressed = true
		_input(key)
		assert(swarm.skill == SwordSwarm.Skill.RETURN)
		key.keycode = KEY_H
		_input(key)
		assert(not controls.visible)
		_input(key)
		assert(controls.visible)
		print("SELF_TEST_OK modes=3 count=1/48/160 hits=", test_hits, " pause=ok empty_targets=ok placement/removal=ok")
		get_tree().quit()

func _capture() -> void:
	await RenderingServer.frame_post_draw
	var suffix := "-" + capture_kind if not capture_kind.is_empty() else ""
	var path := ProjectSettings.globalize_path("res://../reference/preview" + suffix + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", path)
	get_tree().quit()
