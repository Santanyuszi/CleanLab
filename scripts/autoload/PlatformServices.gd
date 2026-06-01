extends Node
## Thin platform bridge for external game services.
##
## The editor and desktop builds use this as a no-op implementation. Android can
## later route these calls to a Google Play Games Services Android plugin.

const GOOGLE_ACHIEVEMENT_IDS := {
	# Fill after Play Console achievements are created.
	# Suggested key format: "reports_delivered.bronze".
}

var _play_games = null


func _ready() -> void:
	if Engine.has_singleton("GooglePlayGames"):
		_play_games = Engine.get_singleton("GooglePlayGames")


func is_available() -> bool:
	return _play_games != null


func sign_in() -> void:
	if _play_games != null and _play_games.has_method("sign_in"):
		_play_games.sign_in()


func unlock_achievement(local_id: String, tier_key: String) -> void:
	var external_id := _external_achievement_id(local_id, tier_key)
	if external_id.is_empty():
		return
	if _play_games != null and _play_games.has_method("unlock_achievement"):
		_play_games.unlock_achievement(external_id)


func increment_achievement(local_id: String, tier_key: String, amount: int = 1) -> void:
	var external_id := _external_achievement_id(local_id, tier_key)
	if external_id.is_empty():
		return
	if _play_games != null and _play_games.has_method("increment_achievement"):
		_play_games.increment_achievement(external_id, amount)


func show_achievements_ui() -> void:
	if _play_games != null and _play_games.has_method("show_achievements"):
		_play_games.show_achievements()


func _external_achievement_id(local_id: String, tier_key: String) -> String:
	return str(GOOGLE_ACHIEVEMENT_IDS.get("%s.%s" % [local_id, tier_key], ""))
