extends Node

## Verifies that the hash-bound visual-review evidence is present, decodable and
## still at its declared native viewport. The quality runner records hashes for
## the same artifacts after this command passes.

const DESKTOP_ARTIFACTS := [
	"res://production/playtests/frontend/title.png",
	"res://production/playtests/frontend/hub.png",
	"res://production/playtests/frontend/stages.png",
	"res://production/playtests/frontend/loadout.png",
	"res://production/playtests/frontend/inventory.png",
	"res://production/playtests/frontend/spirit-beast.png",
	"res://production/playtests/frontend/techniques.png",
	"res://production/playtests/frontend/technique-upgrade.png",
	"res://production/playtests/frontend/codex.png",
	"res://production/playtests/frontend/achievements.png",
	"res://production/playtests/frontend/settings.png",
	"res://production/playtests/frontend/reset.png",
	"res://production/playtests/frontend/results.png",
	"res://production/playtests/frontend/results-defeat.png",
	"res://production/playtests/overhaul/gameplay-final.png",
	"res://production/playtests/overhaul/boss-final.png",
	"res://production/playtests/overhaul/upgrade-final.png",
	"res://production/playtests/overhaul/pause-final.png",
	"res://production/playtests/overhaul/victory-final.png",
	"res://production/playtests/overhaul/defeat-final.png",
	"res://production/playtests/vfx/sword-rank1.png",
	"res://production/playtests/vfx/sword-rank5.png",
	"res://production/playtests/vfx/jade-rank1.png",
	"res://production/playtests/vfx/jade-rank5.png",
	"res://production/playtests/vfx/qi-rank1.png",
	"res://production/playtests/vfx/qi-rank5.png",
]

const PHONE_ARTIFACTS := [
	"res://production/playtests/frontend/title-phone.png",
	"res://production/playtests/frontend/hub-phone.png",
	"res://production/playtests/frontend/stages-phone.png",
	"res://production/playtests/frontend/loadout-phone.png",
	"res://production/playtests/frontend/inventory-phone.png",
	"res://production/playtests/frontend/spirit-beast-phone.png",
	"res://production/playtests/frontend/techniques-phone.png",
	"res://production/playtests/frontend/technique-upgrade-phone.png",
	"res://production/playtests/frontend/codex-phone.png",
	"res://production/playtests/frontend/achievements-phone.png",
	"res://production/playtests/frontend/settings-phone.png",
	"res://production/playtests/frontend/reset-phone.png",
	"res://production/playtests/frontend/results-phone.png",
	"res://production/playtests/frontend/results-defeat-phone.png",
	"res://production/playtests/mobile-support/combat-phone.png",
	"res://production/playtests/mobile-support/boss-phone.png",
	"res://production/playtests/mobile-support/breakthrough-phone.png",
	"res://production/playtests/mobile-support/pause-phone.png",
]

const SPECIAL_ARTIFACTS := {
	"res://production/playtests/mobile-support/landscape-controls.png": Vector2i(1600, 900),
	"res://production/playtests/mobile-support/portrait-overlay.png": Vector2i(900, 1600),
	"res://production/playtests/responsive/hub-wide.png": Vector2i(2100, 900),
	"res://production/playtests/responsive/combat-wide-touch.png": Vector2i(2100, 900),
	"res://production/playtests/responsive/reset-wide.png": Vector2i(2100, 900),
}

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	for path in DESKTOP_ARTIFACTS:
		_validate_image(path, Vector2i(1600, 900))
	for path in PHONE_ARTIFACTS:
		_validate_image(path, Vector2i(844, 390))
	for path: String in SPECIAL_ARTIFACTS:
		_validate_image(path, SPECIAL_ARTIFACTS[path] as Vector2i)
	if failures.is_empty():
		print("VISUAL EVIDENCE RESULT: PASS; artifacts=", DESKTOP_ARTIFACTS.size() + PHONE_ARTIFACTS.size() + SPECIAL_ARTIFACTS.size())
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("VISUAL EVIDENCE RESULT: FAIL (", failures.size(), ")")
		get_tree().quit(1)


func _validate_image(path: String, expected_size: Vector2i) -> void:
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		failures.append("Missing visual evidence: %s" % path)
		return
	var image := Image.load_from_file(absolute)
	if image == null or image.is_empty():
		failures.append("Undecodable visual evidence: %s" % path)
		return
	var actual := Vector2i(image.get_width(), image.get_height())
	if actual != expected_size:
		failures.append("Wrong visual evidence size: %s expected=%s actual=%s" % [path, expected_size, actual])
		return
	print("PASS: visual evidence ", path, " ", actual.x, "x", actual.y)
