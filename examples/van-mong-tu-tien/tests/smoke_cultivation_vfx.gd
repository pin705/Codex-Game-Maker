extends Node

## Headless contract test for the independent rank-aware cultivation VFX.
## Run with:
## godot --headless --audio-driver Dummy --path . tests/smoke_cultivation_vfx.tscn

const CultivationVFXScript := preload("res://scripts/gameplay/cultivation_vfx.gd")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var vfx := CultivationVFXScript.new() as CultivationVFX
	add_child(vfx)
	await get_tree().process_frame
	# Keep the harness deterministic even if a developer profile has the
	# accessibility setting enabled in user://.
	vfx.set_reduced_motion(false)

	# Sword progression: rank changes both the persistent orbit and attack fan.
	vfx.configure(&"van_kiem", {"sword_damage": 0, "vitality": 0, "magnet": 0})
	var sword_base := vfx.debug_snapshot()
	vfx.configure(&"van_kiem", {"sword_damage": 5, "vitality": 0, "magnet": 0})
	var sword_max := vfx.debug_snapshot()
	_expect(int(sword_base.get("sword_count", 0)) >= 2, "Vạn Kiếm starts with authored orbiting blades")
	_expect(int(sword_max.get("sword_count", 0)) > int(sword_base.get("sword_count", 0)), "sword rank adds orbiting blades")
	_expect(int(sword_max.get("attack_blades", 0)) > int(sword_base.get("attack_blades", 0)), "sword rank expands the attack fan")
	vfx.trigger_attack(Vector2.UP)
	await get_tree().process_frame
	_expect(int(vfx.debug_snapshot().get("active_attacks", 0)) == 1, "trigger_attack creates a transient fan")

	# Vitality progression: Ngọc Thể has a persistent shell and rank adds facets.
	vfx.clear_transients()
	vfx.configure(&"ngoc_the", {"sword_damage": 0, "vitality": 0, "magnet": 0})
	var ward_base := vfx.debug_snapshot()
	vfx.configure(&"ngoc_the", {"sword_damage": 0, "vitality": 5, "magnet": 0})
	var ward_max := vfx.debug_snapshot()
	_expect(int(ward_base.get("ward_facets", 0)) >= 8, "Ngọc Thể starts with a jade shell")
	_expect(int(ward_max.get("ward_facets", 0)) > int(ward_base.get("ward_facets", 0)), "vitality rank adds shield facets")
	_expect(int(ward_max.get("ward_glyphs", 0)) > int(ward_base.get("ward_glyphs", 0)), "vitality rank adds ward glyphs")
	vfx.trigger_hit(Vector2.LEFT)
	await get_tree().process_frame
	_expect(int(vfx.debug_snapshot().get("active_hits", 0)) == 1, "trigger_hit creates a jade flare")

	# Qi progression: Tụ Linh has tendrils and rank increases field complexity.
	vfx.clear_transients()
	vfx.configure(&"tu_linh", {"sword_damage": 0, "vitality": 0, "magnet": 0})
	var qi_base := vfx.debug_snapshot()
	vfx.configure(&"tu_linh", {"sword_damage": 0, "vitality": 0, "magnet": 5})
	var qi_max := vfx.debug_snapshot()
	_expect(int(qi_base.get("qi_tendrils", 0)) >= 3, "Tụ Linh starts with vortex tendrils")
	_expect(int(qi_max.get("qi_tendrils", 0)) > int(qi_base.get("qi_tendrils", 0)), "magnet rank adds vortex tendrils")
	vfx.trigger_pickup(Vector2(420.0, 260.0))
	await get_tree().process_frame
	_expect(int(vfx.debug_snapshot().get("active_pickups", 0)) == 1, "trigger_pickup creates a gathering beam")

	# Actor following remains independent of player.gd and supports generic nodes.
	var actor := Node2D.new()
	add_child(actor)
	actor.global_position = Vector2(320.0, 180.0)
	vfx.follow_actor(actor)
	_expect(vfx.global_position.is_equal_approx(actor.global_position), "follow_actor snaps to actor")
	actor.global_position = Vector2(510.0, 340.0)
	vfx.update_actor(actor, Vector2.DOWN)
	var follow_snapshot := vfx.debug_snapshot()
	_expect(vfx.global_position.is_equal_approx(actor.global_position), "update_actor tracks movement")
	_expect((follow_snapshot.get("facing", Vector2.ZERO) as Vector2).is_equal_approx(Vector2.DOWN), "update_actor tracks facing")

	# Accessibility and mobile-style bounds: repeated triggers never exceed the
	# reduced-motion cap, and continuous trails use fewer samples.
	var normal_budget := int(vfx.debug_snapshot().get("particle_budget", 0))
	vfx.set_reduced_motion(true)
	var reduced := vfx.debug_snapshot()
	_expect(bool(reduced.get("reduced_motion", false)), "reduced motion can be forced explicitly")
	_expect(int(reduced.get("particle_budget", 999)) < normal_budget, "reduced motion lowers the particle budget")
	_expect(int(reduced.get("trail_samples", 99)) <= 2, "reduced motion shortens sword trails")
	for index in 20:
		match index % 3:
			0:
				vfx.trigger_attack()
			1:
				vfx.trigger_hit()
			2:
				vfx.trigger_pickup()
	await get_tree().process_frame
	var capped := vfx.debug_snapshot()
	_expect(int(capped.get("active_transients", 0)) <= int(capped.get("transient_cap", 0)), "transient events obey the shared cap")
	_expect(int(capped.get("transient_cap", 99)) <= 4, "reduced motion uses the mobile-safe transient cap")

	# Lifetimes age independently from the slowed decorative phase.
	vfx._process(3.0)
	_expect(int(vfx.debug_snapshot().get("active_transients", -1)) == 0, "transient effects expire deterministically")

	vfx.stop_following()
	actor.queue_free()
	vfx.queue_free()
	await get_tree().process_frame
	_quit_with_report()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)


func _quit_with_report() -> void:
	if failures.is_empty():
		print("CULTIVATION VFX RESULT: PASS")
		get_tree().quit(0)
	else:
		print("CULTIVATION VFX RESULT: FAIL (", failures.size(), " failures)")
		get_tree().quit(1)
