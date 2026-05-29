class_name SortParticleToken
extends Control

signal dropped(token: SortParticleToken)

var true_class: int = 0
var placed: bool = false

var _dragging := false
var _grab_offset := Vector2.ZERO


func setup(p_class: int, local_pos: Vector2) -> void:
	true_class = p_class
	size = Vector2(42, 42)
	position = local_pos - size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if placed:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_grab_offset = event.position
			z_index = 20
		else:
			_dragging = false
			z_index = 0
			dropped.emit(self)
	elif event is InputEventMouseMotion and _dragging:
		global_position = event.global_position - _grab_offset
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_grab_offset = event.position - global_position
			z_index = 20
		else:
			_dragging = false
			z_index = 0
			dropped.emit(self)
	elif event is InputEventScreenDrag and _dragging:
		global_position = event.position - _grab_offset


func mark_placed(ok: bool) -> void:
	placed = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate = Color(0.55, 1.0, 0.58, 1.0) if ok else Color(1.0, 0.35, 0.3, 1.0)


func _draw() -> void:
	var is_fiber := true_class == 2 or true_class == 3
	var is_shiny := true_class == 1 or true_class == 3
	var black := Color(0.015, 0.015, 0.014, 1.0)
	if is_fiber:
		draw_line(Vector2(8, 24), Vector2(34, 18), black, 5.0, true)
		draw_line(Vector2(12, 29), Vector2(30, 23), black, 3.0, true)
	else:
		draw_circle(size * 0.5, 8.0, black)
	if is_shiny:
		draw_circle(Vector2(16, 15), 3.2, Color.WHITE)
		draw_line(Vector2(12, 10), Vector2(20, 18), Color.WHITE, 1.6, true)
