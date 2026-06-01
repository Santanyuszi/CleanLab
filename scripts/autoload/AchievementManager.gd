extends Node
## Local achievement progression. External services are mirrored through
## PlatformServices without making gameplay depend on platform availability.

enum Tier {
	LOCKED,
	BRONZE,
	SILVER,
	GOLD,
	CERTIFIED,
}

const TIER_KEYS := {
	Tier.BRONZE: "bronze",
	Tier.SILVER: "silver",
	Tier.GOLD: "gold",
	Tier.CERTIFIED: "certified",
}
const TIER_NAMES := {
	Tier.LOCKED: "Locked",
	Tier.BRONZE: "Bronze",
	Tier.SILVER: "Silver",
	Tier.GOLD: "Gold",
	Tier.CERTIFIED: "Certified",
}
const TIER_COLORS := {
	Tier.LOCKED: Color("#8FB1B4"),
	Tier.BRONZE: Color(0.72, 0.42, 0.2),
	Tier.SILVER: Color("#8FB1B4"),
	Tier.GOLD: Color(0.98, 0.72, 0.18),
	Tier.CERTIFIED: Color("#4CFFBD"),
}
const CATALOG: Array[Dictionary] = [
	{"id": "sample_handler", "name": "Sample Handler", "description": "Accept and process customer sample work.", "metric": "contracts_accepted", "thresholds": [1, 5, 15, 40], "icon": "package"},
	{"id": "extraction_specialist", "name": "Extraction Specialist", "description": "Complete extraction station work.", "metric": "extraction_completed", "thresholds": [2, 10, 35, 100], "icon": "filter"},
	{"id": "drying_specialist", "name": "Drying Specialist", "description": "Complete drying oven work.", "metric": "drying_completed", "thresholds": [2, 10, 35, 100], "icon": "temperature"},
	{"id": "microscope_operator", "name": "Microscope Operator", "description": "Complete microscope analysis work.", "metric": "microscope_completed", "thresholds": [2, 10, 35, 100], "icon": "microscope"},
	{"id": "particle_hunter", "name": "Particle Hunter", "description": "Find and classify particles.", "metric": "particles_classified", "thresholds": [2, 20, 75, 200], "icon": "search"},
	{"id": "metallic_expert", "name": "Metallic Expert", "description": "Correctly classify metallic particles.", "metric": "metallic_classified", "thresholds": [1, 8, 30, 90], "icon": "hexagon-3d"},
	{"id": "fiber_expert", "name": "Fiber Expert", "description": "Correctly classify fiber particles.", "metric": "fiber_classified", "thresholds": [1, 8, 30, 90], "icon": "scribble"},
	{"id": "non_metallic_expert", "name": "Non-Metallic Expert", "description": "Correctly classify non-metallic particles.", "metric": "non_metallic_classified", "thresholds": [1, 8, 30, 90], "icon": "atom-2"},
	{"id": "fast_analyst", "name": "Fast Analyst", "description": "Finish microscope sessions quickly.", "metric": "fast_microscopy", "thresholds": [1, 5, 15, 40], "icon": "stopwatch"},
	{"id": "accuracy_master", "name": "Accuracy Master", "description": "Finish microscope sessions perfectly.", "metric": "perfect_microscopy", "thresholds": [1, 5, 15, 40], "icon": "target-arrow"},
	{"id": "truck_dispatcher", "name": "Truck Dispatcher", "description": "Send completed reports by truck.", "metric": "truck_shipments", "thresholds": [1, 8, 25, 70], "icon": "truck-delivery"},
	{"id": "factory_flow", "name": "Factory Flow", "description": "Deliver completed cleanliness reports.", "metric": "reports_delivered", "thresholds": [2, 10, 35, 100], "icon": "building-factory"},
	{"id": "customer_satisfaction", "name": "Customer Satisfaction", "description": "Complete contracts without breaking trust.", "metric": "clean_delivery_streak", "thresholds": [2, 5, 12, 25], "icon": "mood-smile"},
	{"id": "reputation_builder", "name": "Reputation Builder", "description": "Reach strong customer reputation.", "metric": "reputation_reached", "thresholds": [65, 75, 88, 98], "icon": "rosette-discount-check"},
	{"id": "upgrade_engineer", "name": "Upgrade Engineer", "description": "Upgrade lab equipment.", "metric": "total_device_upgrades", "thresholds": [1, 4, 8, 14], "icon": "arrow-up-circle"},
	{"id": "automation_expert", "name": "Automation Expert", "description": "Bring equipment lines to maximum capability.", "metric": "maxed_devices", "thresholds": [1, 2, 3, 4], "icon": "robot"},
	{"id": "cleanroom_discipline", "name": "Cleanroom Discipline", "description": "Maintain cleanroom compliance and consistency.", "metric": "clean_delivery_streak", "thresholds": [3, 8, 18, 40], "icon": "shield-check"},
	{"id": "technical_cleanliness_master", "name": "Technical Cleanliness Master", "description": "Certify achievements across the lab.", "metric": "certified_achievements", "thresholds": [1, 4, 9, 17], "icon": "award"},
]

var _stats: Dictionary = {}
var _tiers: Dictionary = {}
var _unread_count: int = 0

signal achievement_updated(achievement_id: String, tier: int)
signal achievement_unlocked(achievement: Dictionary, tier: int)
signal unread_changed(count: int)


func _ready() -> void:
	reset()
	GameManager.contract_accepted.connect(_on_contract_accepted)
	GameManager.contract_cancelled.connect(_on_contract_cancelled)
	GameManager.delivery_reports_completed.connect(_on_delivery_reports_completed)
	GameManager.device_changed.connect(_on_device_changed)
	GameManager.station_completed.connect(_on_station_completed)
	GameManager.economy_changed.connect(_refresh_derived_progress)
	GameManager.microscopy_results_applied.connect(_on_microscopy_results_applied)


func reset() -> void:
	_stats = {
		"contracts_accepted": 0,
		"contracts_cancelled": 0,
		"reports_delivered": 0,
		"revenue_earned": 0,
		"profit_generated": 0,
		"contracts_completed": 0,
		"clean_delivery_streak": 0,
		"timed_offers_accepted": 0,
		"truck_shipments": 0,
		"perfect_microscopy": 0,
		"fast_microscopy": 0,
		"particles_classified": 0,
		"metallic_classified": 0,
		"fiber_classified": 0,
		"non_metallic_classified": 0,
		"extraction_completed": 0,
		"drying_completed": 0,
		"microscope_completed": 0,
		"highest_report_tier": 0,
	}
	_tiers.clear()
	for achievement in CATALOG:
		_tiers[str(achievement["id"])] = Tier.LOCKED
	_unread_count = 0
	unread_changed.emit(_unread_count)
	call_deferred("_refresh_derived_progress")


func get_catalog() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for achievement in CATALOG:
		var item := achievement.duplicate(true)
		var id := str(item["id"])
		item["tier"] = int(_tiers.get(id, Tier.LOCKED))
		item["progress"] = get_progress_value(item)
		item["next_threshold"] = get_next_threshold(item)
		item["progress_ratio"] = get_progress_ratio(item)
		output.append(item)
	return output


func get_unread_count() -> int:
	return _unread_count


func clear_unread() -> void:
	if _unread_count == 0:
		return
	_unread_count = 0
	unread_changed.emit(_unread_count)


func tier_name(tier: int) -> String:
	return str(TIER_NAMES.get(tier, "Locked"))


func tier_color(tier: int) -> Color:
	return TIER_COLORS.get(tier, TIER_COLORS[Tier.LOCKED])


func get_progress_value(achievement: Dictionary) -> int:
	var metric := str(achievement.get("metric", ""))
	match metric:
		"reputation_reached":
			return floori(GameManager.lab_reputation)
		"player_level":
			return GameManager.player_level
		"contract_tier":
			return GameManager.get_contract_tier()
		"truck_level":
			return GameManager.get_device_level("truck")
		"extraction_level":
			return GameManager.get_device_level("extraction")
		"drying_level":
			return GameManager.get_device_level("drying")
		"microscope_level":
			return GameManager.get_device_level("microscope")
		"total_device_upgrades":
			return _total_device_upgrades()
		"maxed_devices":
			return _maxed_device_count()
		"certified_achievements":
			return _certified_count(false)
	return int(_stats.get(metric, 0))


func get_next_threshold(achievement: Dictionary) -> int:
	var tier := int(_tiers.get(str(achievement.get("id", "")), Tier.LOCKED))
	var thresholds: Array = achievement.get("thresholds", [])
	if tier >= Tier.CERTIFIED or thresholds.is_empty():
		return int(thresholds.back()) if not thresholds.is_empty() else 0
	return int(thresholds[tier])


func get_progress_ratio(achievement: Dictionary) -> float:
	var threshold := get_next_threshold(achievement)
	if threshold <= 0:
		return 1.0
	return clampf(float(get_progress_value(achievement)) / float(threshold), 0.0, 1.0)


func _on_contract_accepted(_contract: Dictionary) -> void:
	_stats["contracts_accepted"] = int(_stats["contracts_accepted"]) + 1
	_stats["timed_offers_accepted"] = int(_stats["timed_offers_accepted"]) + 1
	_evaluate_all()


func _on_contract_cancelled(_order_id: String) -> void:
	_stats["contracts_cancelled"] = int(_stats["contracts_cancelled"]) + 1
	_stats["clean_delivery_streak"] = 0
	_evaluate_all()


func _on_delivery_reports_completed(payout: int, reports: Array) -> void:
	var delivered := reports.size()
	if delivered <= 0:
		return
	var cost := 0
	var highest_tier := int(_stats["highest_report_tier"])
	for report in reports:
		cost += int(report.get("manufacture_cost", 0))
		highest_tier = maxi(highest_tier, int(report.get("tier", 1)))
	_stats["reports_delivered"] = int(_stats["reports_delivered"]) + delivered
	_stats["contracts_completed"] = int(_stats["contracts_completed"]) + delivered
	_stats["revenue_earned"] = int(_stats["revenue_earned"]) + payout
	_stats["profit_generated"] = int(_stats["profit_generated"]) + maxi(payout - cost, 0)
	_stats["clean_delivery_streak"] = int(_stats["clean_delivery_streak"]) + delivered
	_stats["truck_shipments"] = int(_stats["truck_shipments"]) + 1
	_stats["highest_report_tier"] = highest_tier
	_evaluate_all()


func _on_device_changed(_device_key: String) -> void:
	_evaluate_all()


func _on_station_completed(device_key: String) -> void:
	match device_key:
		"extraction":
			_stats["extraction_completed"] = int(_stats["extraction_completed"]) + 1
		"drying":
			_stats["drying_completed"] = int(_stats["drying_completed"]) + 1
		"microscope":
			_stats["microscope_completed"] = int(_stats["microscope_completed"]) + 1
	_evaluate_all()


func _on_microscopy_results_applied(summary: Dictionary) -> void:
	var classified := int(summary.get("classified", 0))
	var accuracy := float(summary.get("accuracy", 0.0))
	var wrong := int(summary.get("wrong", 0))
	var avg_speed := float(summary.get("avg_speed", 99.0))
	var class_counts: Dictionary = summary.get("class_counts", {})
	_stats["particles_classified"] = int(_stats["particles_classified"]) + classified
	_stats["metallic_classified"] = int(_stats["metallic_classified"]) + int(class_counts.get("metallic", 0))
	_stats["fiber_classified"] = int(_stats["fiber_classified"]) + int(class_counts.get("fiber", 0))
	_stats["non_metallic_classified"] = int(_stats["non_metallic_classified"]) + int(class_counts.get("non_metallic", 0))
	if classified > 0 and wrong == 0 and accuracy >= 0.999:
		_stats["perfect_microscopy"] = int(_stats["perfect_microscopy"]) + 1
	if classified > 0 and avg_speed <= 1.6:
		_stats["fast_microscopy"] = int(_stats["fast_microscopy"]) + 1
	_evaluate_all()


func _refresh_derived_progress() -> void:
	_evaluate_all()


func _evaluate_all() -> void:
	var changed := false
	for achievement in CATALOG:
		if _evaluate(achievement):
			changed = true
	if changed:
		unread_changed.emit(_unread_count)


func _evaluate(achievement: Dictionary) -> bool:
	var id := str(achievement["id"])
	var current_tier := int(_tiers.get(id, Tier.LOCKED))
	var next_tier := _tier_for_progress(achievement, get_progress_value(achievement))
	if next_tier <= current_tier:
		return false
	_tiers[id] = next_tier
	_unread_count += 1
	achievement_updated.emit(id, next_tier)
	achievement_unlocked.emit(achievement.duplicate(true), next_tier)
	for tier in range(current_tier + 1, next_tier + 1):
		if TIER_KEYS.has(tier):
			PlatformServices.unlock_achievement(id, str(TIER_KEYS[tier]))
	return true


func _tier_for_progress(achievement: Dictionary, progress: int) -> int:
	var thresholds: Array = achievement.get("thresholds", [])
	var tier := Tier.LOCKED
	for i in thresholds.size():
		if progress >= int(thresholds[i]):
			tier = i + 1
	return tier


func _certified_count(include_master: bool) -> int:
	var count := 0
	for achievement in CATALOG:
		var id := str(achievement["id"])
		if not include_master and id == "technical_cleanliness_master":
			continue
		if int(_tiers.get(id, Tier.LOCKED)) >= Tier.CERTIFIED:
			count += 1
	return count


func _total_device_upgrades() -> int:
	var total := 0
	for key in ["extraction", "drying", "microscope", "truck"]:
		total += maxi(GameManager.get_device_level(key) - 1, 0)
	return total


func _maxed_device_count() -> int:
	var total := 0
	for key in ["extraction", "drying", "microscope", "truck"]:
		if GameManager.get_device_level(key) >= GameManager.get_device_max_level(key):
			total += 1
	return total
