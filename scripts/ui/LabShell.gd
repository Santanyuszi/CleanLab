class_name LabShell
extends Control
## Landscape dashboard shell (mockup layout): header, lab view, sidebar, bottom panels.

@onready var _header: HeaderBar = %HeaderBar
@onready var _sidebar: StationSidebar = %StationSidebar
@onready var _sample_queue: SampleQueuePanel = %SampleQueuePanel
@onready var _microscope_dock: MicroscopeDock = %MicroscopeDock
@onready var _escalation: EscalationPanel = %EscalationPanel
@onready var _lab_viewport: SubViewport = %LabViewport


func _ready() -> void:
	add_to_group("lab_shell")
	GameManager.economy_changed.connect(_refresh_header)
	GameManager.layer_changed.connect(_on_layer_changed)
	GameManager.delivery_completed.connect(_on_delivery)
	GameManager.problem_inspection_requested.connect(_on_problem_inspection)
	GameManager.problem_inspection_resolved.connect(_on_problem_resolved)
	_refresh_header()
	_on_layer_changed(GameManager.game_layer)
	set_hint("Drag parts between stations in the lab view.")


func get_lab_root() -> Node2D:
	return _lab_viewport.get_node("LaboratoryRoom") as Node2D


func set_hint(text: String) -> void:
	_sample_queue.set_status_line(text)


func _refresh_header() -> void:
	_header.refresh()


func _on_layer_changed(layer: GameManager.GameLayer) -> void:
	var show_dock := layer == GameManager.GameLayer.MICROSCOPY
	_microscope_dock.visible = show_dock
	_microscope_dock.set_active(show_dock)


func _on_delivery(payout: int) -> void:
	set_hint("Truck departed — +$%d. Next sample incoming." % payout)


func _on_problem_inspection(_part: Part, _claims: Array) -> void:
	set_hint("QC problem — verify particle in inspection overlay.")


func _on_problem_resolved(_part: Part, _passed: bool) -> void:
	set_hint("QC resolved. Collect report and ship to truck.")
