class_name Sample
extends Area2D
## Physical sample in the lab. Carried by the worker between stations.

enum ProcessingState {
	ARRIVED,
	WASHING,
	WASHED,
	DRYING,
	DRIED,
	INSPECTING,
	COMPLETE,
}

@export var contamination_level: float = 0.75
@export var sample_id: String = "SMP-001"

var processing_state: ProcessingState = ProcessingState.ARRIVED
var is_carried: bool = false

signal state_changed(new_state: ProcessingState)
signal picked_up(by: Worker)
signal dropped(at: Vector2)


@onready var _visual: ColorRect = $Visual
@onready var _label: Label = $Label


func _ready() -> void:
	add_to_group("interactable")
	_update_visual()
	_label.text = sample_id


func set_processing_state(state: ProcessingState) -> void:
	processing_state = state
	state_changed.emit(state)
	_update_visual()


func interact(worker: Worker) -> void:
	if is_carried:
		return
	if worker.carried_sample != null:
		return
	if global_position.distance_to(worker.global_position) > worker.interaction_range:
		worker.move_to(global_position)
		return
	_pick_up(worker)


func _pick_up(worker: Worker) -> void:
	is_carried = true
	worker.attach_sample(self)
	picked_up.emit(worker)
	set_collision_layer_value(3, false)
	set_collision_mask_value(2, false)


func release(at_position: Vector2) -> void:
	is_carried = false
	global_position = at_position
	set_collision_layer_value(3, true)
	set_collision_mask_value(2, true)
	dropped.emit(at_position)
	_update_visual()


func _update_visual() -> void:
	var base := Color(0.35, 0.75, 0.95)
	match processing_state:
		ProcessingState.ARRIVED:
			base = Color(0.9, 0.45, 0.2)
		ProcessingState.WASHING, ProcessingState.WASHED:
			base = Color(0.3, 0.85, 0.95)
		ProcessingState.DRYING, ProcessingState.DRIED:
			base = Color(0.95, 0.85, 0.35)
		ProcessingState.INSPECTING:
			base = Color(0.75, 0.45, 0.95)
		ProcessingState.COMPLETE:
			base = Color(0.35, 0.95, 0.55)
	_visual.color = base.lerp(Color(0.15, 0.15, 0.2), contamination_level * 0.35)
