extends Node
## Tap-to-route controller between incoming, stations, and reports out.

@export var lab_path: NodePath = ^".."

var _lab: Node2D
var _shell: LabShell = null


func _ready() -> void:
	_lab = get_node(lab_path) as Node2D
	await get_tree().process_frame
	_shell = get_tree().get_first_node_in_group("lab_shell") as LabShell


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.game_layer != GameManager.GameLayer.LAB:
		return
	var world: Vector2 = _event_world(event)
	if world == Vector2.INF:
		return
	if _is_press(event):
		_handle_tap(world)
		get_viewport().set_input_as_handled()


func _event_world(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return TouchInput.screen_to_world(_lab, (event as InputEventScreenTouch).position)
	if event is InputEventScreenDrag:
		return TouchInput.screen_to_world(_lab, (event as InputEventScreenDrag).position)
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		return _lab.get_global_mouse_position()
	return Vector2.INF


func _is_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _handle_tap(world: Vector2) -> void:
	var ready_station := _ready_station_part_at(world)
	if ready_station:
		var ready_part := ready_station.get_ready_part_at(world)
		if ready_part and ready_part.current_step == Part.Step.REPORT_READY and not GameManager.can_stage_report():
			_hint("Truck is full. Send it before the microscope can release more reports.")
			return
		_route_part(ready_station.pick_up())
		return
	var station: WorkStation = _station_at(world)
	if station and station.can_pick_up():
		if station.station_kind == WorkStation.Kind.MICROSCOPE and station.held_part and station.held_part.current_step == Part.Step.REPORT_READY and not GameManager.can_stage_report():
			_hint("Truck is full. Send it before the microscope can release more reports.")
			return
		_route_part(station.pick_up())
		return
	if station and station.held_part != null:
		_hint("Processing at %s." % station.station_title)
		return
	var part := _part_at(world)
	if part:
		_route_part(part)
		return
	_hint("Tap the orange sample or a finished station.")


func _ready_station_part_at(world: Vector2) -> WorkStation:
	for node in get_tree().get_nodes_in_group("work_station"):
		var station := node as WorkStation
		if station == null or not station.can_pick_up():
			continue
		if station.get_ready_part_at(world):
			return station
	return null


func _part_at(world: Vector2) -> Part:
	for node in get_tree().get_nodes_in_group("draggable_part"):
		var part: Part = node as Part
		if part == null or part.is_on_station:
			continue
		if part.global_position.distance_to(world) < 56.0:
			return part
	return null


func _route_part(part: Part) -> void:
	if part == null:
		return
	if part.current_step == Part.Step.REPORT_READY:
		_stage_report(part)
		return
	var station := _next_station_for(part)
	if station == null:
		_hint("Next station is not available.")
		return
	if not station.can_accept_part(part):
		_hint("%s is not ready." % station.station_title)
		return
	var from_pos := part.global_position
	if station.try_accept_part(part):
		part.global_position = from_pos
		_tween_part_to(part, station.get_slot_global_position())
		_hint("%s started." % station.station_title)


func _next_station_for(part: Part) -> WorkStation:
	var target_kind: WorkStation.Kind
	match part.current_step:
		Part.Step.INCOMING:
			target_kind = WorkStation.Kind.EXTRACTION
		Part.Step.EXTRACTED:
			target_kind = WorkStation.Kind.DRYING
		Part.Step.DRIED:
			target_kind = WorkStation.Kind.MICROSCOPE
		_:
			return null
	for node in get_tree().get_nodes_in_group("work_station"):
		var station := node as WorkStation
		if station and station.station_kind == target_kind:
			return station
	return null


func _tween_part_to(part: Part, target: Vector2) -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(part, "global_position", target, 0.22)


func _stage_report(part: Part) -> void:
	if GameManager.stage_report_for_shipping(part):
		_tween_part_to(part, Vector2(1238, 508))
		await get_tree().create_timer(0.24).timeout
		if is_instance_valid(part):
			part.queue_free()
		_hint("Report staged. Send the truck when ready.")
	elif GameManager.is_order_broken(part.order.order_id):
		_hint("Contract broken. This report can no longer be shipped.")
	elif not GameManager.can_stage_report():
		_hint("Truck is full. Send it before staging more reports.")


func _station_at(world: Vector2) -> WorkStation:
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.contains_point(world):
			return s
	return null


func _hint(text: String) -> void:
	if _shell:
		_shell.set_hint(text)
