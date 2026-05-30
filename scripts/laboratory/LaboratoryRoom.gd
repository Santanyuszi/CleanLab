extends Node2D
## Lab floor: tap samples through stations, then send staged reports by truck.

@export var part_scene: PackedScene

const DRAWN_ART_NODES: Array[StringName] = [
	&"LabArtLabel",
	&"RoomGlow",
	&"RoomFrame",
	&"RoomInterior",
	&"BackWall",
	&"FloorPlane",
	&"CeilingBand",
	&"LightStrip1",
	&"LightStrip2",
	&"LightStrip3",
	&"GlassLine1",
	&"GlassLine2",
	&"GlassLine3",
	&"ExtractionMachine",
	&"ExtractionWindow",
	&"DryingCabinet",
	&"Bench",
	&"Monitor",
	&"StorageRack",
	&"SamplesSlot",
	&"SamplesInLabel",
	&"ReportsSlot",
	&"ReportsOutLabel",
	&"OasisLogo",
	&"OasisSub",
	&"IncomingLabel",
	&"TruckLabel",
]

const DEVICE_OVERLAY_NODES := {
	"extraction": &"ExtractionOverlay",
	"drying": &"OvenOverlay",
	"microscope": &"MicroscopeOverlay",
}

const STATION_BUTTONS := {
	"extraction": &"StationButtons/ExtractionButton",
	"drying": &"StationButtons/OvenButton",
	"microscope": &"StationButtons/MicroscopeButton",
}

const STATION_BUTTON_SCALE := Vector2(2.35, 2.35)
const STATION_OVERLAY_IDLE := Color(1.0, 1.0, 1.0, 1.0)

@onready var _incoming_pad: Marker2D = %IncomingPad

var _button_tweens: Dictionary = {}
var _button_states: Dictionary = {}


func _ready() -> void:
	_hide_drawn_art()
	_refresh_device_overlays()
	_connect_station_buttons()
	GameManager.device_changed.connect(_on_device_changed)
	GameManager.start_run()


func spawn_contract(contract: Dictionary) -> void:
	if not GameManager.has_manufacturing_capacity():
		return
	_spawn_order(GameManager.create_order_from_contract(contract))


func spawn_contract_batch(contract: Dictionary) -> int:
	var accepted := 0
	var batch_size := int(contract.get("batch_size", 1))
	for i in batch_size:
		if not GameManager.has_manufacturing_capacity():
			break
		_spawn_order(GameManager.create_order_from_contract(contract))
		accepted += 1
	return accepted


func cancel_contract_order(order_id: String) -> bool:
	for station in get_tree().get_nodes_in_group("work_station"):
		if station is WorkStation and station.remove_order(order_id):
			GameManager.cancel_active_contract(order_id)
			return true
	for child in get_children():
		if child is Part and child.order and child.order.order_id == order_id:
			child.queue_free()
			GameManager.cancel_active_contract(order_id)
			return true
	return false


func _spawn_order(order: PartOrder) -> void:
	if not GameManager.has_manufacturing_capacity():
		return
	var part: Part = part_scene.instantiate()
	part.order = order
	part.global_position = _incoming_pad.global_position + Vector2(randf_range(-38.0, 38.0), randf_range(-26.0, 26.0))
	add_child(part)
	GameManager.register_part_in_queue(part)


func _hide_drawn_art() -> void:
	for node_name in DRAWN_ART_NODES:
		var node := get_node_or_null(NodePath(node_name))
		if node is CanvasItem:
			(node as CanvasItem).visible = false


func _on_device_changed(_device_key: String) -> void:
	_refresh_device_overlays()


func _refresh_device_overlays() -> void:
	for device_key in DEVICE_OVERLAY_NODES:
		var node := get_node_or_null(NodePath(DEVICE_OVERLAY_NODES[device_key]))
		if node is CanvasItem:
			(node as CanvasItem).visible = GameManager.is_device_owned(device_key)
	for device_key in STATION_BUTTONS:
		var button := get_node_or_null(NodePath(STATION_BUTTONS[device_key])) as TextureButton
		if button:
			button.visible = GameManager.is_device_owned(device_key)


func _connect_station_buttons() -> void:
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("work_station"):
		var station := node as WorkStation
		if station == null or not STATION_BUTTONS.has(station.device_key):
			continue
		station.status_changed.connect(_on_station_status)
		var button := get_node_or_null(NodePath(STATION_BUTTONS[station.device_key])) as TextureButton
		if button:
			button.pressed.connect(_on_station_button_pressed.bind(station))
			button.tooltip_text = station.station_title
		_on_station_status(station.device_key, station.get_ui_status(), station.get_ui_progress(), station.get_ui_time_left())


func _on_station_button_pressed(station: WorkStation) -> void:
	var controller := get_node_or_null("DragController")
	if controller and controller.has_method("_handle_tap"):
		controller.call("_handle_tap", station.global_position)


func flash_station_warning(device_key: String) -> void:
	var button := get_node_or_null(NodePath(STATION_BUTTONS.get(device_key, &""))) as TextureButton
	var overlay := get_node_or_null(NodePath(DEVICE_OVERLAY_NODES.get(device_key, &""))) as TextureRect
	if button == null or overlay == null:
		return
	_stop_button_tween(device_key)
	button.modulate = Color(1.0, 0.28, 0.08, 0.5)
	overlay.modulate = Color(1.0, 0.5, 0.28, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(button, "modulate:a", 0.08, 0.18)
	tween.tween_property(overlay, "modulate", STATION_OVERLAY_IDLE, 0.18)
	tween.chain().set_parallel(true)
	tween.tween_property(button, "modulate:a", 0.5, 0.18)
	tween.tween_property(overlay, "modulate", Color(1.0, 0.5, 0.28, 1.0), 0.18)
	tween.chain().set_parallel(true)
	tween.tween_property(button, "modulate:a", 0.0, 0.22)
	tween.tween_property(overlay, "modulate", STATION_OVERLAY_IDLE, 0.22)


func _on_station_status(device_key: String, status: String, _progress: float, _time_left: float) -> void:
	var button := get_node_or_null(NodePath(STATION_BUTTONS.get(device_key, &""))) as TextureButton
	var overlay := get_node_or_null(NodePath(DEVICE_OVERLAY_NODES.get(device_key, &""))) as TextureRect
	if button == null or overlay == null:
		return
	if _button_states.get(device_key, "") == status:
		return
	_button_states[device_key] = status
	_stop_button_tween(device_key)
	match status:
		"Processing":
			button.modulate = Color(0.0, 0.9, 1.0, 0.22)
			overlay.modulate = Color(0.72, 0.98, 1.0, 0.9)
			var tween := create_tween().set_loops()
			tween.set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(0.38, 0.86, 1.0, 0.66), 0.55)
			tween.tween_property(button, "modulate:a", 0.5, 0.55)
			tween.chain().set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(0.9, 1.0, 1.0, 1.0), 0.55)
			tween.tween_property(button, "modulate:a", 0.18, 0.55)
			_button_tweens[device_key] = tween
		"Ready":
			button.modulate = Color(0.65, 1.0, 0.25, 0.36)
			overlay.modulate = Color(1.0, 1.0, 0.72, 1.0)
			var tween := create_tween().set_loops()
			tween.set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(0.62, 1.0, 0.35, 0.78), 0.28)
			tween.tween_property(button, "scale", STATION_BUTTON_SCALE * 1.04, 0.28)
			tween.chain().set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(1.0, 1.0, 0.82, 1.0), 0.28)
			tween.tween_property(button, "scale", STATION_BUTTON_SCALE, 0.28)
			_button_tweens[device_key] = tween
		"Inspection":
			button.modulate = Color(1.0, 0.1, 0.1, 0.36)
			overlay.modulate = Color(1.0, 0.52, 0.52, 1.0)
			var tween := create_tween().set_loops()
			tween.set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(1.0, 0.12, 0.12, 0.82), 0.25)
			tween.tween_property(button, "modulate:a", 0.56, 0.25)
			tween.chain().set_parallel(true)
			tween.tween_property(overlay, "modulate", Color(1.0, 0.58, 0.58, 1.0), 0.25)
			tween.tween_property(button, "modulate:a", 0.2, 0.25)
			_button_tweens[device_key] = tween
		_:
			overlay.modulate = STATION_OVERLAY_IDLE
			button.modulate = Color(1.0, 1.0, 1.0, 0.0)


func _stop_button_tween(device_key: String) -> void:
	var tween := _button_tweens.get(device_key) as Tween
	if tween:
		tween.kill()
	_button_tweens.erase(device_key)
	var button := get_node_or_null(NodePath(STATION_BUTTONS.get(device_key, &""))) as TextureButton
	if button:
		button.scale = STATION_BUTTON_SCALE
	var overlay := get_node_or_null(NodePath(DEVICE_OVERLAY_NODES.get(device_key, &""))) as TextureRect
	if overlay:
		overlay.modulate = STATION_OVERLAY_IDLE
