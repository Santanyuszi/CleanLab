class_name SamplePipeline
extends Node
## Semi-automatic lab prep: wash → dry → microscope. Player focuses on routing + microscopy.

signal pipeline_started(sample: Sample)
signal pipeline_finished(sample: Sample)

@export var move_duration: float = 0.45

var _running: bool = false
var _wash: StationBase
var _dry: StationBase
var _microscope: MicroscopeStation


func setup(wash: StationBase, dry: StationBase, microscope: MicroscopeStation) -> void:
	_wash = wash
	_dry = dry
	_microscope = microscope


func start(sample: Sample) -> void:
	if _running or sample == null:
		return
	_running = true
	pipeline_started.emit(sample)
	GameManager.set_management_phase(GameManager.ManagementPhase.PIPELINE_ACTIVE)
	await _run_chain(sample)
	_running = false
	pipeline_finished.emit(sample)


func _run_chain(sample: Sample) -> void:
	await _tween_sample_to(sample, _wash)
	await _await_station(_wash, sample)
	await _tween_sample_to(sample, _dry)
	await _await_station(_dry, sample)
	await _tween_sample_to(sample, _microscope)
	await _await_station(_microscope, sample)


func _tween_sample_to(sample: Sample, station: StationBase) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sample, "global_position", station.global_position, move_duration)
	await tween.finished


func _await_station(station: StationBase, sample: Sample) -> void:
	if sample.processing_state != station.required_sample_state:
		sample.set_processing_state(station.required_sample_state)
	station.accept_sample(sample)
	await station.processing_completed
