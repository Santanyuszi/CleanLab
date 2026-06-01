class_name FilterCircle
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var radius := minf(size.x, size.y) * 0.46
	var center := size * 0.5
	draw_circle(center, radius, Color(0.96, 0.97, 0.95, 1.0))
	draw_arc(center, radius, 0.0, TAU, 96, Color(0.65, 0.72, 0.74, 1.0), 3.0)
	draw_circle(center, radius * 0.04, Color(0.9, 0.92, 0.9, 0.8))
