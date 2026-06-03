class_name Part
extends Area2D
## Product moving through lab stations.

enum Step {
	INCOMING,
	EXTRACTED,
	DRIED,
	REPORT_READY,
}

@export var order: PartOrder

var current_step: Step = Step.INCOMING
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
	_label.text = order.order_id
	_report_badge.visible = false
	_apply_thumbnail()
	_refresh_visual()


func can_enter_station(kind: WorkStation.Kind) -> bool:
	if is_on_station:
		return false
	match kind:
		WorkStation.Kind.EXTRACTION:
			return current_step == Step.INCOMING and order.needs_extraction
		WorkStation.Kind.DRYING:
			return current_step == Step.EXTRACTED and order.needs_drying
		WorkStation.Kind.MICROSCOPE:
			return current_step == Step.DRIED and order.needs_microscope
		WorkStation.Kind.TRUCK:
			return current_step == Step.REPORT_READY
	return false


func advance_step_after_station(kind: WorkStation.Kind) -> void:
	match kind:
		WorkStation.Kind.EXTRACTION:
			current_step = Step.EXTRACTED
		WorkStation.Kind.DRYING:
			current_step = Step.DRIED
		WorkStation.Kind.MICROSCOPE:
			current_step = Step.REPORT_READY
	_refresh_visual()


func set_report_ready() -> void:
	current_step = Step.REPORT_READY
	_report_badge.visible = true
	_refresh_visual()


func reset_to_incoming() -> void:
	current_step = Step.INCOMING
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
		Step.EXTRACTED:
			_visual.color = Color(0.28, 0.82, 0.92)
		Step.DRIED:
			_visual.color = Color(0.94, 0.86, 0.32)
		Step.REPORT_READY:
			_visual.color = Color(0.55, 0.75, 0.95)
			_report_badge.visible = true


func _apply_thumbnail() -> void:
	_thumbnail.visible = false
	if order.thumbnail_path.is_empty() or not FileAccess.file_exists(order.thumbnail_path):
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
