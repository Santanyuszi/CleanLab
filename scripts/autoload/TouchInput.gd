extends Node
## Shared tap/touch helpers — mouse and touchscreen use the same "tap" action.

const MIN_TOUCH_TARGET_PX: float = 88.0


static func is_tap_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed("tap")


static func get_screen_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return event.position
	if event is InputEventMouseButton:
		return event.position
	return Vector2.ZERO


static func screen_to_world(canvas: CanvasItem, screen_pos: Vector2) -> Vector2:
	return canvas.get_canvas_transform().affine_inverse() * screen_pos


static func vibrate_feedback(duration_ms: int = 35) -> void:
	if OS.has_feature("mobile") or OS.get_name() in ["Android", "iOS"]:
		Input.vibrate_handheld(duration_ms)
