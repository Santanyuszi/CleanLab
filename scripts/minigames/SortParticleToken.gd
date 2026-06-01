class_name SortParticleToken
extends Control

signal dropped(token: SortParticleToken)

var true_class: int = 0
var placed: bool = false

var _dragging := false
var _grab_offset := Vector2.ZERO
var _texture: Texture2D = null
var _texture_region := Rect2()


func setup(p_class: int, local_pos: Vector2, texture: Texture2D = null, texture_region: Rect2 = Rect2()) -> void:
	true_class = p_class
	_texture = texture
	_texture_region = texture_region
	if _texture and _texture_region.size.x > 0.0:
		var token_width := 132.0
		size = Vector2(token_width, token_width * _texture_region.size.y / _texture_region.size.x)
	else:
		size = Vector2(56, 56)
	custom_minimum_size = size
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
	if _texture:
		draw_texture_rect_region(_texture, Rect2(Vector2.ZERO, size), _texture_region)
		return
	var is_fiber := true_class == 2 or true_class == 3
	var is_shiny := true_class == 1 or true_class == 3
	var black := Color(0.015, 0.015, 0.014, 1.0)
	if is_fiber:
		draw_line(Vector2(11, 32), Vector2(45, 24), black, 7.0, true)
		draw_line(Vector2(16, 39), Vector2(40, 31), black, 4.0, true)
	else:
		draw_circle(size * 0.5, 11.0, black)
	if is_shiny:
		draw_circle(Vector2(21, 20), 4.0, Color.WHITE)
		draw_line(Vector2(16, 14), Vector2(26, 24), Color.WHITE, 2.0, true)
