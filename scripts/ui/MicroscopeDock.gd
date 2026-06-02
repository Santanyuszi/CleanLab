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
	CLASS_REGULAR: "REGULAR",
	CLASS_METALLIC_SHINY: "METALLIC SHINY",
	CLASS_FIBER: "FIBER",
	CLASS_SHINY_FIBER: "SHINY FIBER",
}
const FILTER_DISPLAY_MIN := 190.0
const FILTER_DISPLAY_MAX := 340.0
const CORNER_BUTTON_SIZE := Vector2(178, 58)
const CORNER_BUTTON_MARGIN := 12.0
const BUTTON_BG := Color("#FFFFFF")
const BUTTON_HOVER := Color("#F2F9F8")
const BUTTON_PRESSED := Color("#4CFFBD")
const BUTTON_BORDER := Color(0.561, 0.694, 0.706, 0.72)
const BUTTON_TEXT := Color("#002121")

@onready var _timer: Label = %TimerLabel
@onready var _combo: Label = %ComboLabel
@onready var _score: Label = %ScoreLabel
@onready var _accuracy: Label = %AccuracyLabel
@onready var _particle_field: Control = %ParticleField
@onready var _prompt: Label = %PromptLabel
@onready var _title: Label = get_node_or_null("Margin/VBox/Title") as Label

var _active: bool = false
var _time_left: float = 0.0
var _score_val: int = 0
var _correct: int = 0
var _wrong: int = 0
var _token: Control = null
var _filter_texture: TextureRect = null
var _particle_class: int = CLASS_REGULAR
var _linked_part: Part = null
var _class_buttons: Dictionary = {}


func _ready() -> void:
	visible = false
	GameManager.microscope_session_started.connect(_on_session_started)
	_hide_old_class_buttons()
	_add_corner_class_buttons()
	_particle_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_particle_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_particle_field.custom_minimum_size = Vector2(0, 260)
	_particle_field.resized.connect(_layout_revision_controls)
	_timer.visible = false
	_combo.visible = false
	if _score.get_parent() is CanvasItem:
		(_score.get_parent() as CanvasItem).visible = false
	if _title:
		_title.text = "CRITICAL PARTICLE FOUND"
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_title.add_theme_font_size_override("font_size", 22)
	_accuracy.visible = false
	_prompt.text = "Select the particle category."
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _hide_old_class_buttons() -> void:
	var bottom := get_node_or_null("Margin/VBox/Bottom") as CanvasItem
	if bottom:
		bottom.visible = false
	for i in range(0, 5):
		var btn := find_child("ClassBtn%d" % i, true, false) as Button
		if btn:
			btn.visible = false


func _add_corner_class_buttons() -> void:
	for class_id in range(CLASS_REGULAR, CLASS_SHINY_FIBER + 1):
		if _class_buttons.has(class_id):
			continue
		var btn := Button.new()
		btn.name = "ClassCorner%d" % class_id
		btn.text = str(CLASS_NAMES.get(class_id, "CLASS"))
		btn.custom_minimum_size = CORNER_BUTTON_SIZE
		btn.size = CORNER_BUTTON_SIZE
		btn.add_theme_font_size_override("font_size", 15)
		_style_class_button(btn)
		btn.pressed.connect(_on_class_pressed.bind(class_id))
		_particle_field.add_child(btn)
		_class_buttons[class_id] = btn
	_layout_revision_controls()


func _style_class_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _button_style(BUTTON_BG, BUTTON_BORDER))
	button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER, BUTTON_PRESSED))
	button.add_theme_stylebox_override("pressed", _button_style(Color(BUTTON_PRESSED.r, BUTTON_PRESSED.g, BUTTON_PRESSED.b, 0.72), BUTTON_PRESSED))
	button.add_theme_color_override("font_color", BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT)


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	return style


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
	_prompt.text = "Select the particle category."
	_refresh_stats()


func _deferred_spawn_revision() -> void:
	_spawn_revision_particle()


func _process(delta: float) -> void:
	if not _active:
		return


func _spawn_revision_particle() -> void:
	var size := _particle_field.size
	if size.x < 50.0:
		size = Vector2(640, 320)
	_add_filter_texture(size)
	_particle_class = randi_range(CLASS_REGULAR, CLASS_SHINY_FIBER)
	var asset := _particle_asset_for_class(_particle_class)
	_token = TOKEN_SCRIPT.new()
	_particle_field.add_child(_token)
	if asset.is_empty():
		_token.call("setup", _particle_class, size * 0.5)
	else:
		_token.call("setup", _particle_class, size * 0.5, asset["texture"])
	_token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_token.scale = Vector2(0.92, 0.92)
	_center_filter_and_particle(size)
	_prompt.text = "Select the particle category."


func _add_filter_texture(size: Vector2) -> void:
	if _filter_texture != null and is_instance_valid(_filter_texture):
		_filter_texture.queue_free()
	_filter_texture = TextureRect.new()
	_filter_texture.name = "RevisionFilter"
	_filter_texture.texture = load(FILTER_IMAGE_PATH) as Texture2D
	_filter_texture.size = _filter_display_size(size)
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
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(cell * cell_size, cell_size)
	return {
		"texture": atlas,
	}


func _layout_revision_controls() -> void:
	if _particle_field == null:
		return
	var size := _particle_field.size
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var button_size := CORNER_BUTTON_SIZE
	var positions := {
		CLASS_REGULAR: Vector2(CORNER_BUTTON_MARGIN, CORNER_BUTTON_MARGIN),
		CLASS_METALLIC_SHINY: Vector2(size.x - button_size.x - CORNER_BUTTON_MARGIN, CORNER_BUTTON_MARGIN),
		CLASS_FIBER: Vector2(CORNER_BUTTON_MARGIN, size.y - button_size.y - CORNER_BUTTON_MARGIN),
		CLASS_SHINY_FIBER: Vector2(size.x - button_size.x - CORNER_BUTTON_MARGIN, size.y - button_size.y - CORNER_BUTTON_MARGIN),
	}
	for class_id in _class_buttons:
		var button := _class_buttons[class_id] as Button
		if button:
			button.size = button_size
			button.position = positions.get(class_id, Vector2.ZERO)
	_center_filter_and_particle(size)


func _center_filter_and_particle(size: Vector2) -> void:
	var center := size * 0.5
	if _filter_texture != null and is_instance_valid(_filter_texture):
		var filter_size := _filter_display_size(size)
		_filter_texture.size = filter_size
		_filter_texture.position = center - filter_size * 0.5
	if _token != null and is_instance_valid(_token):
		_token.position = center - _token.size * _token.scale * 0.5


func _filter_display_size(field_size: Vector2) -> Vector2:
	var button_clearance := CORNER_BUTTON_SIZE.y + CORNER_BUTTON_MARGIN * 2.0
	var usable_height := maxf(field_size.y - button_clearance, FILTER_DISPLAY_MIN)
	var side_clearance := CORNER_BUTTON_SIZE.x * 2.0 + CORNER_BUTTON_MARGIN * 4.0
	var usable_width := maxf(field_size.x - side_clearance, FILTER_DISPLAY_MIN)
	var diameter := clampf(minf(minf(field_size.x * 0.46, usable_width), usable_height), FILTER_DISPLAY_MIN, FILTER_DISPLAY_MAX)
	return Vector2(diameter, diameter)


func _on_class_pressed(class_id: int) -> void:
	if not _active or _token == null:
		return
	var ok := class_id == _particle_class
	if ok:
		_correct += 1
		_score_val = 80
		_prompt.text = "Correct classification. Report staged."
		_token.call("mark_placed", true)
	else:
		_wrong += 1
		_score_val = 0
		_prompt.text = "Wrong classification. Sample returned for revision."
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
