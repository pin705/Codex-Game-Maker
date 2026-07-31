extends Node

## Persistent account-wide progression for the commercial demo loop.
##
## This script is designed to be registered as the `MetaProfile` autoload. It
## deliberately owns only durable meta state; a combat run remains owned by the
## gameplay scene. All dictionaries returned to callers are deep copies so UI
## code cannot accidentally mutate the save without going through this API.

signal profile_loaded(created_new: bool, recovered_from_error: bool)
signal profile_changed(snapshot: Dictionary)
signal currency_changed(current: int, delta: int)
signal selection_changed(stage_id: StringName, discipline_id: StringName)
signal upgrade_purchased(upgrade_id: StringName, rank: int, cost: int)
signal fragments_changed(skill_id: StringName, current: int, delta: int)
signal achievements_unlocked(achievement_ids: Array[String])
signal bestiary_discovered(entry_ids: Array[String])
signal settings_changed(current_settings: Dictionary)
signal save_failed(reason: String)

const SAVE_VERSION := 3
const SAVE_PATH := "user://van_mong_profile.json"

const STAGE_ORDER := ["van_mong", "huyet_van", "thien_mon"]
const DISCIPLINE_ORDER := ["van_kiem", "tu_linh", "ngoc_the"]
const UPGRADE_ORDER := ["sword_damage", "vitality", "magnet"]
const BESTIARY_ORDER := ["mac_linh", "mac_lang", "ta_tu", "huyet_ve", "thien_giac"]
const ACHIEVEMENT_ORDER := [
	"nhap_dao",
	"pha_van_mong",
	"toc_chien",
	"huyet_chien",
	"tram_yeu_100",
	"thien_mon_chinh_phuc",
]

const STAGES: Dictionary = {
	"van_mong": {
		"id": "van_mong",
		"name": "Vân Mộng Cốc",
		"eyebrow": "Đệ nhất thí luyện",
		"description": "Linh vụ tràn qua cổ cốc. Mặc Linh và Mặc Lang là thử thách đầu tiên của mọi đệ tử.",
		"difficulty": 1,
		"recommended_power": 0,
		"unlock": {
			"required_stage": "",
			"required_stage_victories": 0,
			"required_total_victories": 0,
			"description": "Mở sẵn",
		},
		"modifiers": {
			"enemy_health_mult": 1.0,
			"enemy_damage_mult": 1.0,
			"spawn_interval_mult": 1.0,
			"elite_chance_add": 0.0,
			"boss_health_mult": 1.0,
		},
		"rewards": {
			"base": 30,
			"victory_bonus": 70,
			"per_kill": 1.0,
			"speed_par_seconds": 240.0,
			"max_speed_bonus": 30,
			"first_clear_bonus": 100,
		},
		"bestiary": ["mac_linh", "mac_lang", "ta_tu"],
		"victory_bestiary": [],
	},
	"huyet_van": {
		"id": "huyet_van",
		"name": "Huyết Vân Đài",
		"eyebrow": "Đệ nhị thí luyện",
		"description": "Huyết nguyệt nhuộm đỏ chiến đài. Địch nhân hung hãn hơn và Huyết Vệ thường xuyên xuất trận.",
		"difficulty": 2,
		"recommended_power": 2,
		"unlock": {
			"required_stage": "van_mong",
			"required_stage_victories": 1,
			"required_total_victories": 1,
			"description": "Chiến thắng Vân Mộng Cốc",
		},
		"modifiers": {
			"enemy_health_mult": 1.18,
			"enemy_damage_mult": 1.12,
			"spawn_interval_mult": 0.88,
			"elite_chance_add": 0.06,
			"boss_health_mult": 1.12,
		},
		"rewards": {
			"base": 45,
			"victory_bonus": 100,
			"per_kill": 1.2,
			"speed_par_seconds": 240.0,
			"max_speed_bonus": 45,
			"first_clear_bonus": 160,
		},
		"bestiary": ["mac_linh", "mac_lang", "ta_tu", "huyet_ve"],
		"victory_bestiary": [],
	},
	"thien_mon": {
		"id": "thien_mon",
		"name": "Thiên Môn Tàn Cảnh",
		"eyebrow": "Chung cực thí luyện",
		"description": "Tàn tích trên tầng mây nơi Thiên Giác trấn giữ. Mật độ yêu vật và sức mạnh thủ lĩnh đạt đỉnh.",
		"difficulty": 3,
		"recommended_power": 5,
		"unlock": {
			"required_stage": "huyet_van",
			"required_stage_victories": 1,
			"required_total_victories": 2,
			"description": "Chiến thắng Huyết Vân Đài",
		},
		"modifiers": {
			"enemy_health_mult": 1.38,
			"enemy_damage_mult": 1.25,
			"spawn_interval_mult": 0.78,
			"elite_chance_add": 0.12,
			"boss_health_mult": 1.35,
		},
		"rewards": {
			"base": 65,
			"victory_bonus": 140,
			"per_kill": 1.5,
			"speed_par_seconds": 240.0,
			"max_speed_bonus": 60,
			"first_clear_bonus": 240,
		},
		"bestiary": ["mac_linh", "mac_lang", "ta_tu", "huyet_ve"],
		"victory_bestiary": ["thien_giac"],
	},
}

const DISCIPLINES: Dictionary = {
	"van_kiem": {
		"id": "van_kiem",
		"name": "Vạn Kiếm Quy Tông",
		"short_name": "Vạn Kiếm",
		"role": "Công kích",
		"description": "Phi kiếm dày đặc, sát thương cao và xuất chiêu nhanh; đổi lại căn cơ sinh mệnh mỏng hơn.",
		"modifiers": {
			"damage_mult": 1.18,
			"attack_interval_mult": 0.90,
			"max_health_mult": 0.92,
		},
	},
	"tu_linh": {
		"id": "tu_linh",
		"name": "Tụ Linh Chân Quyết",
		"short_name": "Tụ Linh",
		"role": "Trưởng thành",
		"description": "Hấp thu linh khí nhanh, phạm vi thu nhặt rộng và đột phá sớm hơn trong mỗi trận.",
		"modifiers": {
			"xp_mult": 1.22,
			"pickup_range_mult": 1.25,
			"movement_speed_mult": 0.96,
		},
	},
	"ngoc_the": {
		"id": "ngoc_the",
		"name": "Ngọc Thể Huyền Công",
		"short_name": "Ngọc Thể",
		"role": "Sinh tồn",
		"description": "Cường hóa thể phách và giảm thương nhận vào; thân pháp chậm hơn đôi chút.",
		"modifiers": {
			"max_health_mult": 1.25,
			"damage_taken_mult": 0.88,
			"movement_speed_mult": 0.92,
		},
	},
}

const UPGRADES: Dictionary = {
	"sword_damage": {
		"id": "sword_damage",
		"name": "Kiếm Tâm",
		"description": "Mỗi tầng tăng 8% sát thương phi kiếm.",
		"max_rank": 5,
		"base_cost": 120,
		"cost_growth": 1.65,
		"fragment_base_cost": 4,
		"fragment_cost_growth": 1.55,
		"effect_per_rank": 0.08,
		"effect_key": "damage_mult",
	},
	"vitality": {
		"id": "vitality",
		"name": "Ngọc Cốt",
		"description": "Mỗi tầng tăng 10% sinh mệnh tối đa.",
		"max_rank": 5,
		"base_cost": 100,
		"cost_growth": 1.60,
		"fragment_base_cost": 4,
		"fragment_cost_growth": 1.58,
		"effect_per_rank": 0.10,
		"effect_key": "max_health_mult",
	},
	"magnet": {
		"id": "magnet",
		"name": "Tụ Linh Trận",
		"description": "Mỗi tầng tăng 12% phạm vi hút và 3% linh khí nhận được.",
		"max_rank": 5,
		"base_cost": 90,
		"cost_growth": 1.55,
		"fragment_base_cost": 3,
		"fragment_cost_growth": 1.52,
		"effect_per_rank": 0.12,
		"secondary_effect_per_rank": 0.03,
		"effect_key": "pickup_range_mult",
		"secondary_effect_key": "xp_mult",
	},
}

const BESTIARY: Dictionary = {
	"mac_linh": {
		"id": "mac_linh",
		"name": "Mặc Linh",
		"kind": "U linh",
		"threat": 1,
		"habitat": "Vân Mộng Cốc",
		"description": "Linh thể kết từ mực tà, yếu ớt nhưng thường xuất hiện thành đàn.",
		"combat_tip": "Dùng phi kiếm quét nhanh trước khi chúng khép vòng vây.",
	},
	"mac_lang": {
		"id": "mac_lang",
		"name": "Mặc Lang",
		"kind": "Yêu thú",
		"threat": 2,
		"habitat": "Vân Mộng Cốc",
		"description": "Yêu lang bám theo khí tức tu sĩ rồi lao vào từ góc khuất.",
		"combat_tip": "Giữ khoảng trống để né cú vồ thẳng tuyến.",
	},
	"ta_tu": {
		"id": "ta_tu",
		"name": "Tà Tu",
		"kind": "Tu sĩ sa ngã",
		"threat": 3,
		"habitat": "Các thí luyện",
		"description": "Kẻ luyện cấm thuật, có khả năng áp sát và bẻ gãy tiết tấu di chuyển.",
		"combat_tip": "Ưu tiên tiêu diệt trước đám yêu vật thường.",
	},
	"huyet_ve": {
		"id": "huyet_ve",
		"name": "Huyết Vệ",
		"kind": "Tinh anh",
		"threat": 4,
		"habitat": "Huyết Vân Đài",
		"description": "Chiến vệ được huyết trận gia trì, chịu đòn tốt và gây áp lực liên tục.",
		"combat_tip": "Giữ Linh Bạo cho lúc Huyết Vệ tiến vào tầm gần.",
	},
	"thien_giac": {
		"id": "thien_giac",
		"name": "Thiên Giác",
		"kind": "Đại yêu thủ lĩnh",
		"threat": 5,
		"habitat": "Thiên Môn Tàn Cảnh",
		"description": "Cổ yêu trấn Thiên Môn, tích tụ lôi khí và tà niệm qua nhiều kỷ nguyên.",
		"combat_tip": "Không tham sát thương; xoay quanh rìa đấu trường và phản công sau đại chiêu.",
	},
}

const ACHIEVEMENTS: Dictionary = {
	"nhap_dao": {
		"id": "nhap_dao",
		"name": "Nhập Đạo",
		"description": "Hoàn thành một lần thí luyện.",
		"reward_currency": 40,
		"requirement": {"type": "runs", "amount": 1},
	},
	"pha_van_mong": {
		"id": "pha_van_mong",
		"name": "Phá Vân Mộng",
		"description": "Chiến thắng Vân Mộng Cốc lần đầu.",
		"reward_currency": 80,
		"requirement": {"type": "stage_victories", "stage_id": "van_mong", "amount": 1},
	},
	"toc_chien": {
		"id": "toc_chien",
		"name": "Nhất Khắc Định Càn Khôn",
		"description": "Chiến thắng một thí luyện trong không quá 180 giây.",
		"reward_currency": 75,
		"requirement": {"type": "fast_victory", "seconds": 180.0},
	},
	"huyet_chien": {
		"id": "huyet_chien",
		"name": "Huyết Chiến",
		"description": "Chiến thắng Huyết Vân Đài lần đầu.",
		"reward_currency": 120,
		"requirement": {"type": "stage_victories", "stage_id": "huyet_van", "amount": 1},
	},
	"tram_yeu_100": {
		"id": "tram_yeu_100",
		"name": "Bách Yêu Trảm",
		"description": "Tiêu diệt tổng cộng 100 địch nhân.",
		"reward_currency": 100,
		"requirement": {"type": "kills", "amount": 100},
	},
	"thien_mon_chinh_phuc": {
		"id": "thien_mon_chinh_phuc",
		"name": "Thiên Môn Chinh Phục",
		"description": "Đánh bại Thiên Giác và hoàn thành chung cực thí luyện.",
		"reward_currency": 250,
		"requirement": {"type": "stage_victories", "stage_id": "thien_mon", "amount": 1},
	},
}

const DEFAULT_SETTINGS: Dictionary = {
	"master": 0.80,
	"music": 0.65,
	"sfx": 0.85,
	"reduced_motion": false,
	"screen_shake": true,
}

var save_path: String = SAVE_PATH
var auto_save := true
var last_error := ""
var recovered_on_last_load := false
## Transient navigation hint used when a scene reload must reopen a meta screen.
## It is intentionally not persisted as player progression.
var pending_screen: StringName = &"title"

var _state: Dictionary = {}

var currency: int:
	get:
		return int(_state.get("currency", 0))

var victories: int:
	get:
		return int(_state.get("victories", 0))

var runs: int:
	get:
		return int(_state.get("runs", 0))

var kills: int:
	get:
		return int(_state.get("kills", 0))

var unlocked_stages: Array[String]:
	get:
		return _string_array(_state.get("unlocked_stages", []))

var selected_stage: StringName:
	get:
		return StringName(str(_state.get("selected_stage", "van_mong")))

var selected_discipline: StringName:
	get:
		return StringName(str(_state.get("selected_discipline", "van_kiem")))

var technique_ranks: Dictionary:
	get:
		return _dictionary_copy(_state.get("technique_ranks", {}))

var skill_fragments: Dictionary:
	get:
		return _dictionary_copy(_state.get("skill_fragments", {}))

var discovered_bestiary: Array[String]:
	get:
		return _string_array(_state.get("discovered_bestiary", []))

var achievements: Dictionary:
	get:
		return _dictionary_copy(_state.get("achievements", {}))

var settings: Dictionary:
	get:
		return _dictionary_copy(_state.get("settings", DEFAULT_SETTINGS))


func _ready() -> void:
	self.load()


## Restores clean defaults. By default the reset is persisted immediately.
func reset(persist: bool = true) -> bool:
	last_error = ""
	recovered_on_last_load = false
	_state = _make_default_state()
	var persisted := true
	if persist:
		persisted = save()
	_emit_profile_changed()
	return persisted


## Loads, migrates and sanitizes a profile. Missing/corrupt files recover to a
## playable default profile; corrupt source text is retained beside the save.
func load() -> bool:
	last_error = ""
	recovered_on_last_load = false
	if not FileAccess.file_exists(save_path):
		_state = _make_default_state()
		var created_ok := true
		if auto_save:
			created_ok = save()
		profile_loaded.emit(true, false)
		_emit_profile_changed()
		return created_ok

	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return _recover_from_load_error("Không thể mở hồ sơ: %s" % error_string(FileAccess.get_open_error()), "")
	var raw_text := file.get_as_text()
	file.close()
	var parser := JSON.new()
	var parse_error := parser.parse(raw_text)
	if parse_error != OK or not parser.data is Dictionary:
		var message := "Hồ sơ JSON không hợp lệ"
		if parse_error != OK:
			message += " (dòng %d: %s)" % [parser.get_error_line(), parser.get_error_message()]
		return _recover_from_load_error(message, raw_text)

	var migrated := _migrate_profile(parser.data as Dictionary)
	_state = _sanitize_profile(migrated)
	_reconcile_stage_unlocks()
	_reconcile_earned_achievements()
	profile_loaded.emit(false, false)
	_emit_profile_changed()
	return true


## Writes only the sanitized state. Unknown/corrupt fields never round-trip.
func save() -> bool:
	last_error = ""
	if _state.is_empty():
		_state = _make_default_state()
	_state["version"] = SAVE_VERSION
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		last_error = "Không thể ghi hồ sơ: %s" % error_string(FileAccess.get_open_error())
		save_failed.emit(last_error)
		push_warning(last_error)
		return false
	file.store_string(JSON.stringify(_state, "\t", true))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "Ghi hồ sơ thất bại: %s" % error_string(write_error)
		save_failed.emit(last_error)
		push_warning(last_error)
		return false
	return true


# Explicit aliases keep call sites readable when the singleton name is present.
func reset_profile(persist: bool = true) -> bool:
	return reset(persist)


func load_profile() -> bool:
	return self.load()


func save_profile() -> bool:
	return save()


func select_stage(stage_id: StringName) -> bool:
	var id := String(stage_id)
	if not STAGES.has(id) or not is_stage_unlocked(stage_id):
		return false
	if str(_state.get("selected_stage", "")) == id:
		return true
	_state["selected_stage"] = id
	_persist_after_change()
	selection_changed.emit(selected_stage, selected_discipline)
	_emit_profile_changed()
	return true


func select_discipline(discipline_id: StringName) -> bool:
	var id := String(discipline_id)
	if not DISCIPLINES.has(id):
		return false
	if str(_state.get("selected_discipline", "")) == id:
		return true
	_state["selected_discipline"] = id
	_persist_after_change()
	selection_changed.emit(selected_stage, selected_discipline)
	_emit_profile_changed()
	return true


## Returns -1 for an unknown or max-rank technique.
func get_upgrade_cost(upgrade_id: StringName, rank_override: int = -1) -> int:
	var id := String(upgrade_id)
	if not UPGRADES.has(id):
		return -1
	var definition: Dictionary = UPGRADES[id]
	var current_rank := int(_dictionary_ref(_state.get("technique_ranks", {})).get(id, 0))
	var rank := current_rank if rank_override < 0 else rank_override
	if rank < 0 or rank >= int(definition.get("max_rank", 0)):
		return -1
	var base_cost := float(definition.get("base_cost", 0))
	var growth := float(definition.get("cost_growth", 1.0))
	return maxi(0, int(round(base_cost * pow(growth, rank))))


## Skill fragments are the persistent evolution material earned in runs. The
## cost grows per rank so a first unlock is generous while rank 4/5 remains a
## meaningful long-term chase.
func get_fragment_cost(upgrade_id: StringName, rank_override: int = -1) -> int:
	var id := String(upgrade_id)
	if not UPGRADES.has(id):
		return -1
	var definition: Dictionary = UPGRADES[id]
	var current_rank := int(_dictionary_ref(_state.get("technique_ranks", {})).get(id, 0))
	var rank := current_rank if rank_override < 0 else rank_override
	if rank < 0 or rank >= int(definition.get("max_rank", 0)):
		return -1
	var base_cost := float(definition.get("fragment_base_cost", 4))
	var growth := float(definition.get("fragment_cost_growth", 1.55))
	return maxi(1, int(round(base_cost * pow(growth, rank))))


## Purchase result is structured for UI messaging: success, error, cost, rank,
## max_rank and currency are always present.
func purchase_upgrade(upgrade_id: StringName) -> Dictionary:
	var id := String(upgrade_id)
	var result := {
		"success": false,
		"error": "unknown_upgrade",
		"upgrade_id": id,
	"cost": -1,
	"fragment_cost": -1,
		"rank": 0,
		"max_rank": 0,
		"currency": currency,
	}
	if not UPGRADES.has(id):
		return result
	var definition: Dictionary = UPGRADES[id]
	var ranks := _dictionary_ref(_state.get("technique_ranks", {}))
	var rank := int(ranks.get(id, 0))
	var max_rank := int(definition.get("max_rank", 0))
	result["rank"] = rank
	result["max_rank"] = max_rank
	if rank >= max_rank:
		result["error"] = "max_rank"
		return result
	var cost := get_fragment_cost(upgrade_id)
	result["cost"] = cost
	result["fragment_cost"] = cost
	var fragments := _dictionary_ref(_state.get("skill_fragments", {}))
	var owned := int(fragments.get(id, 0))
	result["fragments"] = owned
	if owned < cost:
		result["error"] = "insufficient_fragments"
		return result

	ranks[id] = rank + 1
	_state["technique_ranks"] = ranks
	fragments[id] = owned - cost
	_state["skill_fragments"] = fragments
	result["success"] = true
	result["error"] = ""
	result["rank"] = rank + 1
	result["currency"] = currency
	result["fragments"] = fragments[id]
	_persist_after_change()
	fragments_changed.emit(StringName(id), int(fragments[id]), -cost)
	upgrade_purchased.emit(StringName(id), rank + 1, cost)
	_emit_profile_changed()
	return result


## Finalizes exactly one run and returns a complete reward breakdown. Locked or
## unknown stages are rejected without mutating profile state.
func record_run(victory: bool, run_kills: int, elapsed: float, stage_id: StringName = &"") -> Dictionary:
	var resolved_stage := selected_stage if stage_id.is_empty() else stage_id
	var id := String(resolved_stage)
	if not STAGES.has(id):
		return {"success": false, "error": "unknown_stage", "stage_id": id, "total": 0}
	if not is_stage_unlocked(resolved_stage):
		return {"success": false, "error": "stage_locked", "stage_id": id, "total": 0}

	var safe_kills := maxi(0, run_kills)
	var safe_elapsed := elapsed
	if not is_finite(safe_elapsed) or safe_elapsed < 0.0:
		safe_elapsed = 0.0
	var stage: Dictionary = STAGES[id]
	var reward_config := _dictionary_ref(stage.get("rewards", {}))
	var records := _dictionary_ref(_state.get("stage_records", {}))
	var stage_record := _dictionary_ref(records.get(id, _make_stage_record()))
	var previous_stage_victories := int(stage_record.get("victories", 0))
	var first_clear := victory and previous_stage_victories == 0

	_state["runs"] = runs + 1
	_state["kills"] = kills + safe_kills
	if victory:
		_state["victories"] = victories + 1
	stage_record["runs"] = int(stage_record.get("runs", 0)) + 1
	stage_record["kills"] = int(stage_record.get("kills", 0)) + safe_kills
	stage_record["last_elapsed"] = safe_elapsed
	stage_record["last_victory"] = victory
	if victory:
		stage_record["victories"] = previous_stage_victories + 1
		var best_time := float(stage_record.get("best_time", -1.0))
		if best_time < 0.0 or safe_elapsed < best_time:
			stage_record["best_time"] = safe_elapsed
	records[id] = stage_record
	_state["stage_records"] = records

	var unlocks_before := unlocked_stages
	_reconcile_stage_unlocks()
	var new_unlocks := _array_difference(unlocked_stages, unlocks_before)
	var next_stage_id := id
	if victory:
		var stage_index := STAGE_ORDER.find(id)
		if stage_index >= 0:
			for candidate_index in range(stage_index + 1, STAGE_ORDER.size()):
				if unlocked_stages.has(STAGE_ORDER[candidate_index]):
					next_stage_id = STAGE_ORDER[candidate_index]
					break
		_state["selected_stage"] = next_stage_id
	var new_bestiary: Array[String] = []
	for entry_id: Variant in stage.get("bestiary", []):
		_discover_bestiary_internal(str(entry_id), new_bestiary)
	if victory:
		for entry_id: Variant in stage.get("victory_bestiary", []):
			_discover_bestiary_internal(str(entry_id), new_bestiary)

	var base_reward := maxi(0, int(reward_config.get("base", 0)))
	var victory_bonus := maxi(0, int(reward_config.get("victory_bonus", 0))) if victory else 0
	var kill_bonus := maxi(0, int(round(safe_kills * float(reward_config.get("per_kill", 0.0)))))
	var speed_bonus := 0
	if victory:
		var speed_par := maxf(1.0, float(reward_config.get("speed_par_seconds", 240.0)))
		var max_speed_bonus := maxi(0, int(reward_config.get("max_speed_bonus", 0)))
		var speed_ratio := clampf((speed_par - safe_elapsed) / speed_par, 0.0, 1.0)
		speed_bonus = int(round(max_speed_bonus * speed_ratio))
	var first_clear_bonus := maxi(0, int(reward_config.get("first_clear_bonus", 0))) if first_clear else 0
	var achievement_context := {
		"victory": victory,
		"elapsed": safe_elapsed,
		"stage_id": id,
	}
	var new_achievements := _evaluate_and_unlock_achievements(achievement_context)
	var achievement_bonus := 0
	for achievement_id: String in new_achievements:
		achievement_bonus += int(_dictionary_ref(ACHIEVEMENTS[achievement_id]).get("reward_currency", 0))
	var total_reward := base_reward + victory_bonus + kill_bonus + speed_bonus + first_clear_bonus + achievement_bonus
	var fragment_drops: Dictionary = {}
	var fragment_drop_count := maxi(1, int(safe_kills / 18) + (3 if victory else 1))
	var primary_fragment: String = UPGRADE_ORDER[(maxi(0, STAGE_ORDER.find(id)) + (1 if victory else 0)) % UPGRADE_ORDER.size()]
	fragment_drops[primary_fragment] = fragment_drop_count
	var fragments := _dictionary_ref(_state.get("skill_fragments", {}))
	for fragment_id: String in fragment_drops.keys():
		var delta := int(fragment_drops[fragment_id])
		fragments[fragment_id] = int(fragments.get(fragment_id, 0)) + delta
		fragments_changed.emit(StringName(fragment_id), int(fragments[fragment_id]), delta)
	_state["skill_fragments"] = fragments
	_state["currency"] = currency + total_reward
	_persist_after_change()

	currency_changed.emit(currency, total_reward)
	if not new_achievements.is_empty():
		achievements_unlocked.emit(new_achievements)
	if not new_bestiary.is_empty():
		bestiary_discovered.emit(new_bestiary)
	_emit_profile_changed()
	return {
		"success": true,
		"error": "",
		"stage_id": id,
		"victory": victory,
		"kills": safe_kills,
		"elapsed": safe_elapsed,
		"first_clear": first_clear,
		"base": base_reward,
		"victory_bonus": victory_bonus,
		"kill_bonus": kill_bonus,
		"speed_bonus": speed_bonus,
		"first_clear_bonus": first_clear_bonus,
		"achievement_bonus": achievement_bonus,
		"total": total_reward,
		"currency_after": currency,
		"new_unlocks": new_unlocks,
		"next_stage_id": next_stage_id,
		"fragment_drops": fragment_drops,
		"new_achievements": new_achievements,
		"new_bestiary": new_bestiary,
	}


func is_stage_unlocked(stage_id: StringName) -> bool:
	var id := String(stage_id)
	return STAGES.has(id) and unlocked_stages.has(id)


func discover_bestiary(entry_id: StringName) -> bool:
	var added: Array[String] = []
	if not _discover_bestiary_internal(String(entry_id), added):
		return false
	_persist_after_change()
	bestiary_discovered.emit(added)
	_emit_profile_changed()
	return true


func is_bestiary_discovered(entry_id: StringName) -> bool:
	return discovered_bestiary.has(String(entry_id))


func set_setting(setting_id: StringName, value: Variant) -> bool:
	var id := _canonical_setting_id(String(setting_id))
	if not DEFAULT_SETTINGS.has(id):
		return false
	var current := settings
	var sanitized: Variant = _sanitize_setting(id, value, DEFAULT_SETTINGS[id])
	if current.get(id) == sanitized:
		return true
	current[id] = sanitized
	_state["settings"] = current
	_persist_after_change()
	settings_changed.emit(settings)
	_emit_profile_changed()
	return true


func update_setting(setting_id: StringName, value: Variant) -> bool:
	return set_setting(setting_id, value)


func apply_settings(changes: Dictionary) -> bool:
	var current := settings
	var changed := false
	for setting_id: Variant in changes.keys():
		var id := _canonical_setting_id(str(setting_id))
		if not DEFAULT_SETTINGS.has(id):
			continue
		var sanitized: Variant = _sanitize_setting(id, changes[setting_id], DEFAULT_SETTINGS[id])
		if current.get(id) != sanitized:
			current[id] = sanitized
			changed = true
	if not changed:
		return false
	_state["settings"] = current
	_persist_after_change()
	settings_changed.emit(settings)
	_emit_profile_changed()
	return true


func grant_currency(amount: int) -> int:
	var safe_amount := maxi(0, amount)
	if safe_amount == 0:
		return currency
	_state["currency"] = currency + safe_amount
	_persist_after_change()
	currency_changed.emit(currency, safe_amount)
	_emit_profile_changed()
	return currency


func get_profile_snapshot() -> Dictionary:
	return _state.duplicate(true)


func get_profile() -> Dictionary:
	return get_profile_snapshot()


func get_stage_data(stage_id: StringName) -> Dictionary:
	return _data_copy(STAGES, String(stage_id))


func get_stages() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in STAGE_ORDER:
		var data := _data_copy(STAGES, id)
		data["unlocked"] = is_stage_unlocked(StringName(id))
		data["record"] = get_stage_record(StringName(id))
		result.append(data)
	return result


func get_stage_record(stage_id: StringName) -> Dictionary:
	if not STAGES.has(String(stage_id)):
		return {}
	var records := _dictionary_ref(_state.get("stage_records", {}))
	return _dictionary_copy(records.get(String(stage_id), _make_stage_record()))


func get_discipline_data(discipline_id: StringName) -> Dictionary:
	return _data_copy(DISCIPLINES, String(discipline_id))


func get_disciplines() -> Array[Dictionary]:
	return _ordered_data(DISCIPLINES, DISCIPLINE_ORDER)


func get_upgrade_data(upgrade_id: StringName) -> Dictionary:
	var data := _data_copy(UPGRADES, String(upgrade_id))
	if data.is_empty():
		return data
	data["rank"] = int(technique_ranks.get(String(upgrade_id), 0))
	data["next_cost"] = get_upgrade_cost(upgrade_id)
	data["fragment_cost"] = get_fragment_cost(upgrade_id)
	data["fragments_owned"] = int(skill_fragments.get(String(upgrade_id), 0))
	return data


func get_upgrades() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in UPGRADE_ORDER:
		result.append(get_upgrade_data(StringName(id)))
	return result


## Frontend naming alias: permanent upgrades are presented as "techniques".
func get_techniques() -> Array[Dictionary]:
	return get_upgrades()


## Boolean convenience API for simple buttons. Call purchase_upgrade() when the
## UI needs the structured failure reason or purchase receipt.
func purchase_technique(technique_id: StringName) -> bool:
	return bool(purchase_upgrade(technique_id).get("success", false))


func get_bestiary_data(entry_id: StringName) -> Dictionary:
	var data := _data_copy(BESTIARY, String(entry_id))
	if not data.is_empty():
		data["discovered"] = is_bestiary_discovered(entry_id)
	return data


func get_bestiary_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in BESTIARY_ORDER:
		result.append(get_bestiary_data(StringName(id)))
	return result


func get_achievement_data(achievement_id: StringName) -> Dictionary:
	var id := String(achievement_id)
	var data := _data_copy(ACHIEVEMENTS, id)
	if not data.is_empty():
		data["unlocked"] = bool(achievements.get(id, false))
		data["progress"] = get_achievement_progress(achievement_id)
	return data


func get_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in ACHIEVEMENT_ORDER:
		result.append(get_achievement_data(StringName(id)))
	return result


func get_achievement_progress(achievement_id: StringName) -> Dictionary:
	var id := String(achievement_id)
	if not ACHIEVEMENTS.has(id):
		return {"current": 0.0, "target": 0.0}
	var requirement := _dictionary_ref(_dictionary_ref(ACHIEVEMENTS[id]).get("requirement", {}))
	var requirement_type := str(requirement.get("type", ""))
	match requirement_type:
		"runs":
			return {"current": runs, "target": int(requirement.get("amount", 1))}
		"kills":
			return {"current": kills, "target": int(requirement.get("amount", 1))}
		"stage_victories":
			var record := get_stage_record(StringName(str(requirement.get("stage_id", ""))))
			return {"current": int(record.get("victories", 0)), "target": int(requirement.get("amount", 1))}
		"fast_victory":
			var target := float(requirement.get("seconds", 180.0))
			var best := _best_victory_time()
			return {"current": best, "target": target, "lower_is_better": true}
	return {"current": 0.0, "target": 0.0}


## Combines stage, discipline and permanent modifiers into a combat-ready flat
## dictionary. Multipliers compose; elite_chance_add composes additively.
func get_run_modifiers(stage_id: StringName = &"", discipline_id: StringName = &"") -> Dictionary:
	var resolved_stage := selected_stage if stage_id.is_empty() else stage_id
	var resolved_discipline := selected_discipline if discipline_id.is_empty() else discipline_id
	if not STAGES.has(String(resolved_stage)):
		resolved_stage = &"van_mong"
	if not DISCIPLINES.has(String(resolved_discipline)):
		resolved_discipline = &"van_kiem"
	var result := {
		"damage_mult": 1.0,
		"attack_interval_mult": 1.0,
		"max_health_mult": 1.0,
		"damage_taken_mult": 1.0,
		"xp_mult": 1.0,
		"pickup_range_mult": 1.0,
		"movement_speed_mult": 1.0,
		"enemy_health_mult": 1.0,
		"enemy_damage_mult": 1.0,
		"spawn_interval_mult": 1.0,
		"elite_chance_add": 0.0,
		"boss_health_mult": 1.0,
	}
	_compose_modifiers(result, _dictionary_ref(_dictionary_ref(STAGES[String(resolved_stage)]).get("modifiers", {})))
	_compose_modifiers(result, _dictionary_ref(_dictionary_ref(DISCIPLINES[String(resolved_discipline)]).get("modifiers", {})))
	_compose_modifiers(result, get_permanent_modifiers())
	result["stage_id"] = String(resolved_stage)
	result["discipline_id"] = String(resolved_discipline)
	return result


func get_permanent_modifiers() -> Dictionary:
	var result := {
		"damage_mult": 1.0,
		"max_health_mult": 1.0,
		"pickup_range_mult": 1.0,
		"xp_mult": 1.0,
	}
	var ranks := technique_ranks
	for id: String in UPGRADE_ORDER:
		var rank := int(ranks.get(id, 0))
		var definition := _dictionary_ref(UPGRADES[id])
		var effect_key := str(definition.get("effect_key", ""))
		if result.has(effect_key):
			result[effect_key] = 1.0 + rank * float(definition.get("effect_per_rank", 0.0))
		var secondary_key := str(definition.get("secondary_effect_key", ""))
		if result.has(secondary_key):
			result[secondary_key] = 1.0 + rank * float(definition.get("secondary_effect_per_rank", 0.0))
	return result


func _make_default_state() -> Dictionary:
	var ranks: Dictionary = {}
	var fragments: Dictionary = {}
	for id: String in UPGRADE_ORDER:
		ranks[id] = 0
		fragments[id] = 10
	var unlocked_achievements: Dictionary = {}
	for id: String in ACHIEVEMENT_ORDER:
		unlocked_achievements[id] = false
	var records: Dictionary = {}
	for id: String in STAGE_ORDER:
		records[id] = _make_stage_record()
	return {
		"version": SAVE_VERSION,
		"currency": 150,
		"victories": 0,
		"runs": 0,
		"kills": 0,
		"unlocked_stages": ["van_mong"],
		"selected_stage": "van_mong",
		"selected_discipline": "van_kiem",
		"technique_ranks": ranks,
		"skill_fragments": fragments,
		"stage_records": records,
		"discovered_bestiary": [],
		"achievements": unlocked_achievements,
		"settings": DEFAULT_SETTINGS.duplicate(true),
	}


func _make_stage_record() -> Dictionary:
	return {
		"runs": 0,
		"victories": 0,
		"kills": 0,
		"best_time": -1.0,
		"last_elapsed": 0.0,
		"last_victory": false,
	}


func _migrate_profile(raw: Dictionary) -> Dictionary:
	var source := raw.duplicate(true)
	if source.get("profile") is Dictionary:
		var wrapped := (source.get("profile") as Dictionary).duplicate(true)
		if not wrapped.has("version"):
			wrapped["version"] = source.get("version", 0)
		source = wrapped
	# Legacy aliases are accepted regardless of the claimed version. This also
	# repairs hand-edited saves that mixed schemas.
	_copy_alias_if_missing(source, "currency", ["souls", "spirit_stones", "linh_thach"])
	_copy_alias_if_missing(source, "victories", ["wins"])
	_copy_alias_if_missing(source, "runs", ["games_played", "attempts"])
	_copy_alias_if_missing(source, "kills", ["total_kills"])
	_copy_alias_if_missing(source, "selected_discipline", ["selected_path", "discipline"])
	_copy_alias_if_missing(source, "technique_ranks", ["upgrades", "techniques"])
	_copy_alias_if_missing(source, "discovered_bestiary", ["codex", "bestiary"])
	if not source.has("settings") and source.get("audio") is Dictionary:
		var audio := source.get("audio") as Dictionary
		source["settings"] = {
			"master": audio.get("master", DEFAULT_SETTINGS.master),
			"music": audio.get("music", DEFAULT_SETTINGS.music),
			"sfx": audio.get("sfx", DEFAULT_SETTINGS.sfx),
		}
	source["version"] = SAVE_VERSION
	return source


func _sanitize_profile(source: Dictionary) -> Dictionary:
	var result := _make_default_state()
	result["currency"] = _nonnegative_int(source.get("currency"), result.currency)
	result["victories"] = _nonnegative_int(source.get("victories"), result.victories)
	result["runs"] = _nonnegative_int(source.get("runs"), result.runs)
	result["kills"] = _nonnegative_int(source.get("kills"), result.kills)

	var sanitized_records := _dictionary_ref(result.stage_records)
	var source_records := _dictionary_ref(source.get("stage_records", {}))
	for id: String in STAGE_ORDER:
		var record := _make_stage_record()
		var source_record := _dictionary_ref(source_records.get(id, {}))
		record["runs"] = _nonnegative_int(source_record.get("runs"), 0)
		record["victories"] = _nonnegative_int(source_record.get("victories"), 0)
		record["kills"] = _nonnegative_int(source_record.get("kills"), 0)
		record["best_time"] = _safe_time(source_record.get("best_time"), -1.0, true)
		record["last_elapsed"] = _safe_time(source_record.get("last_elapsed"), 0.0, false)
		record["last_victory"] = bool(source_record.get("last_victory", false))
		sanitized_records[id] = record
	result["stage_records"] = sanitized_records

	var unlocked := _filter_known_ids(source.get("unlocked_stages", []), STAGES)
	if not unlocked.has("van_mong"):
		unlocked.push_front("van_mong")
	result["unlocked_stages"] = _ordered_subset(unlocked, STAGE_ORDER)
	var selected_stage_id := str(source.get("selected_stage", "van_mong"))
	if not STAGES.has(selected_stage_id) or not unlocked.has(selected_stage_id):
		selected_stage_id = "van_mong"
	result["selected_stage"] = selected_stage_id
	var selected_discipline_id := str(source.get("selected_discipline", "van_kiem"))
	if not DISCIPLINES.has(selected_discipline_id):
		selected_discipline_id = "van_kiem"
	result["selected_discipline"] = selected_discipline_id

	var ranks := _dictionary_ref(result.technique_ranks)
	var source_ranks := _dictionary_ref(source.get("technique_ranks", {}))
	for id: String in UPGRADE_ORDER:
		var max_rank := int(_dictionary_ref(UPGRADES[id]).get("max_rank", 0))
		ranks[id] = clampi(_nonnegative_int(source_ranks.get(id), 0), 0, max_rank)
	result["technique_ranks"] = ranks
	var fragments := _dictionary_ref(result.get("skill_fragments", {}))
	var source_fragments := _dictionary_ref(source.get("skill_fragments", {}))
	for id: String in UPGRADE_ORDER:
		fragments[id] = _nonnegative_int(source_fragments.get(id), int(fragments.get(id, 10)))
	result["skill_fragments"] = fragments
	result["discovered_bestiary"] = _ordered_subset(
		_filter_known_ids(source.get("discovered_bestiary", []), BESTIARY),
		BESTIARY_ORDER
	)

	var unlocked_achievements := _dictionary_ref(result.achievements)
	var source_achievements: Variant = source.get("achievements", {})
	if source_achievements is Array:
		for raw_id: Variant in source_achievements:
			var id := str(raw_id)
			if ACHIEVEMENTS.has(id):
				unlocked_achievements[id] = true
	elif source_achievements is Dictionary:
		for id: String in ACHIEVEMENT_ORDER:
			unlocked_achievements[id] = bool((source_achievements as Dictionary).get(id, false))
	result["achievements"] = unlocked_achievements

	var sanitized_settings := DEFAULT_SETTINGS.duplicate(true)
	var source_settings := _dictionary_ref(source.get("settings", {}))
	for id: String in DEFAULT_SETTINGS.keys():
		var source_value: Variant = source_settings.get(id, source_settings.get(id + "_volume"))
		sanitized_settings[id] = _sanitize_setting(id, source_value, DEFAULT_SETTINGS[id])
	result["settings"] = sanitized_settings
	return result


func _reconcile_stage_unlocks() -> void:
	var current := unlocked_stages
	if not current.has("van_mong"):
		current.append("van_mong")
	for id: String in STAGE_ORDER:
		if current.has(id):
			continue
		var stage := _dictionary_ref(STAGES[id])
		var unlock := _dictionary_ref(stage.get("unlock", {}))
		var required_total := int(unlock.get("required_total_victories", 0))
		var required_stage := str(unlock.get("required_stage", ""))
		var required_stage_victories := int(unlock.get("required_stage_victories", 0))
		var stage_wins := required_stage_victories
		if not required_stage.is_empty():
			stage_wins = int(get_stage_record(StringName(required_stage)).get("victories", 0))
		if victories >= required_total and stage_wins >= required_stage_victories:
			current.append(id)
	_state["unlocked_stages"] = _ordered_subset(current, STAGE_ORDER)
	if not current.has(str(_state.get("selected_stage", "van_mong"))):
		_state["selected_stage"] = "van_mong"


func _reconcile_earned_achievements() -> void:
	_evaluate_and_unlock_achievements({})


func _evaluate_and_unlock_achievements(context: Dictionary) -> Array[String]:
	var unlocked := _dictionary_ref(_state.get("achievements", {}))
	var newly_unlocked: Array[String] = []
	for id: String in ACHIEVEMENT_ORDER:
		if bool(unlocked.get(id, false)):
			continue
		var definition := _dictionary_ref(ACHIEVEMENTS[id])
		var requirement := _dictionary_ref(definition.get("requirement", {}))
		if _achievement_requirement_met(requirement, context):
			unlocked[id] = true
			newly_unlocked.append(id)
	_state["achievements"] = unlocked
	return newly_unlocked


func _achievement_requirement_met(requirement: Dictionary, context: Dictionary) -> bool:
	match str(requirement.get("type", "")):
		"runs":
			return runs >= int(requirement.get("amount", 1))
		"kills":
			return kills >= int(requirement.get("amount", 1))
		"stage_victories":
			var record := get_stage_record(StringName(str(requirement.get("stage_id", ""))))
			return int(record.get("victories", 0)) >= int(requirement.get("amount", 1))
		"fast_victory":
			if bool(context.get("victory", false)):
				return float(context.get("elapsed", INF)) <= float(requirement.get("seconds", 180.0))
			var best := _best_victory_time()
			return best >= 0.0 and best <= float(requirement.get("seconds", 180.0))
	return false


func _best_victory_time() -> float:
	var best := -1.0
	for id: String in STAGE_ORDER:
		var candidate := float(get_stage_record(StringName(id)).get("best_time", -1.0))
		if candidate >= 0.0 and (best < 0.0 or candidate < best):
			best = candidate
	return best


func _discover_bestiary_internal(id: String, added: Array[String]) -> bool:
	if not BESTIARY.has(id):
		return false
	var discovered := discovered_bestiary
	if discovered.has(id):
		return false
	discovered.append(id)
	_state["discovered_bestiary"] = _ordered_subset(discovered, BESTIARY_ORDER)
	added.append(id)
	return true


func _recover_from_load_error(reason: String, raw_text: String) -> bool:
	last_error = reason
	recovered_on_last_load = true
	if not raw_text.is_empty():
		_backup_corrupt_save(raw_text)
	_state = _make_default_state()
	if auto_save:
		save()
	# Keep the recovery reason observable even when the replacement save worked.
	last_error = reason
	profile_loaded.emit(true, true)
	_emit_profile_changed()
	push_warning(reason)
	return true


func _backup_corrupt_save(raw_text: String) -> void:
	var backup_path := save_path + ".corrupt"
	var backup := FileAccess.open(backup_path, FileAccess.WRITE)
	if backup == null:
		return
	backup.store_string(raw_text)
	backup.close()


func _persist_after_change() -> void:
	if auto_save:
		save()


func _emit_profile_changed() -> void:
	profile_changed.emit(get_profile_snapshot())


func _compose_modifiers(target: Dictionary, source: Dictionary) -> void:
	for raw_key: Variant in source.keys():
		var key := str(raw_key)
		if not target.has(key):
			continue
		if key.ends_with("_add"):
			target[key] = float(target[key]) + float(source[raw_key])
		else:
			target[key] = float(target[key]) * float(source[raw_key])


func _sanitize_setting(id: String, value: Variant, fallback: Variant) -> Variant:
	if id in ["master", "music", "sfx"]:
		if value is int or value is float:
			var numeric := float(value)
			if is_finite(numeric):
				return clampf(numeric, 0.0, 1.0)
		return float(fallback)
	if value is bool:
		return value
	return bool(fallback)


func _canonical_setting_id(id: String) -> String:
	match id:
		"master_volume":
			return "master"
		"music_volume":
			return "music"
		"sfx_volume":
			return "sfx"
	return id


func _safe_time(value: Variant, fallback: float, allow_negative_one: bool) -> float:
	if value is int or value is float:
		var numeric := float(value)
		if is_finite(numeric) and (numeric >= 0.0 or (allow_negative_one and is_equal_approx(numeric, -1.0))):
			return numeric
	return fallback


func _nonnegative_int(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		var numeric := float(value)
		if is_finite(numeric):
			return maxi(0, int(numeric))
	return fallback


func _filter_known_ids(value: Variant, catalog: Dictionary) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for raw_id: Variant in value:
		var id := str(raw_id)
		if catalog.has(id) and not result.has(id):
			result.append(id)
	return result


func _ordered_subset(ids: Array[String], order: Array) -> Array[String]:
	var result: Array[String] = []
	for raw_id: Variant in order:
		var id := str(raw_id)
		if ids.has(id):
			result.append(id)
	return result


func _array_difference(values: Array[String], previous: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		if not previous.has(value):
			result.append(value)
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item: Variant in value:
			result.append(str(item))
	return result


func _dictionary_ref(value: Variant) -> Dictionary:
	return value as Dictionary if value is Dictionary else {}


func _dictionary_copy(value: Variant) -> Dictionary:
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _data_copy(catalog: Dictionary, id: String) -> Dictionary:
	return _dictionary_copy(catalog.get(id, {}))


func _ordered_data(catalog: Dictionary, order: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_id: Variant in order:
		result.append(_data_copy(catalog, str(raw_id)))
	return result


func _copy_alias_if_missing(target: Dictionary, canonical: String, aliases: Array) -> void:
	if target.has(canonical):
		return
	for alias: Variant in aliases:
		if target.has(alias):
			target[canonical] = target[alias]
			return
