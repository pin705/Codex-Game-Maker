extends Node

const MetaProfileScript := preload("res://scripts/meta/meta_profile.gd")

var failures: Array[String] = []
var test_path := "user://van_mong_profile_test.json"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var profile := MetaProfileScript.new()
	profile.save_path = test_path
	profile.auto_save = false
	_expect(profile.reset(false), "defaults reset")
	_expect(profile.currency == 150, "new profile has starter currency")
	_expect(profile.is_stage_unlocked(&"van_mong"), "first stage starts unlocked")
	_expect(not profile.is_stage_unlocked(&"huyet_van"), "second stage starts locked")
	_expect(not profile.select_stage(&"huyet_van"), "locked stage cannot be selected")
	_expect(profile.select_discipline(&"ngoc_the"), "discipline selection succeeds")

	var first_reward: Dictionary = profile.record_run(true, 60, 150.0, &"van_mong")
	_expect(bool(first_reward.get("success", false)), "first result is recorded")
	_expect(bool(first_reward.get("first_clear", false)), "first victory is a first clear")
	_expect(profile.runs == 1 and profile.victories == 1 and profile.kills == 60, "global counters update once")
	_expect(profile.is_stage_unlocked(&"huyet_van"), "Vân Mộng victory unlocks Huyết Vân")
	_expect(profile.selected_stage == &"huyet_van", "victory auto-selects the next sequential stage")
	_expect(not (first_reward.get("fragment_drops", {}) as Dictionary).is_empty(), "run returns persistent skill fragment drops")
	_expect(profile.is_bestiary_discovered(&"mac_lang"), "stage result discovers bestiary")
	_expect(bool(profile.achievements.get("nhap_dao", false)), "run achievement unlocks")
	_expect(bool(profile.achievements.get("toc_chien", false)), "fast victory achievement unlocks")

	_expect(profile.select_stage(&"huyet_van"), "unlocked second stage can be selected")
	_expect(profile.selected_stage == &"huyet_van", "second stage becomes current selection")
	var second_reward: Dictionary = profile.record_run(true, 55, 210.0)
	if not bool(second_reward.get("success", false)):
		print("INFO: selected-stage reward rejection: ", second_reward)
	_expect(bool(second_reward.get("success", false)), "selected stage result is recorded without an explicit id")
	_expect(profile.is_stage_unlocked(&"thien_mon"), "Huyết Vân victory unlocks Thiên Môn")
	_expect(profile.selected_stage == &"thien_mon", "second victory advances route to final stage")
	_expect(profile.get_stage_record(&"huyet_van").get("victories", 0) == 1, "per-stage record persists")

	var purchase: Dictionary = profile.purchase_upgrade(&"magnet")
	_expect(bool(purchase.get("success", false)), "upgrade purchase succeeds")
	_expect(int(profile.skill_fragments.get("magnet", 0)) >= 0, "fragment wallet persists after upgrade")
	_expect(int(profile.technique_ranks.get("magnet", 0)) == 1, "upgrade rank increments")
	var modifiers: Dictionary = profile.get_run_modifiers(&"huyet_van", &"ngoc_the")
	_expect(float(modifiers.get("enemy_health_mult", 0.0)) > 1.0, "stage modifier is composed")
	_expect(float(modifiers.get("max_health_mult", 0.0)) > 1.20, "discipline modifier is composed")
	_expect(float(modifiers.get("pickup_range_mult", 0.0)) > 1.0, "permanent technique modifier is composed")
	_expect(profile.set_setting(&"music", 2.0), "setting accepts update")
	_expect(is_equal_approx(float(profile.settings.music), 1.0), "volume is clamped")

	_expect(profile.save(), "profile saves as JSON")
	var loaded := MetaProfileScript.new()
	loaded.save_path = test_path
	loaded.auto_save = false
	_expect(loaded.load(), "profile loads from JSON")
	_expect(loaded.victories == 2, "loaded counters match")
	_expect(loaded.selected_discipline == &"ngoc_the", "loaded selection matches")
	_expect(int(loaded.technique_ranks.get("magnet", 0)) == 1, "loaded technique rank matches")

	_write_json({
		"version": 0,
		"souls": 321,
		"wins": 3,
		"games_played": 4,
		"total_kills": 99,
		"selected_path": "tu_linh",
		"upgrades": {"sword_damage": 99},
		"codex": ["mac_linh", "not_real"],
		"settings": {"master_volume": -4.0},
	})
	_expect(loaded.load(), "legacy profile migrates")
	_expect(loaded.currency == 321 and loaded.victories == 3, "legacy aliases migrate")
	_expect(loaded.selected_discipline == &"tu_linh", "legacy discipline migrates")
	_expect(int(loaded.technique_ranks.sword_damage) == 5, "legacy rank clamps to max")
	_expect(is_equal_approx(float(loaded.settings.master), 0.0), "legacy setting sanitizes")
	_expect(not loaded.discovered_bestiary.has("not_real"), "unknown content is discarded")

	_write_text("{ definitely not json")
	_expect(loaded.load(), "corrupt profile recovers to defaults")
	_expect(loaded.recovered_on_last_load, "corrupt recovery is observable")
	_expect(FileAccess.file_exists(test_path + ".corrupt"), "corrupt source is backed up")
	_expect(loaded.currency == 150, "corrupt recovery remains playable")
	profile.free()
	loaded.free()
	_cleanup()
	_quit_with_report()


func _write_json(data: Dictionary) -> void:
	_write_text(JSON.stringify(data))


func _write_text(text: String) -> void:
	var file := FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures.append(label)
		print("FAIL: ", label)


func _cleanup() -> void:
	for path: String in [test_path, test_path + ".corrupt"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _quit_with_report() -> void:
	if failures.is_empty():
		print("META PROFILE RESULT: PASS")
		get_tree().quit(0)
	else:
		print("META PROFILE RESULT: FAIL (", failures.size(), " failures)")
		get_tree().quit(1)
