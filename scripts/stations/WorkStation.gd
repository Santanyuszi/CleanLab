class_name WorkStation
extends Area2D
## Kitchen-style station: drop part → timer → tap to collect → drag onward.

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


func _ready() -> void:
	add_to_group("work_station")
	_title.text = station_title
	_progress.max_value = 1.0
	if station_kind == Kind.TRUCK:
		_set_status("Deliver report here")
	else:
		_set_status("Drop part here")
	_emit_status()


func get_slot_global_position() -> Vector2:
	return _slot.global_position


func contains_point(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= 90.0


func is_unlocked() -> bool:
	return GameManager.is_device_unlocked(device_key, min_device_level)


func can_accept_part(part: Part) -> bool:
	if not is_unlocked():
		return false
	if station_kind == Kind.TRUCK:
		return false
	if slot_state != SlotState.EMPTY:
		return false
	return part.can_enter_station(station_kind)


func try_accept_part(part: Part) -> bool:
	if not can_accept_part(part):
		return false
	held_part = part
	part.attach_to_station(self)
	slot_state = SlotState.PROCESSING
	_process_duration = GameManager.process_time_for(device_key, base_process_seconds)
	_timer = _process_duration
	_progress.value = 0.0
	_set_status("Processing…")
	_set_platform_color(Color(0.12, 0.42, 0.62))
	_emit_status()
	if held_part:
		GameManager.update_queue_stage(held_part.order.order_id, station_title)
	return true


func can_pick_up() -> bool:
	return slot_state == SlotState.READY and held_part != null


func pick_up() -> Part:
	if not can_pick_up():
		return null
	var part: Part = held_part
	held_part = null
	slot_state = SlotState.EMPTY
	part.is_on_station = false
	_progress.value = 0.0
	_set_status("Drop part here")
	_set_platform_color(Color(0.18, 0.22, 0.28))
	_emit_status()
	return part


func try_deliver_report(part: Part) -> bool:
	if station_kind != Kind.TRUCK:
		return false
	if part.current_step != Part.Step.REPORT_READY:
		return false
	var payout: int = part.order.payout
	_set_status("Departing…")
	_set_platform_color(Color(0.2, 0.55, 0.35))
	GameManager.unregister_part(part.order.order_id)
	GameManager.complete_delivery(payout)
	part.queue_free()
	_set_status("Awaiting report")
	_set_platform_color(Color(0.16, 0.2, 0.26))
	return true


func resume_after_inspection(passed: bool) -> void:
	if slot_state != SlotState.AWAITING_INSPECTION or held_part == null:
		return
	if not passed:
		GameManager.apply_inspection_penalty()
		_timer = _process_duration * 0.5
		slot_state = SlotState.PROCESSING
		_set_status("Re-analysis…")
		return
	held_part.set_report_ready()
	slot_state = SlotState.READY
	_set_status("Tap to collect report")
	_set_platform_color(Color(0.18, 0.58, 0.38))
	part_ready.emit(self)


func _process(delta: float) -> void:
	if slot_state != SlotState.PROCESSING:
		return
	_timer -= delta
	_progress.value = 1.0 - clampf(_timer / _process_duration, 0.0, 1.0)
	_emit_status()
	if _timer <= 0.0:
		_on_timer_finished()


func _on_timer_finished() -> void:
	if held_part == null:
		return
	if station_kind == Kind.MICROSCOPE:
		if randf() < GameManager.MINIGAME_PROBLEM_CHANCE:
			slot_state = SlotState.AWAITING_INSPECTION
			_set_status("QC problem!")
			_set_platform_color(Color(0.62, 0.28, 0.55))
			_emit_status()
			var claims: Array = _build_inspection_claims()
			GameManager.enter_problem_inspection(held_part, claims)
			return
		slot_state = SlotState.AWAITING_INSPECTION
		_set_status("Inspection…")
		_emit_status()
		GameManager.start_microscope_session(held_part)
		return
	held_part.advance_step_after_station(station_kind)
	slot_state = SlotState.READY
	_set_status("Tap to collect")
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
	if slot_state == SlotState.PROCESSING:
		return 1.0 - clampf(_timer / _process_duration, 0.0, 1.0)
	if slot_state == SlotState.READY:
		return 1.0
	return 0.0


func get_ui_time_left() -> float:
	if slot_state == SlotState.PROCESSING:
		return _timer
	return 0.0


func _emit_status() -> void:
	status_changed.emit(device_key, get_ui_status(), get_ui_progress(), get_ui_time_left())
