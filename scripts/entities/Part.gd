class_name Part
extends Area2D
## Product moving through lab stations.

enum Step {
	INCOMING,
	IN_PROGRESS,
	REPORT_READY,
}

@export var order: PartOrder

var current_step: Step = Step.INCOMING
## Index into order.required_steps pointing at the next station this part must visit.
var step_index: int = 0
var is_dragging: bool = false
var is_on_station: bool = false

signal picked_up(part: Part)
signal dropped(part: Part)


@onready var _visual: ColorRect = $Visual
@onready var _thumbnail: Sprite2D = $Thumbnail
@onready var _label: Label = $Label
@onready var _report_badge: ColorRect = $ReportBadge


func _ready() -> void:
	add_to_group("draggable_part")
	if order == null:
		order = PartOrder.new()
		order.display_name = "Sample"
		var steps: Array[int] = [
			int(WorkStation.Kind.EXTRACTION),
			int(WorkStation.Kind.DRYING),
			int(WorkStation.Kind.MICROSCOPE),
		]
		order.required_steps = steps
	_label.text = order.display_name if order.display_name != "" else order.order_id
	_report_badge.visible = false
	_apply_thumbnail()
	_refresh_visual()


## WorkStation.Kind int value of the next required station, or -1 when all steps are done.
func next_required_station_kind() -> int:
	if order == null or order.required_steps.is_empty():
		return -1
	if step_index >= order.required_steps.size():
		return -1
	return order.required_steps[step_index]


## Human-readable name of the next destination (used for hints and queue display).
func next_station_name() -> String:
	if current_step == Step.REPORT_READY:
		return "Truck Dock"
	var kind := next_required_station_kind()
	if kind < 0:
		return "Truck Dock"
	return _kind_to_station_name(kind)


## Human-readable name of the station that follows the current one (for queue peek).
func peek_station_after_current() -> String:
	if order == null:
		return "—"
	var next_idx := step_index + 1
	if next_idx >= order.required_steps.size():
		return "Truck Dock"
	return _kind_to_station_name(order.required_steps[next_idx])


func can_enter_station(kind: WorkStation.Kind) -> bool:
	if is_on_station:
		return false
	if current_step == Step.REPORT_READY:
		return false
	var next := next_required_station_kind()
	if next < 0:
		return false
	return next == int(kind)


func advance_step_after_station(_kind: WorkStation.Kind) -> void:
	if current_step == Step.REPORT_READY:
		return
	step_index += 1
	if order != null and step_index >= order.required_steps.size():
		set_report_ready()
	else:
		current_step = Step.IN_PROGRESS
		_refresh_visual()


func set_report_ready() -> void:
	current_step = Step.REPORT_READY
	if order != null:
		step_index = order.required_steps.size()
	_report_badge.visible = true
	_refresh_visual()


func reset_to_incoming() -> void:
	current_step = Step.INCOMING
	step_index = 0
	is_on_station = false
	_report_badge.visible = false
	_refresh_visual()


func begin_drag() -> void:
	is_dragging = true
	is_on_station = false
	z_index = 10
	scale = Vector2(1.08, 1.08)
	modulate = Color(1.15, 1.15, 1.15, 1.0)
	picked_up.emit(self)


func end_drag() -> void:
	is_dragging = false
	z_index = 0
	scale = Vector2.ONE
	modulate = Color.WHITE
	dropped.emit(self)


func attach_to_station(station: WorkStation) -> void:
	is_on_station = true
	global_position = station.get_slot_global_position()


func drop_to(target_position: Vector2) -> void:
	global_position = target_position + Vector2(0.0, -120.0)
	scale = Vector2(0.62, 0.62)
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target_position, 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.16)


func _refresh_visual() -> void:
	var has_thumbnail := _thumbnail.texture != null
	_visual.visible = not has_thumbnail
	_label.visible = not has_thumbnail
	match current_step:
		Step.INCOMING:
			_visual.color = Color(0.92, 0.48, 0.22)
		Step.IN_PROGRESS:
			var total := order.required_steps.size() if order != null and not order.required_steps.is_empty() else 3
			var t := float(step_index) / float(total)
			_visual.color = Color(0.28, 0.82, 0.92).lerp(Color(0.94, 0.86, 0.32), t)
		Step.REPORT_READY:
			_visual.color = Color(0.55, 0.75, 0.95)
			_report_badge.visible = true


static func _kind_to_station_name(kind: int) -> String:
	match kind:
		WorkStation.Kind.EXTRACTION: return "Extraction Cabinet"
		WorkStation.Kind.DRYING:     return "Drying Oven"
		WorkStation.Kind.MICROSCOPE: return "Microscope Bench"
		WorkStation.Kind.SEM:        return "SEM Analyzer"
		WorkStation.Kind.FTIR:       return "FTIR Spectrometer"
	return "Station"


func _apply_thumbnail() -> void:
	_thumbnail.visible = false
	if order.thumbnail_path.is_empty() or not ResourceLoader.exists(order.thumbnail_path):
		return
	var texture := load(order.thumbnail_path) as Texture2D
	if texture == null:
		return
	_thumbnail.texture = texture
	_thumbnail.visible = true
	var texture_size := texture.get_size()
	var max_size := 76.0
	var largest_axis := maxf(texture_size.x, texture_size.y)
	if largest_axis > 0.0:
		var uniform_scale := max_size / largest_axis
		_thumbnail.scale = Vector2(uniform_scale, uniform_scale)


func _play_spawn_animation() -> void:
	scale = Vector2(0.72, 0.72)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22)
