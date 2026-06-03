extends Node
## Thin platform bridge for external game services.
##
## The editor and desktop builds use this as a no-op implementation. Android
## routes these calls to the Google Play Games Services Android plugin.
##
## HOW TO FILL IN ACHIEVEMENT IDs:
## 1. Open Play Console → Play Games Services → Setup → Achievements.
## 2. Create one achievement per entry (18 total). Use the achievement name
##    from AchievementManager.CATALOG.
## 3. Copy each achievement's ID (looks like "CgkI...") into GOOGLE_ACHIEVEMENT_IDS
##    below, using the key format "<local_id>.<tier_key>".
##    - tier_key values: "bronze", "silver", "gold", "certified"
##    - For incremental achievements set type to "Incremental" in Play Console
##      and match the threshold counts in AchievementManager.CATALOG.

const GOOGLE_ACHIEVEMENT_IDS := {
	# --- Sample Handler ---
	"sample_handler.bronze": "",
	"sample_handler.silver": "",
	"sample_handler.gold": "",
	"sample_handler.certified": "",
	# --- Extraction Specialist ---
	"extraction_specialist.bronze": "",
	"extraction_specialist.silver": "",
	"extraction_specialist.gold": "",
	"extraction_specialist.certified": "",
	# --- Drying Specialist ---
	"drying_specialist.bronze": "",
	"drying_specialist.silver": "",
	"drying_specialist.gold": "",
	"drying_specialist.certified": "",
	# --- Microscope Operator ---
	"microscope_operator.bronze": "",
	"microscope_operator.silver": "",
	"microscope_operator.gold": "",
	"microscope_operator.certified": "",
	# --- Particle Hunter ---
	"particle_hunter.bronze": "",
	"particle_hunter.silver": "",
	"particle_hunter.gold": "",
	"particle_hunter.certified": "",
	# --- Metallic Expert ---
	"metallic_expert.bronze": "",
	"metallic_expert.silver": "",
	"metallic_expert.gold": "",
	"metallic_expert.certified": "",
	# --- Fiber Expert ---
	"fiber_expert.bronze": "",
	"fiber_expert.silver": "",
	"fiber_expert.gold": "",
	"fiber_expert.certified": "",
	# --- Non-Metallic Expert ---
	"non_metallic_expert.bronze": "",
	"non_metallic_expert.silver": "",
	"non_metallic_expert.gold": "",
	"non_metallic_expert.certified": "",
	# --- Fast Analyst ---
	"fast_analyst.bronze": "",
	"fast_analyst.silver": "",
	"fast_analyst.gold": "",
	"fast_analyst.certified": "",
	# --- Accuracy Master ---
	"accuracy_master.bronze": "",
	"accuracy_master.silver": "",
	"accuracy_master.gold": "",
	"accuracy_master.certified": "",
	# --- Truck Dispatcher ---
	"truck_dispatcher.bronze": "",
	"truck_dispatcher.silver": "",
	"truck_dispatcher.gold": "",
	"truck_dispatcher.certified": "",
	# --- Factory Flow ---
	"factory_flow.bronze": "",
	"factory_flow.silver": "",
	"factory_flow.gold": "",
	"factory_flow.certified": "",
	# --- Customer Satisfaction ---
	"customer_satisfaction.bronze": "",
	"customer_satisfaction.silver": "",
	"customer_satisfaction.gold": "",
	"customer_satisfaction.certified": "",
	# --- Reputation Builder ---
	"reputation_builder.bronze": "",
	"reputation_builder.silver": "",
	"reputation_builder.gold": "",
	"reputation_builder.certified": "",
	# --- Upgrade Engineer ---
	"upgrade_engineer.bronze": "",
	"upgrade_engineer.silver": "",
	"upgrade_engineer.gold": "",
	"upgrade_engineer.certified": "",
	# --- Automation Expert ---
	"automation_expert.bronze": "",
	"automation_expert.silver": "",
	"automation_expert.gold": "",
	"automation_expert.certified": "",
	# --- Cleanroom Discipline ---
	"cleanroom_discipline.bronze": "",
	"cleanroom_discipline.silver": "",
	"cleanroom_discipline.gold": "",
	"cleanroom_discipline.certified": "",
	# --- Technical Cleanliness Master ---
	"technical_cleanliness_master.bronze": "",
	"technical_cleanliness_master.silver": "",
	"technical_cleanliness_master.gold": "",
	"technical_cleanliness_master.certified": "",
}

var _play_games = null


func _ready() -> void:
	if Engine.has_singleton("GooglePlayGames"):
		_play_games = Engine.get_singleton("GooglePlayGames")
	if is_available():
		sign_in()


func is_available() -> bool:
	return _play_games != null and _has_required_methods() and _has_configured_achievement_ids()


func sign_in() -> void:
	if _play_games != null and _play_games.has_method("sign_in"):
		_play_games.sign_in()


func unlock_achievement(local_id: String, tier_key: String) -> void:
	if not is_available():
		return
	var external_id := _external_achievement_id(local_id, tier_key)
	if external_id.is_empty():
		return
	if _play_games.has_method("unlock_achievement"):
		_play_games.unlock_achievement(external_id)


func increment_achievement(local_id: String, tier_key: String, amount: int = 1) -> void:
	if not is_available():
		return
	var external_id := _external_achievement_id(local_id, tier_key)
	if external_id.is_empty():
		return
	if _play_games.has_method("increment_achievement"):
		_play_games.increment_achievement(external_id, amount)


func show_achievements_ui() -> void:
	if is_available() and _play_games.has_method("show_achievements"):
		_play_games.show_achievements()


func _external_achievement_id(local_id: String, tier_key: String) -> String:
	return str(GOOGLE_ACHIEVEMENT_IDS.get("%s.%s" % [local_id, tier_key], ""))


func _has_required_methods() -> bool:
	return (
		_play_games.has_method("sign_in")
		and _play_games.has_method("unlock_achievement")
		and _play_games.has_method("increment_achievement")
		and _play_games.has_method("show_achievements")
	)


func _has_configured_achievement_ids() -> bool:
	for external_id in GOOGLE_ACHIEVEMENT_IDS.values():
		if str(external_id).strip_edges().is_empty():
			return false
	return true
