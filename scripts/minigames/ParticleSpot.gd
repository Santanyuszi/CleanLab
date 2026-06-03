class_name ParticleSpot
extends Control
## Tappable particle on the filter image — core microscopy interaction.

signal tapped(spot: ParticleSpot)

var true_class: ParticleTypes.Class = ParticleTypes.Class.REGULAR
var is_classified: bool = false
var spawned_at: float = 0.0

@onready var _dot: ColorRect = $Dot
@onready var _ring: ColorRect = $Ring


func _ready() -> void:
	spawned_at = Time.get_ticks_msec() / 1000.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(56, 56)
	_ring.visible = false


func setup(p_class: ParticleTypes.Class, local_pos: Vector2) -> void:
	true_class = p_class
	position = local_pos - size * 0.5
	_dot.color = ParticleTypes.color_for(p_class)


func set_selected(selected: bool) -> void:
	_ring.visible = selected
	_dot.modulate = Color(1.25, 1.25, 1.25) if selected else Color.WHITE


func mark_classified() -> void:
	is_classified = true
	modulate = Color(0.35, 0.35, 0.4, 0.5)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_selected(false)


func reaction_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - spawned_at


func _gui_input(event: InputEvent) -> void:
	if is_classified:
		return
	if TouchInput.is_tap_pressed(event):
		tapped.emit(self)
		accept_event()
