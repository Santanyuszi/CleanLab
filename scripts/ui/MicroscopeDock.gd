class_name MicroscopeDock
extends PanelContainer
## Bottom-center microscopy panel — visible only during inspection (not on main lab idle).

@export var particle_scene: PackedScene

const TOKEN_SCRIPT := preload("res://scripts/minigames/SortParticleToken.gd")
const CLASS_REGULAR := 0
const CLASS_METALLIC_SHINY := 1
const CLASS_FIBER := 2
const CLASS_SHINY_FIBER := 3
const FILTER_IMAGE_PATH := "res://assets/minigames/microscope/filter_47mm_base.png"
const PARTICLE_SHEETS := {
	CLASS_REGULAR: [
		"res://assets/minigames/microscope/regular.png",
	],
	CLASS_METALLIC_SHINY: [
		"res://assets/minigames/microscope/metallic_shiny_1.png",
		"res://assets/minigames/microscope/metallic_shiny_2.png",
	],
	CLASS_FIBER: [
		"res://assets/minigames/microscope/fiber.png",
	],
	CLASS_SHINY_FIBER: [
		"res://assets/minigames/microscope/shiny_fiber.png",
	],
}
const CLASS_NAMES := {
	CLASS_REGULAR: "regular",
	CLASS_METALLIC_SHINY: "metallic shiny",
	CLASS_FIBER: "fiber",
	CLASS_SHINY_FIBER: "shiny fiber",
}

@onready var _timer: Label = %TimerLabel
@onready var _combo: Label = %ComboLabel
@onready var _score: Label = %ScoreLabel
@onready var _accuracy: Label = %AccuracyLabel
@onready var _particle_field: Control = %ParticleField
@onready var _prompt: Label = %PromptLabel

var _active: bool = false
var _time_left: float = 0.0
var _score_val: int = 0
var _correct: int = 0
var _wrong: int = 0
var _token: Control = null
var _filter_texture: TextureRect = null
var _particle_class: int = CLASS_REGULAR
var _question_class: int = CLASS_REGULAR
var _linked_part: Part = null


func _ready() -> void:
	visible = false
	GameManager.microscope_session_started.connect(_on_session_started)
	for i in 2:
		var btn := find_child("ClassBtn%d" % i, true, false) as Button
		if btn == null:
			continue
		btn.text = "YES" if i == 0 else "NO"
		btn.pressed.connect(_on_class_pressed.bind(i))
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 20)
	for i in range(2, 5):
		var btn := find_child("ClassBtn%d" % i, true, false) as Button
		if btn:
			btn.visible = false
	_timer.visible = false
	_combo.visible = false
	_score.text = "REVISION NEEDED"
	_score.add_theme_font_size_override("font_size", 20)
	_accuracy.visible = false


func set_active(on: bool) -> void:
	if not on:
		_active = false
		_clear_particle()


func _on_session_started(part: Part) -> void:
	_linked_part = part
	_active = true
	_time_left = 0.0
	_score_val = 0
	_correct = 0
	_wrong = 0
	_clear_particle()
	call_deferred("_deferred_spawn_revision")
	_prompt.text = "Revision needed"
	_refresh_stats()


func _deferred_spawn_revision() -> void:
	_spawn_revision_particle()


func _process(delta: float) -> void:
	if not _active:
		return


func _spawn_revision_particle() -> void:
	var size := _particle_field.size
	if size.x < 50.0:
		size = Vector2(520, 220)
	_add_filter_texture(size)
	_particle_class = randi_range(CLASS_REGULAR, CLASS_SHINY_FIBER)
	_question_class = _roll_question_class(_particle_class)
	var asset := _particle_asset_for_class(_particle_class)
	_token = TOKEN_SCRIPT.new()
	_particle_field.add_child(_token)
	if asset.is_empty():
		_token.call("setup", _particle_class, size * 0.5)
	else:
		_token.call("setup", _particle_class, size * 0.5, asset["texture"], asset["region"])
	_token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token.scale = Vector2(1.3, 1.3)
	_prompt.text = "Is this %s?" % str(CLASS_NAMES.get(_question_class, "particle"))


func _add_filter_texture(size: Vector2) -> void:
	if _filter_texture != null and is_instance_valid(_filter_texture):
		_filter_texture.queue_free()
	_filter_texture = TextureRect.new()
	_filter_texture.name = "RevisionFilter"
	_filter_texture.texture = load(FILTER_IMAGE_PATH) as Texture2D
	_filter_texture.size = Vector2(260, 260)
	_filter_texture.position = size * 0.5 - _filter_texture.size * 0.5
	_filter_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_filter_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_filter_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_field.add_child(_filter_texture)


func _particle_asset_for_class(class_id: int) -> Dictionary:
	var paths: Array = PARTICLE_SHEETS.get(class_id, [])
	if paths.is_empty():
		return {}
	var texture := load(str(paths.pick_random())) as Texture2D
	if texture == null:
		return {}
	var tex_size := texture.get_size()
	var cell_size := Vector2(tex_size.x / 3.0, tex_size.y / 3.0)
	var cell_index := randi_range(0, 8)
	var cell := Vector2(cell_index % 3, int(cell_index / 3))
	return {
		"texture": texture,
		"region": Rect2(cell * cell_size, cell_size),
	}


func _roll_question_class(actual_class: int) -> int:
	if randf() < 0.5:
		return actual_class
	var choices: Array[int] = []
	for class_id in range(CLASS_REGULAR, CLASS_SHINY_FIBER + 1):
		if class_id != actual_class:
			choices.append(class_id)
	return choices.pick_random()


func _on_class_pressed(class_id: int) -> void:
	if not _active or _token == null:
		return
	var answered_yes := class_id == 0
	var expected_yes := _particle_class == _question_class
	var ok := answered_yes == expected_yes
	if ok:
		_correct += 1
		_score_val = 80
		_prompt.text = "Correct. Report staged."
		_token.call("mark_placed", true)
	else:
		_wrong += 1
		_score_val = 0
		_prompt.text = "Wrong judgement. Sample returned for revision."
		_token.call("mark_placed", false)
	_refresh_stats()
	_finish()


func _finish() -> void:
	_active = false
	var accuracy: float = 1.0 if _wrong == 0 else 0.0
	var summary: Dictionary = {
		"score": _score_val,
		"accuracy": accuracy,
		"avg_speed": 1.5,
		"wrong": _wrong,
		"classified": _correct,
		"class_counts": _class_counts_for_particle(),
	}
	GameManager.apply_microscopy_results(summary)
	var microscope: WorkStation = null
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.station_kind == WorkStation.Kind.MICROSCOPE:
				microscope = s
	if microscope:
		microscope.resume_after_inspection(_wrong == 0)
	await get_tree().create_timer(0.85).timeout
	_clear_particle()


func _class_counts_for_particle() -> Dictionary:
	if _wrong > 0:
		return {}
	match _particle_class:
		CLASS_METALLIC_SHINY:
			return {"metallic": 1}
		CLASS_FIBER:
			return {"fiber": 1}
		CLASS_SHINY_FIBER:
			return {"metallic": 1, "fiber": 1}
		_:
			return {"non_metallic": 1}


func _refresh_stats() -> void:
	_score.text = "REVISION NEEDED"


func _clear_particle() -> void:
	if _token != null and is_instance_valid(_token):
		_token.queue_free()
	_token = null
	if _filter_texture != null and is_instance_valid(_filter_texture):
		_filter_texture.queue_free()
	_filter_texture = null
