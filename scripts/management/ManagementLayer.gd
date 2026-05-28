class_name ManagementLayer
extends Node
## Calm strategic layer: intake, automated prep, escalations (future). Feeds microscopy.

@export var sample_scene: PackedScene
@export var spawn_delay: float = 0.5

@onready var _spawn_point: Marker2D = %SpawnPoint
@onready var _incoming: IncomingDock = %IncomingDock
@onready var _pipeline: SamplePipeline = %SamplePipeline
@onready var _wash: StationBase = %WashingStation
@onready var _dry: StationBase = %DryingStation
@onready var _microscope: MicroscopeStation = %MicroscopeStation
@onready var _hud: GameHUD = %GameHUD


func _ready() -> void:
	_pipeline.setup(_wash, _dry, _microscope)
	_pipeline.pipeline_started.connect(_on_pipeline_started)
	GameManager.microscopy_results_applied.connect(_on_microscopy_results_applied)
	GameManager.start_prototype_run()
	await get_tree().create_timer(spawn_delay).timeout
	_spawn_incoming_sample()


func get_incoming_dock() -> IncomingDock:
	return _incoming


func get_pipeline() -> SamplePipeline:
	return _pipeline


func _spawn_incoming_sample() -> void:
	var sample: Sample = sample_scene.instantiate()
	sample.global_position = _spawn_point.global_position
	get_parent().add_child(sample)
	_incoming.set_pending_sample(sample)
	GameManager.register_incoming_sample(sample)
	_hud.set_phase_hint("Tap operator, then Incoming to start automated prep.")


func _on_pipeline_started(_sample: Sample) -> void:
	_hud.set_phase_hint("Prep running automatically… microscope challenge incoming.")


func _on_microscopy_results_applied(_summary: Dictionary) -> void:
	await get_tree().create_timer(1.2).timeout
	_spawn_incoming_sample()
