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
@onready var _label: Label = $Label
@onready var _report_badge: ColorRect = $ReportBadge


func _ready() -> void:
	add_to_group("draggable_part")
	if order == null:
		order = PartOrder.new()
	_label.text = order.order_id
	_report_badge.visible = false
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


func _refresh_visual() -> void:
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
