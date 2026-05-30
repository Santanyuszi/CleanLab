class_name ProblemInspectionPopup
extends CanvasLayer
## QC revision popup: drag particles from the filter into the four corner groups.

const MIN_PARTICLE_COUNT := 1
const MAX_PARTICLE_COUNT := 2
const TOKEN_SCRIPT := preload("res://scripts/minigames/SortParticleToken.gd")
const CLASS_REGULAR := 0
const CLASS_METALLIC := 1
const CLASS_FIBER := 2
const CLASS_SHINY_FIBER := 3
const GROUP_NAMES := {
	CLASS_REGULAR: "REGULAR",
	CLASS_METALLIC: "METALLIC",
	CLASS_FIBER: "FIBER",
	CLASS_SHINY_FIBER: "SHINY FIBER",
}

@onready var _board: ColorRect = %ParticleView
@onready var _status: Label = %ClaimLabel

var _part: Part = null
var _station: WorkStation = null
var _tokens: Array[Control] = []
var _zones: Dictionary = {}
var _completed := 0
var _mistakes := 0
var _particle_count := MIN_PARTICLE_COUNT


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	GameManager.problem_inspection_requested.connect(_on_requested)
	call_deferred("_build_zones")


func _on_requested(part: Part, _claims: Array) -> void:
	var station: WorkStation = null
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.station_kind == WorkStation.Kind.MICROSCOPE and s.held_part == part:
			station = s
			break
	open(part, station)


func open(part: Part, station: WorkStation) -> void:
	_part = part
	_station = station
	_completed = 0
	_mistakes = 0
	_particle_count = randi_range(MIN_PARTICLE_COUNT, MAX_PARTICLE_COUNT)
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	await get_tree().process_frame
	_clear_tokens()
	_build_zones()
	_spawn_tokens()
	_update_status()


func _build_zones() -> void:
	if _board == null or _board.size.x <= 0.0:
		return
	for child in _board.get_children():
		if child.name.begins_with("Zone"):
			child.queue_free()
	_zones.clear()
	var specs := [
		{"class": CLASS_REGULAR, "name": "ZoneRegular", "pos": Vector2(18, 18)},
		{"class": CLASS_METALLIC, "name": "ZoneMetallic", "pos": Vector2(_board.size.x - 168, 18)},
		{"class": CLASS_FIBER, "name": "ZoneFiber", "pos": Vector2(18, _board.size.y - 88)},
		{"class": CLASS_SHINY_FIBER, "name": "ZoneShinyFiber", "pos": Vector2(_board.size.x - 168, _board.size.y - 88)},
	]
	for spec in specs:
		var zone := PanelContainer.new()
		zone.name = spec.name
		zone.position = spec.pos
		zone.size = Vector2(150, 70)
		zone.mouse_filter = Control.MOUSE_FILTER_IGNORE
		zone.add_theme_stylebox_override("panel", _zone_style())
		_board.add_child(zone)

		var label := Label.new()
		label.text = str(GROUP_NAMES[int(spec["class"])])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.72, 0.95, 1.0))
		zone.add_child(label)
		_zones[spec["class"]] = Rect2(zone.position, zone.size)


func _spawn_tokens() -> void:
	var center := _board.size * 0.5
	var radius := minf(_board.size.x, _board.size.y) * 0.22
	for i in _particle_count:
		var token: Control = TOKEN_SCRIPT.new()
		_board.add_child(token)
		var p_class := i % 4
		var angle := randf() * TAU
		var pos := center + Vector2(cos(angle), sin(angle)) * randf_range(20.0, radius)
		token.call("setup", p_class, pos)
		token.connect("dropped", Callable(self, "_on_token_dropped"))
		_tokens.append(token)


func _on_token_dropped(token: Control) -> void:
	for class_id in _zones.keys():
		var zone: Rect2 = _zones[class_id]
		var token_center := token.position + token.size * 0.5
		if zone.has_point(token_center):
			var ok := int(token.get("true_class")) == int(class_id)
			token.position = zone.get_center() - token.size * 0.5
			token.call("mark_placed", ok)
			_completed += 1
			if not ok:
				_mistakes += 1
			_update_status()
			if _completed == _particle_count:
				_finish()
			return
	_update_status("Place the particle into one of the four groups.")


func _finish() -> void:
	var passed := _mistakes == 0
	if passed:
		_show_ok()
		await get_tree().create_timer(0.8).timeout
	if _station:
		_station.resume_after_inspection(passed)
	GameManager.leave_problem_inspection()
	GameManager.resolve_problem_inspection(_part, passed)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_part = null
	_station = null
	_clear_tokens()


func _show_ok() -> void:
	var ok_label := Label.new()
	ok_label.name = "RevisionOK"
	ok_label.text = "OK"
	ok_label.position = _board.size * 0.5 - Vector2(64, 64)
	ok_label.size = Vector2(128, 128)
	ok_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ok_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ok_label.add_theme_font_size_override("font_size", 52)
	ok_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.35))
	_board.add_child(ok_label)


func _update_status(message: String = "") -> void:
	if message != "":
		_status.text = message
		return
	_status.text = "%d / %d sorted correctly. Mistakes: %d" % [_completed - _mistakes, _particle_count, _mistakes]


func _clear_tokens() -> void:
	for token in _tokens:
		if is_instance_valid(token):
			token.queue_free()
	_tokens.clear()
	var ok := _board.get_node_or_null("RevisionOK")
	if ok:
		ok.queue_free()


func _zone_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.08, 0.1, 0.88)
	style.border_color = Color(0.0, 0.85, 0.9, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
