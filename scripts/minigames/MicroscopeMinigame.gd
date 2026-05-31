extends CanvasLayer
## Signature gameplay: tap particles on the filter, classify fast under pressure.

const SESSION_DURATION: float = 15.0
const BASE_SCORE: int = 80
const COMBO_STEP: float = 0.12
const SPEED_BONUS_THRESHOLD: float = 2.0
const SPEED_BONUS_MULT: float = 1.35
const WRONG_REPUTATION: float = -3.0
const CORRECT_REPUTATION: float = 0.6
const SWIPE_MIN_DISTANCE: float = 80.0

@export var min_particles_per_session: int = 1
@export var max_particles_per_session: int = 2
@export var particle_scene: PackedScene

@onready var _particle_field: Control = $Root/Content/ParticleField
@onready var _filter_bg: ColorRect = $Root/Content/ParticleField/FilterBackground
@onready var _timer_label: Label = $Root/TopBar/Margin/HBox/TimerLabel
@onready var _score_label: Label = $Root/TopBar/Margin/HBox/ScoreLabel
@onready var _combo_label: Label = $Root/TopBar/Margin/HBox/ComboLabel
@onready var _prompt_label: Label = $Root/Content/PromptLabel
@onready var _results_panel: PanelContainer = $Root/ResultsPanel
@onready var _results_label: Label = $Root/ResultsPanel/Margin/ResultsLabel
@onready var _class_buttons: Array[Button] = []

var _active: bool = false
var _time_left: float = 0.0
var _score: int = 0
var _combo: float = 1.0
var _particles: Array[ParticleSpot] = []
var _selected: ParticleSpot = null
var _classified_count: int = 0
var _correct_count: int = 0
var _wrong_count: int = 0
var _ftir_flags: int = 0
var _class_counts: Dictionary = {}
var _speed_samples: Array[float] = []
var _swipe_start: Vector2 = Vector2.ZERO
var _swipe_tracking: bool = false
var _linked_sample: Sample = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_results_panel.visible = false
	if GameManager.has_signal("microscope_minigame_requested"):
		GameManager.connect("microscope_minigame_requested", _on_minigame_requested)
	_cache_buttons()
	_apply_touch_sizes()


func _cache_buttons() -> void:
	var bar: VBoxContainer = $Root/BottomBar/Margin/HBox
	for row in bar.get_children():
		for child in row.get_children():
			if child is Button:
				_class_buttons.append(child)


func _apply_touch_sizes() -> void:
	for btn in _class_buttons:
		btn.custom_minimum_size = Vector2(0, TouchInput.MIN_TOUCH_TARGET_PX)


func _input(event: InputEvent) -> void:
	if not _active or _selected == null:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start = event.position
			_swipe_tracking = true
		elif _swipe_tracking:
			_try_swipe_classify(event.position)
			_swipe_tracking = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_swipe_start = event.position
			_swipe_tracking = true
		elif _swipe_tracking:
			_try_swipe_classify(event.position)
			_swipe_tracking = false


func _try_swipe_classify(end_pos: Vector2) -> void:
	var delta := end_pos - _swipe_start
	if delta.length() < SWIPE_MIN_DISTANCE:
		return
	var chosen: ParticleTypes.Class
	if absf(delta.y) >= absf(delta.x):
		chosen = ParticleTypes.Class.METALLIC if delta.y < 0.0 else ParticleTypes.Class.IGNORE
	else:
		chosen = ParticleTypes.Class.FIBER if delta.x < 0.0 else ParticleTypes.Class.NON_METALLIC
	_submit_classification(chosen)


func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	_timer_label.text = "%.0fs" % maxf(_time_left, 0.0)
	if _time_left <= 0.0:
		_finish_session()


func _on_minigame_requested(sample: Sample) -> void:
	_linked_sample = sample
	_start_session()


func _start_session() -> void:
	await _start_session_async()


func _start_session_async() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_results_panel.visible = false
	_active = true
	_time_left = SESSION_DURATION
	_score = 0
	_combo = 1.0
	_classified_count = 0
	_correct_count = 0
	_wrong_count = 0
	_ftir_flags = 0
	_class_counts = {
		"metallic": 0,
		"fiber": 0,
		"non_metallic": 0,
	}
	_speed_samples.clear()
	_selected = null
	_clear_particles()
	await get_tree().process_frame
	_spawn_particles()
	_update_hud()
	_prompt_label.text = "Tap a particle, then classify"


func _spawn_particles() -> void:
	var field_size := _particle_field.size
	if field_size.x < 10.0:
		field_size = Vector2(900, 360)
	var margin := 40.0
	var particle_count := randi_range(min_particles_per_session, max_particles_per_session)
	for i in particle_count:
		var spot: ParticleSpot = particle_scene.instantiate()
		_particle_field.add_child(spot)
		var p_class := randi() % 5 as ParticleTypes.Class
		var local_pos := Vector2(
			randf_range(margin, field_size.x - margin),
			randf_range(margin, field_size.y - margin)
		)
		spot.setup(p_class, local_pos)
		spot.tapped.connect(_on_particle_tapped)
		_particles.append(spot)


func _on_particle_tapped(spot: ParticleSpot) -> void:
	if not _active or spot.is_classified:
		return
	if _selected != null:
		_selected.set_selected(false)
	_selected = spot
	_selected.set_selected(true)
	_prompt_label.text = "Classify this particle"
	TouchInput.vibrate_feedback(15)


func _on_class_pressed(class_id: int) -> void:
	_submit_classification(class_id as ParticleTypes.Class)


func _submit_classification(chosen: ParticleTypes.Class) -> void:
	if not _active or _selected == null:
		_prompt_label.text = "Tap a particle first"
		return
	var spot := _selected
	var correct := spot.true_class == chosen
	var reaction := spot.reaction_time()
	_speed_samples.append(reaction)

	if correct:
		_correct_count += 1
		_track_correct_class(chosen)
		var gained := int(BASE_SCORE * _combo)
		if reaction <= SPEED_BONUS_THRESHOLD:
			gained = int(gained * SPEED_BONUS_MULT)
		_score += gained
		_combo = minf(_combo + COMBO_STEP, 3.5)
		GameManager.apply_reputation_delta(CORRECT_REPUTATION)
		TouchInput.vibrate_feedback(20)
		if chosen == ParticleTypes.Class.FTIR_REQUIRED:
			_ftir_flags += 1
	else:
		_wrong_count += 1
		_combo = 1.0
		_score = maxi(_score - 40, 0)
		GameManager.apply_reputation_delta(WRONG_REPUTATION)
		TouchInput.vibrate_feedback(55)

	spot.mark_classified()
	_classified_count += 1
	_selected = null
	_update_hud()
	_prompt_label.text = "Tap the next particle"

	if _classified_count >= _particles.size():
		_finish_session()


func _finish_session() -> void:
	_active = false
	var total := maxi(_particles.size(), 1)
	var accuracy := float(_correct_count) / float(total)
	accuracy = clampf(accuracy, 0.0, 1.0)
	var avg_speed := 0.0
	if not _speed_samples.is_empty():
		var sum := 0.0
		for s in _speed_samples:
			sum += s
		avg_speed = sum / _speed_samples.size()

	var summary := {
		"score": _score,
		"accuracy": accuracy,
		"avg_speed": avg_speed,
		"ftir_flags": _ftir_flags,
		"wrong": _wrong_count,
		"classified": _classified_count,
		"class_counts": _class_counts.duplicate(true),
	}

	_show_results(summary)
	await get_tree().create_timer(2.2).timeout
	visible = false
	_results_panel.visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.apply_microscopy_results(summary)
	var microscope := get_tree().get_first_node_in_group("microscope_station")
	if microscope is MicroscopeStation:
		microscope.consume_sample_after_minigame()
	_clear_particles()


func _track_correct_class(chosen: ParticleTypes.Class) -> void:
	match chosen:
		ParticleTypes.Class.METALLIC:
			_class_counts["metallic"] = int(_class_counts.get("metallic", 0)) + 1
		ParticleTypes.Class.FIBER:
			_class_counts["fiber"] = int(_class_counts.get("fiber", 0)) + 1
		ParticleTypes.Class.NON_METALLIC:
			_class_counts["non_metallic"] = int(_class_counts.get("non_metallic", 0)) + 1


func _show_results(summary: Dictionary) -> void:
	_results_panel.visible = true
	_results_label.text = (
		"Inspection complete\nScore: %d  ·  Accuracy: %d%%\n+%d XP  ·  +%d credits\nEscalation risk: %.0f%%"
		% [
			summary.score,
			int(summary.accuracy * 100.0),
			floori(summary.score / 8.0) + int(summary.accuracy * 20.0),
			floori(summary.score / 4.0),
			GameManager.escalation_risk * 100.0,
		]
	)


func _clear_particles() -> void:
	for p in _particles:
		if is_instance_valid(p):
			p.queue_free()
	_particles.clear()


func _update_hud() -> void:
	_score_label.text = "Score %d" % _score
	_combo_label.text = "x%.2f" % _combo
