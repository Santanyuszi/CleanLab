extends Node
## Drag-and-drop between incoming pad, devices, and truck.

@export var lab_path: NodePath = ^".."

var _lab: Node2D
var _carried: Part = null
var _shell: LabShell = null


func _ready() -> void:
	_lab = get_node(lab_path) as Node2D
	await get_tree().process_frame
	_shell = get_tree().get_first_node_in_group("lab_shell") as LabShell


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.game_layer == GameManager.GameLayer.PROBLEM_INSPECTION:
		return
	var world: Vector2 = _event_world(event)
	if world == Vector2.INF:
		return
	if _is_press(event):
		if _carried == null:
			_try_pick(world)
		get_viewport().set_input_as_handled()
	elif _is_release(event):
		if _carried:
			_try_drop(world)
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _carried == null or GameManager.game_layer == GameManager.GameLayer.PROBLEM_INSPECTION:
		return
	var world: Vector2
	if event is InputEventScreenDrag:
		world = TouchInput.screen_to_world(_lab, event.position)
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		world = _lab.get_global_mouse_position()
	else:
		return
	_carried.global_position = world


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


func _is_release(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return not event.pressed
	if event is InputEventMouseButton:
		return not event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	return false


func _try_pick(world: Vector2) -> void:
	var station: WorkStation = _station_at(world)
	if station and station.can_pick_up():
		_carried = station.pick_up()
		_carried.begin_drag()
		_hint(_drag_hint_for(_carried))
		return
	for node in get_tree().get_nodes_in_group("draggable_part"):
		var part: Part = node as Part
		if part == null or part.is_on_station:
			continue
		if part.global_position.distance_to(world) < 56.0:
			_carried = part
			_carried.begin_drag()
			_hint(_drag_hint_for(_carried))
			return


func _try_drop(world: Vector2) -> void:
	if _carried == null:
		return
	var station: WorkStation = _station_at(world)
	if station:
		if station.station_kind == WorkStation.Kind.TRUCK:
			if station.try_deliver_report(_carried):
				var payout: int = _carried.order.payout
				var name: String = _carried.order.display_name
				_carried.end_drag()
				_carried = null
				_hint("Truck departed — +$%d  ·  %s" % [payout, name])
				_lab.call_deferred("_spawn_next_order")
				return
		if station.try_accept_part(_carried):
			_drop_cleanup("Processing at %s…" % station.station_title)
			return
	_hint("Drop on an open station.")
	_carried.global_position = world


func _drop_cleanup(hint: String) -> void:
	_carried.end_drag()
	_carried = null
	_hint(hint)


func _station_at(world: Vector2) -> WorkStation:
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.contains_point(world):
			return s
	return null


func _hint(text: String) -> void:
	if _shell:
		_shell.set_hint(text)


func _drag_hint_for(part: Part) -> String:
	if part.current_step == Part.Step.REPORT_READY:
		return "%s — drag the report to the Truck Dock." % part.order.display_name
	var destination := part.next_station_name()
	return "%s — drag to %s." % [part.order.display_name, destination]
