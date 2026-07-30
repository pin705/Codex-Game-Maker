class_name GameConfig
extends RefCounted

const BALANCE_PATH := "res://resources/tuning/game_balance.json"

static func load_balance() -> Dictionary:
	if not FileAccess.file_exists(BALANCE_PATH):
		push_error("Missing balance file: %s" % BALANCE_PATH)
		return {}
	var file := FileAccess.open(BALANCE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open balance file: %s" % BALANCE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed as Dictionary
	push_error("Invalid JSON in balance file: %s" % BALANCE_PATH)
	return {}

static func section(balance: Dictionary, key: StringName) -> Dictionary:
	var value: Variant = balance.get(key, {})
	return value as Dictionary if value is Dictionary else {}

