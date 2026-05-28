class_name IncomingDock
extends Area2D
## Customer sample intake — one tap (with operator) starts automated prep.

@export var dock_name: String = "Incoming"

var pending_sample: Sample = null

@onready var _platform: ColorRect = $Platform
@onready var _title: Label = $Title


func _ready() -> void:
	add_to_group("incoming_dock")
	_title.text = dock_name


func contains_world_point(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= 72.0


func set_pending_sample(sample: Sample) -> void:
	pending_sample = sample
	_platform.color = Color(0.85, 0.45, 0.2, 0.35)


func clear_pending() -> void:
	pending_sample = null
	_platform.color = Color(0.2, 0.28, 0.38)


func try_accept(worker: Worker, pipeline: SamplePipeline) -> bool:
	if pending_sample == null or pipeline == null:
		return false
	if not worker.is_selected:
		return false
	var sample := pending_sample
	clear_pending()
	worker.deselect()
	pipeline.start(sample)
	TouchInput.vibrate_feedback(30)
	return true
