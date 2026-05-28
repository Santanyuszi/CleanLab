class_name StationBase
extends Area2D
## Base processing station: deposit sample, timer runs, worker picks up result.

enum StationState {
	IDLE,
	READY_FOR_SAMPLE,
	PROCESSING,
	COMPLETE,
}

@export var station_name: String = "Station"
@export var station_type: String = "generic"
@export var processing_time: float = 3.0
@export var required_sample_state: Sample.ProcessingState = Sample.ProcessingState.ARRIVED
@export var output_sample_state: Sample.ProcessingState = Sample.ProcessingState.ARRIVED

var current_state: StationState = StationState.IDLE
var _process_timer: float = 0.0
var _current_sample: Sample = null

signal processing_started(sample: Sample)
signal processing_completed(sample: Sample)
signal sample_ready_for_pickup(sample: Sample)


@onready var _platform: ColorRect = $Platform
@onready var _title: Label = $Title
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var _slot: Marker2D = $SampleSlot


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("station")
	_title.text = station_name
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	_set_visual_state(StationState.IDLE)


func _process(delta: float) -> void:
	if current_state != StationState.PROCESSING:
		return
	_process_timer += delta
	var progress := clampf(_process_timer / processing_time, 0.0, 1.0)
	progress_bar.value = progress
	if _process_timer >= processing_time:
		_finish_processing()


func interact(worker: Worker) -> void:
	if global_position.distance_to(worker.global_position) > worker.interaction_range:
		worker.move_to(global_position)
		return
	if current_state == StationState.COMPLETE and _current_sample != null:
		_pick_up_for_worker(worker)
		return
	if worker.carried_sample != null:
		try_accept_from_worker(worker)


func try_accept_from_worker(worker: Worker) -> bool:
	if current_state != StationState.IDLE and current_state != StationState.READY_FOR_SAMPLE:
		return false
	var sample := worker.carried_sample
	if sample == null:
		return false
	if sample.processing_state != required_sample_state:
		return false
	if global_position.distance_to(worker.global_position) > worker.interaction_range:
		worker.move_to(global_position)
		return false
	worker.detach_sample()
	accept_sample(sample)
	return true


func accept_sample(sample: Sample) -> void:
	_current_sample = sample
	sample.global_position = _slot.global_position
	sample.set_collision_layer_value(3, false)
	sample.set_collision_mask_value(2, false)
	sample.set_processing_state(_state_for_processing())
	current_state = StationState.PROCESSING
	_process_timer = 0.0
	progress_bar.value = 0.0
	_set_visual_state(StationState.PROCESSING)
	processing_started.emit(sample)
	GameManager.notify_station_processing_started(station_type)


func _finish_processing() -> void:
	if _current_sample:
		_current_sample.set_processing_state(output_sample_state)
		_current_sample.contamination_level = maxf(
			_current_sample.contamination_level - 0.2, 0.05
		)
	current_state = StationState.COMPLETE
	_set_visual_state(StationState.COMPLETE)
	processing_completed.emit(_current_sample)
	sample_ready_for_pickup.emit(_current_sample)
	GameManager.notify_station_processing_complete(station_type)


func _pick_up_for_worker(worker: Worker) -> void:
	if worker.carried_sample != null:
		return
	_current_sample.release(_slot.global_position)
	worker.attach_sample(_current_sample)
	_current_sample = null
	current_state = StationState.IDLE
	progress_bar.value = 0.0
	_set_visual_state(StationState.IDLE)


func _state_for_processing() -> Sample.ProcessingState:
	match station_type:
		"washing":
			return Sample.ProcessingState.WASHING
		"drying":
			return Sample.ProcessingState.DRYING
		_:
			return Sample.ProcessingState.ARRIVED


func _set_visual_state(state: StationState) -> void:
	var base := Color(0.18, 0.22, 0.28)
	match state:
		StationState.IDLE, StationState.READY_FOR_SAMPLE:
			base = Color(0.18, 0.22, 0.28)
		StationState.PROCESSING:
			base = Color(0.15, 0.45, 0.65)
		StationState.COMPLETE:
			base = Color(0.2, 0.55, 0.35)
	_platform.color = base
