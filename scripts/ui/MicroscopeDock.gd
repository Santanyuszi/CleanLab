class_name MicroscopeDock
extends PanelContainer
## Bottom-center microscopy panel — visible only during inspection (not on main lab idle).

@export var particle_scene: PackedScene

@onready var _timer: Label = %TimerLabel
@onready var _combo: Label = %ComboLabel
@onready var _score: Label = %ScoreLabel
@onready var _accuracy: Label = %AccuracyLabel
@onready var _particle_field: Control = %ParticleField
@onready var _prompt: Label = %PromptLabel

var _active: bool = false
var _time_left: float = 0.0
var _score_val: int = 0
var _combo_val: float = 1.0
var _correct: int = 0
var _wrong: int = 0
var _total: int = 0
var _particles: Array[ParticleSpot] = []
var _selected: ParticleSpot = null
var _linked_part: Part = null


func _ready() -> void:
	visible = false
	GameManager.microscope_session_started.connect(_on_session_started)
	for i in 5:
		var btn := find_child("ClassBtn%d" % i, true, false) as Button
		if btn == null:
			continue
		btn.pressed.connect(_on_class_pressed.bind(i))
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 14)


func set_active(on: bool) -> void:
	if not on:
		_active = false
		_clear_particles()


func _on_session_started(part: Part) -> void:
	_linked_part = part
	_active = true
	_time_left = 15.0
	_score_val = 0
	_combo_val = 1.0
	_correct = 0
	_wrong = 0
	_total = randi_range(1, 2)
	_selected = null
	_clear_particles()
	call_deferred("_deferred_spawn_particles")
	_prompt.text = "Tap particle, then classify"
	_refresh_stats()


func _deferred_spawn_particles() -> void:
	_spawn_particles()


func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	var seconds_left := int(_time_left)
	_timer.text = "%02d:%02d" % [floori(seconds_left / 60.0), seconds_left % 60]
	if _time_left <= 0.0:
		_finish()


func _spawn_particles() -> void:
	var size := _particle_field.size
	if size.x < 50.0:
		size = Vector2(520, 140)
	for i in _total:
		var spot: ParticleSpot = particle_scene.instantiate()
		_particle_field.add_child(spot)
		var p_class: ParticleTypes.Class = randi() % 5 as ParticleTypes.Class
		spot.setup(p_class, Vector2(randf_range(40, size.x - 40), randf_range(30, size.y - 30)))
		spot.tapped.connect(_on_particle_tapped)
		_particles.append(spot)


func _on_particle_tapped(spot: ParticleSpot) -> void:
	if _selected:
		_selected.set_selected(false)
	_selected = spot
	_selected.set_selected(true)


func _on_class_pressed(class_id: int) -> void:
	if not _active or _selected == null:
		return
	var chosen: ParticleTypes.Class = class_id as ParticleTypes.Class
	var ok: bool = _selected.true_class == chosen
	if ok:
		_correct += 1
		_score_val += int(80 * _combo_val)
		_combo_val = minf(_combo_val + 0.12, 3.5)
	else:
		_wrong += 1
		_combo_val = 1.0
	_selected.mark_classified()
	_selected = null
	_refresh_stats()
	if _correct + _wrong >= _total:
		_finish()


func _finish() -> void:
	_active = false
	var accuracy: float = float(_correct) / float(maxi(_total, 1))
	var summary: Dictionary = {
		"score": _score_val,
		"accuracy": accuracy,
		"avg_speed": 1.5,
		"ftir_flags": 0,
		"wrong": _wrong,
		"classified": _correct,
	}
	GameManager.apply_microscopy_results(summary)
	var microscope: WorkStation = null
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.station_kind == WorkStation.Kind.MICROSCOPE:
			microscope = s
	if microscope:
		microscope.resume_after_inspection(true)
	_clear_particles()


func _refresh_stats() -> void:
	_score.text = "Score: %d" % _score_val
	_combo.text = "Combo: x%.1f" % _combo_val
	var acc: float = float(_correct) / float(maxi(_correct + _wrong, 1)) * 100.0
	_accuracy.text = "Accuracy: %.0f%%" % acc


func _clear_particles() -> void:
	for p in _particles:
		if is_instance_valid(p):
			p.queue_free()
	_particles.clear()
