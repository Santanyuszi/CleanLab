class_name WorkStation
extends Area2D
## Station: tap sample here, wait for timer, tap finished part to advance.

enum Kind {
	EXTRACTION,
	DRYING,
	MICROSCOPE,
	TRUCK,
}

enum SlotState {
	EMPTY,
	PROCESSING,
	AWAITING_INSPECTION,
	READY,
}

@export var station_kind: Kind = Kind.EXTRACTION
@export var station_title: String = "Station"
@export var device_key: String = "extraction"
@export var base_process_seconds: float = 4.0
@export var min_device_level: int = 1

var slot_state: SlotState = SlotState.EMPTY
var held_part: Part = null
var held_parts: Array[Part] = []
var _part_states: Dictionary = {}
var _part_timers: Dictionary = {}
var _part_durations: Dictionary = {}
var _timer: float = 0.0
var _process_duration: float = 1.0

signal part_ready(station: WorkStation)
signal processing_finished(station: WorkStation)
signal status_changed(device_key: String, status: String, progress: float, time_left: float)


@onready var _platform: ColorRect = $Platform
@onready var _title: Label = $Title
@onready var _status: Label = $Status
@onready var _progress: ProgressBar = $ProgressBar
@onready var _slot: Marker2D = $Slot
@onready var _device_art: DeviceArtwork = $DeviceArtwork


func _ready() -> void:
	add_to_group("work_station")
	_title.text = station_title
	_progress.max_value = 1.0
	_refresh_device_art()
	GameManager.device_changed.connect(_on_device_changed)
	if station_kind == Kind.TRUCK:
		_set_status("Reports Out")
	else:
		_set_status("Tap to start")
	_emit_status()


func get_slot_global_position() -> Vector2:
	return _slot.global_position


func get_slot_global_position_for_index(index: int) -> Vector2:
	var column := index % 3
	var row := int(index / 3)
	return _slot.global_position + Vector2((column - 1) * 42.0, row * 34.0)


func contains_point(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= 90.0


func is_unlocked() -> bool:
	return GameManager.is_device_unlocked(device_key, min_device_level)


func _on_device_changed(changed_key: String) -> void:
	if changed_key == device_key:
		_refresh_device_art()
		_emit_status()


func _refresh_device_art() -> void:
	if _device_art == null:
		return
	_device_art.device_key = device_key
	_device_art.device_level = GameManager.get_device_level(device_key)
	_device_art.owned = GameManager.is_device_owned(device_key) or station_kind == Kind.TRUCK


func can_accept_part(part: Part) -> bool:
	if not is_unlocked():
		return false
	if station_kind == Kind.TRUCK:
		return false
	if held_parts.size() >= GameManager.get_station_capacity(device_key):
		return false
	return part.can_enter_station(station_kind)


func try_accept_part(part: Part) -> bool:
	if not can_accept_part(part):
		return false
	var slot_index := held_parts.size()
	held_parts.append(part)
	held_part = held_parts[0]
	part.is_on_station = true
	part.global_position = get_slot_global_position_for_index(slot_index)
	var duration := GameManager.process_time_for(device_key, base_process_seconds)
	_part_states[part.order.order_id] = SlotState.PROCESSING
	_part_timers[part.order.order_id] = duration
	_part_durations[part.order.order_id] = duration
	_refresh_aggregate_state()
	_progress.value = 0.0
	_set_status("Processing...")
	_set_platform_color(Color(0.12, 0.42, 0.62))
	_emit_status()
	if held_part:
		GameManager.update_queue_stage(held_part.order.order_id, station_title)
	return true


func can_pick_up() -> bool:
	return _first_ready_part() != null


func get_ready_part_at(world: Vector2) -> Part:
	for part in held_parts:
		if part == null:
			continue
		if _state_for(part) == SlotState.READY and part.global_position.distance_to(world) < 62.0:
			return part
	return null


func pick_up() -> Part:
	if not can_pick_up():
		return null
	var part := _first_ready_part()
	_remove_part(part)
	part.is_on_station = false
	_progress.value = 0.0
	_set_status("Tap to start" if held_parts.is_empty() else "Processing...")
	_set_platform_color(Color(0.18, 0.22, 0.28))
	_emit_status()
	return part


func remove_order(order_id: String) -> bool:
	for part in held_parts:
		if part != null and part.order != null and part.order.order_id == order_id:
			_remove_part(part)
			part.queue_free()
			_progress.value = 0.0
			_set_status("Tap to start" if held_parts.is_empty() else "Processing...")
			_set_platform_color(Color(0.18, 0.22, 0.28))
			_emit_status()
			return true
	return false


func try_deliver_report(part: Part) -> bool:
	if station_kind != Kind.TRUCK:
		return false
	if part.current_step != Part.Step.REPORT_READY:
		return false
	var payout: int = part.order.payout
	_set_status("Departing...")
	_set_platform_color(Color(0.2, 0.55, 0.35))
	GameManager.unregister_part(part.order.order_id)
	GameManager.complete_delivery(payout)
	part.queue_free()
	_set_status("Reports Out")
	_set_platform_color(Color(0.16, 0.2, 0.26))
	return true


func resume_after_inspection(passed: bool) -> void:
	if slot_state != SlotState.AWAITING_INSPECTION or held_part == null:
		return
	var inspected_part := held_part
	if not passed:
		GameManager.apply_inspection_penalty()
		_part_timers[inspected_part.order.order_id] = float(_part_durations.get(inspected_part.order.order_id, _process_duration)) * 0.5
		_part_states[inspected_part.order.order_id] = SlotState.PROCESSING
		_refresh_aggregate_state()
		_set_status("Re-analysis...")
		return
	_finish_microscope_part(inspected_part)
	part_ready.emit(self)


func _process(delta: float) -> void:
	var processing: Array[Part] = []
	for part in held_parts:
		if _state_for(part) == SlotState.PROCESSING:
			processing.append(part)
	if processing.is_empty():
		_refresh_aggregate_state()
		return
	for part in processing:
		var id := part.order.order_id
		_part_timers[id] = float(_part_timers.get(id, 0.0)) - delta
		if float(_part_timers[id]) <= 0.0:
			_on_timer_finished(part)
	_refresh_aggregate_state()
	_emit_status()


func _on_timer_finished(part: Part) -> void:
	if part == null:
		return
	if station_kind == Kind.MICROSCOPE:
		if randf() < GameManager.MINIGAME_PROBLEM_CHANCE:
			_part_states[part.order.order_id] = SlotState.AWAITING_INSPECTION
			held_part = part
			_refresh_aggregate_state()
			_set_status("Revision")
			_set_platform_color(Color(0.62, 0.28, 0.55))
			_emit_status()
			var claims: Array = _build_inspection_claims()
			GameManager.enter_problem_inspection(part, claims)
			return
		_finish_microscope_part(part)
		return
	part.advance_step_after_station(station_kind)
	_part_states[part.order.order_id] = SlotState.READY
	_set_status("Tap part")
	_set_platform_color(Color(0.18, 0.58, 0.38))
	_emit_status()
	processing_finished.emit(self)
	part_ready.emit(self)


func _build_inspection_claims() -> Array:
	var true_class: int = randi() % 4
	var displayed: int = true_class if randf() > 0.4 else (randi() % 4)
	return [{"true_class": true_class, "displayed_class": displayed}]


func _set_status(text: String) -> void:
	_status.text = text


func _set_platform_color(c: Color) -> void:
	_platform.color = c


func get_ui_status() -> String:
	match slot_state:
		SlotState.EMPTY:
			return "Idle"
		SlotState.PROCESSING:
			return "Processing"
		SlotState.AWAITING_INSPECTION:
			return "Inspection"
		SlotState.READY:
			return "Ready"
	return "Idle"


func get_ui_progress() -> float:
	var processing := _first_part_with_state(SlotState.PROCESSING)
	if processing:
		var id := processing.order.order_id
		var duration := float(_part_durations.get(id, 1.0))
		return 1.0 - clampf(float(_part_timers.get(id, 0.0)) / duration, 0.0, 1.0)
	if slot_state == SlotState.READY:
		return 1.0
	return 0.0


func get_ui_time_left() -> float:
	var processing := _first_part_with_state(SlotState.PROCESSING)
	if processing:
		return float(_part_timers.get(processing.order.order_id, 0.0))
	return 0.0


func _emit_status() -> void:
	status_changed.emit(device_key, get_ui_status(), get_ui_progress(), get_ui_time_left())


func _finish_microscope_part(part: Part) -> void:
	part.set_report_ready()
	if GameManager.stage_report_for_shipping(part):
		_remove_part(part)
		part.queue_free()
		_set_status("Report staged")
		_set_platform_color(Color(0.18, 0.58, 0.38))
	else:
		_part_states[part.order.order_id] = SlotState.READY
		GameManager.update_queue_stage(part.order.order_id, "Truck full")
		_set_status("Truck full")
		_set_platform_color(Color(0.62, 0.28, 0.2))
	_emit_status()
	processing_finished.emit(self)
	part_ready.emit(self)


func _first_ready_part() -> Part:
	return _first_part_with_state(SlotState.READY)


func _first_part_with_state(target_state: SlotState) -> Part:
	for part in held_parts:
		if _state_for(part) == target_state:
			return part
	return null


func _state_for(part: Part) -> SlotState:
	return int(_part_states.get(part.order.order_id, SlotState.EMPTY))


func _remove_part(part: Part) -> void:
	if part == null:
		return
	held_parts.erase(part)
	_part_states.erase(part.order.order_id)
	_part_timers.erase(part.order.order_id)
	_part_durations.erase(part.order.order_id)
	held_part = held_parts[0] if not held_parts.is_empty() else null
	_refresh_slot_positions()
	_refresh_aggregate_state()


func _refresh_slot_positions() -> void:
	for i in held_parts.size():
		var part := held_parts[i]
		if part:
			part.global_position = get_slot_global_position_for_index(i)


func _refresh_aggregate_state() -> void:
	if held_parts.is_empty():
		slot_state = SlotState.EMPTY
		held_part = null
		return
	var revision := _first_part_with_state(SlotState.AWAITING_INSPECTION)
	if revision:
		slot_state = SlotState.AWAITING_INSPECTION
		held_part = revision
		return
	var ready := _first_ready_part()
	if ready:
		slot_state = SlotState.READY
		held_part = ready
		return
	slot_state = SlotState.PROCESSING
	held_part = held_parts[0]
