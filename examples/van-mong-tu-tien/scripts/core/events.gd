extends Node

signal start_requested
signal restart_requested
signal resume_requested
signal upgrade_selected(upgrade_id: StringName)
signal player_health_changed(current: float, maximum: float)
signal experience_changed(current: float, required: float, level: int)
signal realm_changed(realm_name: String, subtitle: String)
signal run_stats_changed(elapsed: float, duration: float, kills: int)
signal pulse_state_changed(remaining: float, cooldown: float)
signal companion_state_changed(remaining: float, cooldown: float, active: bool)
signal qi_collected(value: float)
signal sword_fired(empowered: bool)
signal enemy_defeated(was_boss: bool)
signal upgrade_options_presented(options: Array[Dictionary])
signal banner_requested(title: String, subtitle: String, duration: float)
signal game_started
signal game_paused(is_paused: bool)
signal game_finished(victory: bool, title: String, details: String)
