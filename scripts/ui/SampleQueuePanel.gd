class_name SampleQueuePanel
extends PanelContainer

@onready var _list: VBoxContainer = %QueueList
@onready var _status: Label = %StatusLine


func _ready() -> void:
	GameManager.sample_queue_changed.connect(_rebuild)
	_rebuild()


func set_status_line(text: String) -> void:
	_status.text = text


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()
	for entry in GameManager.sample_queue:
		var row := Label.new()
		var display: String = entry.get("display_name", entry.get("name", "?"))
		var order_id: String = entry.get("name", "")
		var stage: String = entry.get("stage", "—")
		var next: String = entry.get("next_step", "—")
		var payout: int = int(entry.get("payout", 0))
		var priority: String = entry.get("priority", "")
		row.text = "• %s (%s)  $%d [%s]\n  %s  →  %s" % [display, order_id, payout, priority, stage, next]
		row.add_theme_font_size_override("font_size", 12)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD
		_list.add_child(row)
	if _list.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "No active orders"
		empty.add_theme_color_override("font_color", Color(0.55, 0.6, 0.68))
		_list.add_child(empty)
