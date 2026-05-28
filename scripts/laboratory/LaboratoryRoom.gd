extends Node2D
## Single-room prototype: spawns one sample and wires stations + worker.

@export var sample_scene: PackedScene
@export var spawn_delay: float = 0.5

@onready var _spawn_point: Marker2D = $SpawnPoint
@onready var _worker: Worker = $Worker
@onready var _washing: StationBase = $Stations/WashingStation
@onready var _drying: StationBase = $Stations/DryingStation
@onready var _microscope: MicroscopeStation = $Stations/MicroscopeStation
@onready var _hud: Control = $UI/GameHUD


func _ready() -> void:
	GameManager.start_prototype_run()
	await get_tree().create_timer(spawn_delay).timeout
	_spawn_sample()
	_hud.set_phase_hint("Sample arrived. Click the sample, then deliver to Washing.")


func _spawn_sample() -> void:
	var sample: Sample = sample_scene.instantiate()
	sample.global_position = _spawn_point.global_position
	add_child(sample)
	GameManager.register_sample(sample)
	sample.picked_up.connect(_on_sample_picked_up)


func _on_sample_picked_up(_by: Worker) -> void:
	_hud.set_phase_hint("Deliver sample to Washing station (click station).")
