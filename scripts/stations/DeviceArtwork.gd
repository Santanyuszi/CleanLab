class_name DeviceArtwork
extends Node2D
## Procedural station artwork placeholder; replace per-level art with textures later.

@export var device_key := "extraction":
	set(value):
		device_key = value
		queue_redraw()

@export_range(1, 4, 1) var device_level := 1:
	set(value):
		device_level = value
		queue_redraw()

@export var owned := true:
	set(value):
		owned = value
		queue_redraw()


func _ready() -> void:
	z_index = 1
	queue_redraw()


func _draw() -> void:
	if not owned:
		_draw_locked_placeholder()
		return
	match device_key:
		"extraction":
			_draw_extraction()
		"drying":
			_draw_drying_oven()
		"microscope":
			_draw_microscope()


func _draw_extraction() -> void:
	var scale_factor := 0.84 + float(device_level) * 0.08
	var body := Rect2(Vector2(-78, -88) * scale_factor, Vector2(156, 176) * scale_factor)
	_draw_machine_body(body)
	var chamber := Rect2(body.position + Vector2(18, 24) * scale_factor, Vector2(120, 72) * scale_factor)
	draw_rect(chamber, Color(0.62, 0.72, 0.76, 0.42), true)
	draw_arc(chamber.get_center(), chamber.size.x * 0.32, PI, TAU, 48, Color(0.02, 0.04, 0.05), 5.0 * scale_factor)
	_draw_teal_handle(body.position + Vector2(24, 14) * scale_factor, 34.0 * scale_factor)
	_draw_status_lights(body.position + Vector2(body.size.x - 54, body.size.y - 42), scale_factor)


func _draw_drying_oven() -> void:
	var scale_factor := 0.86 + float(device_level) * 0.07
	var body := Rect2(Vector2(-82, -72) * scale_factor, Vector2(164, 144) * scale_factor)
	_draw_machine_body(body)
	for i in 3:
		var shelf_y := body.position.y + (38 + i * 30) * scale_factor
		draw_line(Vector2(body.position.x + 16 * scale_factor, shelf_y), Vector2(body.end.x - 16 * scale_factor, shelf_y), Color(0.72, 0.8, 0.82), 2.0)
	var window := Rect2(body.position + Vector2(20, 28) * scale_factor, Vector2(84, 78) * scale_factor)
	draw_rect(window, Color(0.45, 0.55, 0.58, 0.28), true)
	_draw_teal_handle(body.position + Vector2(118, 24) * scale_factor, 24.0 * scale_factor)


func _draw_microscope() -> void:
	var scale_factor := 0.82 + float(device_level) * 0.08
	var bench := Rect2(Vector2(-92, 20) * scale_factor, Vector2(184, 48) * scale_factor)
	_draw_machine_body(bench)
	var monitor := Rect2(Vector2(-50, -80) * scale_factor, Vector2(100, 60) * scale_factor)
	draw_rect(monitor, Color(0.01, 0.035, 0.045), true)
	draw_rect(monitor, Color(0.0, 0.75, 0.72, 0.28), false, 2.0)
	draw_string(ThemeDB.fallback_font, monitor.position + Vector2(23, 37) * scale_factor, "OASIS", HORIZONTAL_ALIGNMENT_LEFT, -1, 16 * scale_factor, Color(0.7, 1.0, 1.0))
	var tower := Rect2(Vector2(54, -62) * scale_factor, Vector2(42, 118) * scale_factor)
	_draw_machine_body(tower)
	draw_circle(Vector2(76, 4) * scale_factor, 10.0 * scale_factor, Color(0.0, 0.55, 0.55))


func _draw_locked_placeholder() -> void:
	var body := Rect2(Vector2(-70, -55), Vector2(140, 110))
	draw_rect(body, Color(0.04, 0.06, 0.07, 0.68), true)
	draw_rect(body, Color(0.35, 0.42, 0.48, 0.65), false, 2.0)
	draw_line(body.position + Vector2(28, 28), body.end - Vector2(28, 28), Color(0.35, 0.42, 0.48), 2.0)
	draw_line(Vector2(body.end.x - 28, body.position.y + 28), Vector2(body.position.x + 28, body.end.y - 28), Color(0.35, 0.42, 0.48), 2.0)


func _draw_machine_body(rect: Rect2) -> void:
	draw_rect(rect, Color(0.91, 0.95, 0.96), true)
	draw_rect(rect, Color(0.58, 0.68, 0.72), false, 2.0)
	var base := Rect2(Vector2(rect.position.x, rect.end.y - 14.0), Vector2(rect.size.x, 14.0))
	draw_rect(base, Color(0.0, 0.28, 0.3), true)


func _draw_teal_handle(pos: Vector2, width: float) -> void:
	draw_rect(Rect2(pos, Vector2(width, 5.0)), Color(0.0, 0.55, 0.56), true)


func _draw_status_lights(pos: Vector2, scale_factor: float) -> void:
	for i in 3:
		draw_circle(pos + Vector2(i * 15.0 * scale_factor, 0), 4.5 * scale_factor, Color(0.0, 0.55 + i * 0.12, 0.58))
