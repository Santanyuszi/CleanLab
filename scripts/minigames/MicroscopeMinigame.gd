extends CanvasLayer
## Fast particle-classification mini-game (placeholder art).

enum ParticleClass { METALLIC, FIBER, NON_METALLIC, IGNORE }

const SESSION_DURATION: float = 15.0
const BASE_SCORE: int = 100
const COMBO_STEP: float = 0.15
const WRONG_REPUTATION: float = -4.0
const CORRECT_REPUTATION: float = 0.5

@export var rounds_per_session: int = 8

@onready var _panel: PanelContainer = $Center/Panel
@onready var _particle_view: ColorRect = $Center/Panel/Margin/VBox/ParticleView
@onready var _timer_label: Label = $Center/Panel/Margin/VBox/TimerLabel
@onready var _score_label: Label = $Center/Panel/Margin/VBox/ScoreLabel
@onready var _combo_label: Label = $Center/Panel/Margin/VBox/ComboLabel
@onready var _prompt_label: Label = $Center/Panel/Margin/VBox/PromptLabel

var _active: bool = false
var _time_left: float = 0.0
var _score: int = 0
var _combo: float = 1.0
var _round_index: int = 0
var _correct_class: ParticleClass = ParticleClass.METALLIC
var _linked_sample: Sample = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.microscope_minigame_requested.connect(_on_minigame_requested)


func _process(delta: float) -> void:
	if not _active:
		return
	_time_left -= delta
	_timer_label.text = "Time: %.1fs" % maxf(_time_left, 0.0)
	if _time_left <= 0.0:
		_end_session()


func _on_minigame_requested(sample: Sample) -> void:
	_linked_sample = sample
	_start_session()


func _start_session() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	_active = true
	_time_left = SESSION_DURATION
	_score = 0
	_combo = 1.0
	_round_index = 0
	_update_hud()
	_next_round()


func _next_round() -> void:
	if _round_index >= rounds_per_session:
		_end_session()
		return
	_correct_class = randi() % 4 as ParticleClass
	_particle_view.color = _color_for_class(_correct_class)
	_prompt_label.text = "Classify the particle!"
	_round_index += 1


func _on_answer_pressed(class_id: int) -> void:
	if not _active:
		return
	var chosen := class_id as ParticleClass
	if chosen == _correct_class:
		var gained := int(BASE_SCORE * _combo)
		_score += gained
		_combo = minf(_combo + COMBO_STEP, 3.0)
		GameManager.apply_reputation_delta(CORRECT_REPUTATION)
	else:
		_combo = 1.0
		_score = maxi(_score - 50, 0)
		GameManager.apply_reputation_delta(WRONG_REPUTATION)
	_update_hud()
	_next_round()


func _end_session() -> void:
	_active = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.notify_minigame_complete(_score, 0.0)
	var microscope := get_tree().get_first_node_in_group("microscope_station")
	if microscope is MicroscopeStation:
		microscope.consume_sample_after_minigame()


func _update_hud() -> void:
	_score_label.text = "Score: %d" % _score
	_combo_label.text = "Combo: x%.2f" % _combo


func _color_for_class(p_class: ParticleClass) -> Color:
	match p_class:
		ParticleClass.METALLIC:
			return Color(0.75, 0.8, 0.9)
		ParticleClass.FIBER:
			return Color(0.9, 0.5, 0.3)
		ParticleClass.NON_METALLIC:
			return Color(0.4, 0.85, 0.55)
		ParticleClass.IGNORE:
			return Color(0.45, 0.45, 0.5)
	return Color.WHITE
