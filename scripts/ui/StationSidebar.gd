class_name StationSidebar
extends PanelContainer

const ROW_KEYS: Array[String] = [
	"extraction",
	"drying",
	"microscope",
	"storage",
	"escalation",
]


@onready var _rows: Dictionary = {}


func _ready() -> void:
	for key in ROW_KEYS:
		var row: StationSidebarRow = get_node("Margin/VBox/%sRow" % _node_name_for(key))
		_rows[key] = row
		row.setup(_title_for(key))
	_rows["storage"].setup(_title_for("storage"))
	_rows["storage"].set_level(GameManager.get_device_level("storage"))
	_rows["storage"].update_status("Idle", 0.0, 0.0)
	_rows["escalation"].setup(_title_for("escalation"))
	_rows["escalation"].set_level(GameManager.get_device_level("escalation"))
	_rows["escalation"].update_status("Idle", 0.0, 0.0)
	_rows["escalation"].gui_input.connect(_on_escalation_row_input)
	await get_tree().process_frame
	_connect_stations()
	GameManager.economy_changed.connect(_refresh_levels)
	GameManager.escalation_queue_changed.connect(_refresh_escalation_row)
	_refresh_escalation_row()


func _connect_stations() -> void:
	for node in get_tree().get_nodes_in_group("work_station"):
		var station: WorkStation = node as WorkStation
		if station == null:
			continue
		station.status_changed.connect(_on_station_status)
		_on_station_status(
			station.device_key,
			station.get_ui_status(),
			station.get_ui_progress(),
			station.get_ui_time_left(),
		)


func _on_station_status(key: String, status: String, progress: float, time_left: float) -> void:
	var ui_key := key
	if key == "extraction":
		ui_key = "extraction"
	if _rows.has(ui_key):
		_rows[ui_key].update_status(status, progress, time_left)


func _refresh_levels() -> void:
	for key in ["extraction", "drying", "microscope"]:
		if _rows.has(key):
			_rows[key].set_level(GameManager.get_device_level(key))
	_refresh_escalation_row()


func _refresh_escalation_row() -> void:
	if not _rows.has("escalation"):
		return
	var row := _rows["escalation"] as StationSidebarRow
	row.set_level(GameManager.get_device_level("escalation"))
	var ticket := GameManager.get_next_escalation_ticket()
	if ticket.is_empty():
		row.update_status("No tickets", 0.0, 0.0)
		return
	var severity := int(ticket.get("severity", 1))
	var progress := clampf(1.0 - GameManager.escalation_risk, 0.0, 1.0)
	row.update_status("Tap to investigate S%d" % severity, progress, 0.0)


func _on_escalation_row_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	var resolved := GameManager.resolve_next_escalation(true)
	if resolved.is_empty():
		return


func _title_for(key: String) -> String:
	match key:
		"extraction":
			return "Washing / Extraction"
		"drying":
			return "Drying Station"
		"microscope":
			return "Microscope Station"
		"storage":
			return "Storage / Archive"
		"escalation":
			return "Escalation Desk"
	return key


func _node_name_for(key: String) -> String:
	match key:
		"extraction":
			return "Extraction"
		"escalation":
			return "Escalation"
	return key.capitalize()
