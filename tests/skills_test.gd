extends SceneTree
const Swarm = preload("res://scripts/sword_swarm.gd")
var failures: int = 0

func _initialize() -> void: _run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func advance(s: SwordSwarm, frames: int) -> void:
	for i in range(frames): s._physics_process(1.0 / 60.0)

func _run() -> void:
	var s := Swarm.new()
	s.sword_count = 24
	root.add_child(s)
	s.set_physics_process(false)
	s.begin_charge(Vector2(520, 450))
	advance(s, 240)
	for blade in s.swords: check(blade.p.distance_to(s.skill_center) < 32, "All swords must converge while held")
	s.release_charge()
	for i in range(s.swords.size()):
		check(absf(wrapf(s.swords[i].v.angle() - TAU * i / s.swords.size(), -PI, PI)) < 0.0001, "Burst must cover 360 degrees")
	advance(s, 60)
	var outside := 0
	for blade in s.swords:
		if not Rect2(0, 0, 1440, 900).has_point(blade.p): outside += 1
	check(outside > 12, "Burst must be allowed off screen")
	advance(s, 20)
	check(s.skill == Swarm.Skill.RETURN, "Burst must enter recall automatically")
	advance(s, 2100)
	check(s.skill == Swarm.Skill.NONE, "All burst swords must eventually return")
	s.begin_river(Vector2(180, 450), Vector2(1000, 450))
	advance(s, 180)
	s.targets = [{"p": Vector2(380, 450)}, {"p": Vector2(580, 450)}]
	var before_hits := s.hits
	s.release_river()
	advance(s, 130)
	check(s.skill == Swarm.Skill.RIVER, "River must keep streaming during its duration")
	var axis := s.skill_direction
	var normal := axis.orthogonal()
	for i in range(0, s.swords.size(), 2):
		var a: Vector2 = s.swords[i].p - s.skill_center
		var b: Vector2 = s.swords[i + 1].p - s.skill_center
		check(absf(a.dot(axis) - b.dot(axis)) < 0.2, "DNA strands must share longitudinal progression")
		check(absf(a.dot(normal) + b.dot(normal)) < 0.2, "DNA strands must be opposite")
		check(absf(a.dot(normal)) <= s.river_width * 0.5 + 0.1, "River must stay inside its width")
		check(s.swords[i].v.dot(axis) > 0, "River must advance forward")
	check(s.hits > before_hits, "River must pierce targets")
	advance(s, 160)
	check(s.skill == Swarm.Skill.RETURN, "River must recall after duration")
	advance(s, 2400)
	check(s.skill == Swarm.Skill.NONE, "River swords must eventually return")
	s.begin_charge(Vector2(500, 450))
	s.paused = true
	var p := s.swords[0].p
	advance(s, 30)
	check(s.swords[0].p == p, "Pause must freeze held skill")
	s.paused = false
	s.begin_river(Vector2(500, 450), Vector2(500, 100))
	check(s.skill == Swarm.Skill.RIVER_AIM, "New skill must safely replace old skill")
	s.recall()
	check(s.skill == Swarm.Skill.RETURN, "Manual cancel must recall")
	s.sword_count = 1024
	s.trail_lifetime = 4.0
	s.begin_charge(Vector2(500, 450))
	advance(s, 10)
	s.release_charge()
	advance(s, 10)
	check(s.swords.size() == 1024 and s.blade_mesh.instance_count == 1024, "Expanded count must retain every sword")
	check(s.trail_mesh.visible_instance_count <= s.trail_mesh.instance_count, "Adaptive trails must fit buffer")
	s.sword_count = 1
	advance(s, 1)
	check(s.swords.size() == 1, "Count changes during skills must be safe")
	if failures == 0: print("SKILLS_TEST_OK charge=ok burst360=ok offscreen=ok recall=ok dna=ok piercing=ok pause=ok interrupt=ok count1024=ok")
	quit(1 if failures else 0)
