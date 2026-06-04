extends Node2D
## Lab floor: tap samples through stations, then send finished parts by truck.

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
	&"PartsOutSlot",
	&"PartsOutLabel",
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

const PERSONNEL_OVERLAY_NODES := {
	"labor_worker": &"HumanExtractionOverlay",
	"lab_manager": &"HumanMicroscopeOverlay",
}

const STATION_BUTTONS := {
	"extraction": &"StationButtons/ExtractionButton",
	"drying": &"StationButtons/OvenButton",
	"microscope": &"StationButtons/MicroscopeButton",
}

const TRUCK_BUTTON_PATH := "res://assets/ui/CleanLab_TruckButton.png"
const LAB_ART_SIZE := Vector2(1508.0, 1043.0)
const STATION_BUTTON_SCALE := Vector2(2.35, 2.35)
const STATION_OVERLAY_IDLE := Color(1.0, 1.0, 1.0, 1.0)

@onready var _incoming_pad: Marker2D = %IncomingPad

var _order_counter: int = 0
var _button_tweens: Dictionary = {}
var _button_states: Dictionary = {}
var _personnel_tweens: Dictionary = {}
var _personnel_energy_blocked: bool = false
var _automation_tick: float = 0.0
var _auto_contract_tick: float = 0.0
var _auto_truck_tick: float = 0.0
var _truck_overlay_button: TextureButton = null
var _truck_count_label: Label = null
var _truck_overlay_tween: Tween = null


func _ready() -> void:
	add_to_group("laboratory_room")
	_hide_drawn_art()
	_add_truck_overlay_button()
	_refresh_device_overlays()
	_refresh_personnel_overlays()
	_connect_station_buttons()
	GameManager.device_changed.connect(_on_device_changed)
	GameManager.personnel_changed.connect(_on_personnel_changed)
	GameManager.energy_changed.connect(_refresh_personnel_overlays)
	GameManager.shipping_changed.connect(_refresh_truck_overlay_button)
	GameManager.start_run()
	_refresh_personnel_overlays()


func _process(delta: float) -> void:
	_fit_art_to_viewport()
	_automation_tick += delta
	_auto_contract_tick += delta
	_auto_truck_tick += delta
	if _automation_tick >= 0.35:
		_automation_tick = 0.0
		_run_personnel_routing()
	if _auto_contract_tick >= 3.0:
		_auto_contract_tick = 0.0
		_try_auto_accept_contract()
	if _auto_truck_tick >= 2.0:
		_auto_truck_tick = 0.0
		_try_auto_send_truck()


func _fit_art_to_viewport() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var fit_scale := maxf(viewport_size.x / LAB_ART_SIZE.x, viewport_size.y / LAB_ART_SIZE.y)
	var target_scale := Vector2(fit_scale, fit_scale)
	var target_position := ((viewport_size - LAB_ART_SIZE * fit_scale) * 0.5).floor()
	if scale.distance_to(target_scale) > 0.001:
		scale = target_scale
	if position.distance_to(target_position) > 0.5:
		position = target_position


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


func return_part_to_drop_area(part: Part) -> void:
	if part == null:
		return
	part.reset_to_incoming()
	GameManager.update_queue_stage(part.order.order_id, "Revision returned")
	part.drop_to(_incoming_pad.global_position)


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


func _spawn_next_order() -> void:
	_order_counter += 1
	var order_id := "PRT-%03d" % _order_counter
	var order := JobCatalog.random_order(GameManager.player_level, order_id)
	_spawn_order(order)


func _spawn_order(order: PartOrder) -> void:
	if not GameManager.has_manufacturing_capacity():
		return
	var part: Part = part_scene.instantiate()
	part.order = order
	var drop_target := _incoming_pad.global_position + Vector2(randf_range(-8.0, 8.0), randf_range(-6.0, 6.0))
	part.global_position = drop_target
	add_child(part)
	part.drop_to(drop_target)
	GameManager.register_part_in_queue(part)


func _run_personnel_routing() -> void:
	if GameManager.game_layer != GameManager.GameLayer.LAB:
		return
	if not GameManager.has_energy(1):
		_set_personnel_energy_blocked(true)
		return
	_set_personnel_energy_blocked(false)
	var labor_level := GameManager.get_personnel_level("labor_worker") if GameManager.is_personnel_employed("labor_worker") else 0
	var manager_level := GameManager.get_personnel_level("lab_manager") if GameManager.is_personnel_employed("lab_manager") else 0
	if labor_level >= 1 or manager_level >= 2:
		if _try_route_loose_part(Part.Step.INCOMING, WorkStation.Kind.EXTRACTION):
			return
	if labor_level >= 2:
		if _try_route_ready_station(WorkStation.Kind.EXTRACTION, WorkStation.Kind.DRYING):
			return
	if labor_level >= 3:
		if _try_route_ready_station(WorkStation.Kind.DRYING, WorkStation.Kind.MICROSCOPE):
			return


func _try_auto_accept_contract() -> void:
	if not GameManager.is_personnel_employed("lab_manager") or GameManager.get_personnel_level("lab_manager") < 1:
		return
	if not GameManager.has_energy(1):
		return
	if GameManager.get_manufacturing_free_slots() <= 0:
		return
	GameManager.refresh_contract_offers(false)
	var offers := GameManager.get_contract_offers()
	if offers.is_empty():
		GameManager.refresh_contract_offers(true)
		offers = GameManager.get_contract_offers()
	offers.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("margin", 0)) > int(b.get("margin", 0))
	)
	for offer in offers:
		var batch_size := int(offer.get("batch_size", 1))
		if batch_size > GameManager.get_manufacturing_free_slots():
			continue
		if not GameManager.can_accept_contract_offer(offer):
			continue
		var accepted := GameManager.try_accept_contract_offer(str(offer.get("offer_id", "")))
		if accepted.is_empty():
			continue
		if not GameManager.spend_energy(1):
			GameManager.refund_contract_acceptance(accepted)
			GameManager.refresh_contract_offers(true)
			return
		var spawned := spawn_contract_batch(accepted)
		if spawned <= 0:
			GameManager.refund_contract_acceptance(accepted)
			GameManager.refresh_contract_offers(true)
			return
		GameManager.record_contract_accepted(accepted)
		return


func _try_auto_send_truck() -> void:
	if not GameManager.is_personnel_employed("lab_manager") or GameManager.get_personnel_level("lab_manager") < 3:
		return
	if GameManager.get_staged_part_count() <= 0:
		return
	if not GameManager.spend_energy(1):
		return
	GameManager.send_truck()


func _add_truck_overlay_button() -> void:
	if has_node("TruckOverlayButton"):
		return
	var texture := _texture_from_png(TRUCK_BUTTON_PATH)
	if texture == null:
		return
	var button := TextureButton.new()
	button.name = "TruckOverlayButton"
	button.offset_right = 1508.0
	button.offset_bottom = 1043.0
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.texture_click_mask = _make_alpha_click_mask(TRUCK_BUTTON_PATH)
	button.pressed.connect(_on_truck_overlay_pressed)
	_truck_overlay_button = button
	add_child(button)
	_add_truck_count_label()
	_refresh_truck_overlay_button()


func _on_truck_overlay_pressed() -> void:
	var payout := GameManager.send_truck()
	var shell := get_tree().get_first_node_in_group("lab_shell") as LabShell
	if shell == null:
		return
	if payout > 0:
		shell.set_hint("Truck sent. Payment received: $%s." % _format_money(payout))
	else:
		shell.set_hint("Load a finished part before sending the truck.")


func _refresh_truck_overlay_button() -> void:
	if _truck_overlay_button == null and _truck_count_label == null:
		return
	var staged_count := GameManager.get_staged_part_count()
	var capacity := GameManager.get_truck_capacity()
	var has_parts := staged_count > 0
	if _truck_overlay_button:
		_truck_overlay_button.disabled = not has_parts
		_refresh_truck_overlay_pulse(has_parts)
	if _truck_count_label:
		_truck_count_label.text = "%d/%d" % [staged_count, capacity]
		_truck_count_label.visible = has_parts
		_truck_count_label.modulate = Color(1.0, 1.0, 1.0, 1.0 if has_parts else 0.0)


func _refresh_truck_overlay_pulse(has_parts: bool) -> void:
	if _truck_overlay_tween:
		_truck_overlay_tween.kill()
		_truck_overlay_tween = null
	if _truck_overlay_button == null:
		return
	if not has_parts:
		_truck_overlay_button.modulate = Color(1.0, 1.0, 1.0, 0.0)
		return
	_truck_overlay_button.modulate = Color.WHITE
	_truck_overlay_tween = create_tween().set_loops()
	_truck_overlay_tween.tween_property(_truck_overlay_button, "modulate:a", 0.62, 0.55)
	_truck_overlay_tween.tween_property(_truck_overlay_button, "modulate:a", 1.0, 0.55)


func _add_truck_count_label() -> void:
	if _truck_count_label != null:
		return
	var label := Label.new()
	label.name = "TruckPartCount"
	label.position = Vector2(1359, 484)
	label.size = Vector2(90, 30)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#002121"))
	label.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.74))
	label.add_theme_constant_override("outline_size", 4)
	_truck_count_label = label
	add_child(label)


func _make_alpha_click_mask(path: String) -> BitMap:
	var image := _image_from_png(path)
	if image == null:
		return null
	var mask := BitMap.new()
	mask.create_from_image_alpha(image, 0.1)
	return mask


func _texture_from_png(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var imported_texture := load(path) as Texture2D
		if imported_texture:
			return imported_texture
	return null


func _image_from_png(path: String) -> Image:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var imported_texture := load(path) as Texture2D
		if imported_texture:
			return imported_texture.get_image()
	return null


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]


func _try_route_loose_part(step: Part.Step, target_kind: WorkStation.Kind) -> bool:
	var station := _station_for_kind(target_kind)
	if station == null:
		return false
	for node in get_tree().get_nodes_in_group("draggable_part"):
		var part := node as Part
		if part == null or part.is_on_station or part.current_step != step:
			continue
		return _move_part_to_station(part, station)
	return false


func _try_route_ready_station(from_kind: WorkStation.Kind, target_kind: WorkStation.Kind) -> bool:
	var from_station := _station_for_kind(from_kind)
	var target_station := _station_for_kind(target_kind)
	if from_station == null or target_station == null or not from_station.can_pick_up():
		return false
	if not GameManager.has_energy(1):
		return false
	var part := from_station.pick_up()
	return _move_part_to_station(part, target_station)


func _move_part_to_station(part: Part, station: WorkStation) -> bool:
	if part == null or station == null or not station.can_accept_part(part):
		return false
	if not GameManager.spend_energy(1):
		return false
	var from_pos := part.global_position
	if not station.try_accept_part(part):
		return false
	var target_pos := part.global_position
	part.global_position = from_pos
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(part, "global_position", target_pos, 0.24)
	return true


func _station_for_kind(kind: WorkStation.Kind) -> WorkStation:
	for node in get_tree().get_nodes_in_group("work_station"):
		var station := node as WorkStation
		if station and station.station_kind == kind:
			return station
	return null


func _hide_drawn_art() -> void:
	for node_name in DRAWN_ART_NODES:
		var node := get_node_or_null(NodePath(node_name))
		if node is CanvasItem:
			(node as CanvasItem).visible = false


func _on_device_changed(_device_key: String) -> void:
	_refresh_device_overlays()


func _on_personnel_changed(_personnel_key: String) -> void:
	_refresh_personnel_overlays()


func _refresh_device_overlays() -> void:
	for device_key in DEVICE_OVERLAY_NODES:
		var node := get_node_or_null(NodePath(DEVICE_OVERLAY_NODES[device_key]))
		if node is CanvasItem:
			(node as CanvasItem).visible = GameManager.is_device_owned(device_key)
	for device_key in STATION_BUTTONS:
		var button := get_node_or_null(NodePath(STATION_BUTTONS[device_key])) as TextureButton
		if button:
			button.visible = GameManager.is_device_owned(device_key)


func _refresh_personnel_overlays() -> void:
	var blocked := _has_employed_personnel() and not GameManager.has_energy(1)
	_set_personnel_energy_blocked(blocked)
	for personnel_key in PERSONNEL_OVERLAY_NODES:
		var node := get_node_or_null(NodePath(PERSONNEL_OVERLAY_NODES[personnel_key]))
		if node is CanvasItem:
			(node as CanvasItem).visible = GameManager.is_personnel_employed(personnel_key)
			_apply_personnel_overlay_state(personnel_key, node as CanvasItem, blocked)


func _has_employed_personnel() -> bool:
	for personnel_key in PERSONNEL_OVERLAY_NODES:
		if GameManager.is_personnel_employed(personnel_key):
			return true
	return false


func _set_personnel_energy_blocked(blocked: bool) -> void:
	if _personnel_energy_blocked == blocked:
		return
	_personnel_energy_blocked = blocked
	for personnel_key in PERSONNEL_OVERLAY_NODES:
		var node := get_node_or_null(NodePath(PERSONNEL_OVERLAY_NODES[personnel_key]))
		if node is CanvasItem:
			_apply_personnel_overlay_state(personnel_key, node as CanvasItem, blocked)


func _apply_personnel_overlay_state(personnel_key: String, node: CanvasItem, blocked: bool) -> void:
	var employed := GameManager.is_personnel_employed(personnel_key)
	if not employed:
		node.modulate = Color.WHITE
		_stop_personnel_tween(personnel_key)
		return
	if not blocked:
		node.modulate = Color.WHITE
		_stop_personnel_tween(personnel_key)
		return
	if _personnel_tweens.has(personnel_key):
		return
	node.modulate = Color(1.0, 0.38, 0.34, 0.92)
	var tween := create_tween().set_loops()
	tween.tween_property(node, "modulate", Color(1.0, 0.2, 0.16, 0.58), 0.45)
	tween.tween_property(node, "modulate", Color(1.0, 0.42, 0.36, 0.96), 0.45)
	_personnel_tweens[personnel_key] = tween


func _stop_personnel_tween(personnel_key: String) -> void:
	if not _personnel_tweens.has(personnel_key):
		return
	var tween := _personnel_tweens[personnel_key] as Tween
	if tween:
		tween.kill()
	_personnel_tweens.erase(personnel_key)


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
