extends Node
## Global economy, layers, and sample queue.

enum GameLayer {
	LAB,
	MICROSCOPY,
	PROBLEM_INSPECTION,
}

const MINIGAME_PROBLEM_CHANCE: float = 0.35

var game_layer: GameLayer = GameLayer.LAB
var player_money: int = 125680
var player_xp: int = 18450
var player_xp_to_next: int = 24000
var player_level: int = 12
var lab_reputation: float = 87.0
var customer_satisfaction: float = 100.0
var contamination_trend: float = 0.35
var escalation_risk: float = 0.45
var alert_count: int = 1
var samples_in_lab: int = 0
var max_samples_in_lab: int = 20
var game_day: int = 34
var game_minutes: int = 582
var pending_ftir_count: int = 0
var sample_queue: Array[Dictionary] = []

var device_levels: Dictionary = {
	"extraction": 3,
	"drying": 1,
	"microscope": 4,
	"storage": 2,
	"escalation": 2,
}

signal layer_changed(layer: GameLayer)
signal economy_changed
signal sample_queue_changed
signal problem_inspection_requested(part: Part, claims: Array)
signal problem_inspection_resolved(part: Part, approved: bool)
signal microscope_session_started(part: Part)
signal microscopy_results_applied(summary: Dictionary)
signal delivery_completed(payout: int)


func start_run() -> void:
	game_layer = GameLayer.LAB
	sample_queue.clear()
	samples_in_lab = 0
	player_money = 125680
	player_xp = 18450
	player_level = 12
	lab_reputation = 87.0
	game_day = 34
	game_minutes = 582
	layer_changed.emit(game_layer)
	economy_changed.emit()
	sample_queue_changed.emit()


func get_time_string() -> String:
	var h: int = game_minutes / 60
	var m: int = game_minutes % 60
	return "%02d:%02d" % [h, m]


func get_device_level(device_key: String) -> int:
	return int(device_levels.get(device_key, 1))


func process_time_for(device_key: String, base_seconds: float) -> float:
	var level: int = get_device_level(device_key)
	return maxf(base_seconds / (1.0 + (level - 1) * 0.18), 1.0)


func is_device_unlocked(device_key: String, required_level: int) -> bool:
	return get_device_level(device_key) >= required_level


func register_part_in_queue(part: Part) -> void:
	samples_in_lab += 1
	sample_queue.append({
		"name": part.order.order_id,
		"display_name": part.order.display_name,
		"stage": "Incoming",
		"next_step": part.next_station_name(),
		"payout": part.order.payout,
		"priority": _priority_for_payout(part.order.payout),
	})
	sample_queue_changed.emit()


func _priority_for_payout(payout: int) -> String:
	if payout >= 300:
		return "High"
	if payout >= 175:
		return "Medium"
	return "Low"


func update_queue_stage(part_id: String, stage: String) -> void:
	for entry in sample_queue:
		if entry.get("name", "") == part_id:
			entry["stage"] = stage
	sample_queue_changed.emit()


func update_queue_for_part(part: Part, stage: String) -> void:
	var part_id := part.order.order_id
	for entry in sample_queue:
		if entry.get("name", "") == part_id:
			entry["stage"] = stage
			entry["next_step"] = part.next_station_name()
	sample_queue_changed.emit()


func unregister_part(part_id: String) -> void:
	for i in sample_queue.size():
		if sample_queue[i].get("name", "") == part_id:
			sample_queue.remove_at(i)
			break
	samples_in_lab = maxi(samples_in_lab - 1, 0)
	sample_queue_changed.emit()


func start_microscope_session(part: Part) -> void:
	game_layer = GameLayer.MICROSCOPY
	layer_changed.emit(game_layer)
	microscope_session_started.emit(part)


func enter_problem_inspection(part: Part, claims: Array) -> void:
	if game_layer == GameLayer.PROBLEM_INSPECTION:
		return
	game_layer = GameLayer.PROBLEM_INSPECTION
	layer_changed.emit(game_layer)
	problem_inspection_requested.emit(part, claims)


func leave_problem_inspection() -> void:
	game_layer = GameLayer.LAB
	layer_changed.emit(game_layer)


func complete_delivery(payout: int) -> void:
	player_money += payout
	player_xp += payout / 5
	lab_reputation = clampf(lab_reputation + 1.5, 0.0, 100.0)
	game_minutes += 3
	economy_changed.emit()
	delivery_completed.emit(payout)


func apply_inspection_penalty() -> void:
	lab_reputation = clampf(lab_reputation - 5.0, 0.0, 100.0)
	alert_count += 1
	economy_changed.emit()


func apply_reputation_delta(delta: float) -> void:
	lab_reputation = clampf(lab_reputation + delta, 0.0, 100.0)
	economy_changed.emit()


func apply_microscopy_results(summary: Dictionary) -> void:
	var score: int = int(summary.get("score", 0))
	var accuracy: float = float(summary.get("accuracy", 0.0))
	var wrong: int = int(summary.get("wrong", 0))
	player_xp += score / 8 + int(accuracy * 20.0)
	player_money += score / 4
	lab_reputation = clampf(lab_reputation + (accuracy - 0.5) * 6.0 - wrong, 0.0, 100.0)
	game_layer = GameLayer.LAB
	layer_changed.emit(game_layer)
	economy_changed.emit()
	microscopy_results_applied.emit(summary)
