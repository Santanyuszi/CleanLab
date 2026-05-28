extends Node
## Management-layer input: operator authorizes incoming sample → automated pipeline.

@export var lab_root_path: NodePath = ^".."

var _lab: Node2D
var _worker: Worker = null
var _management: ManagementLayer = null
var _hud: GameHUD = null


func _ready() -> void:
	_lab = get_node(lab_root_path) as Node2D
	_worker = _lab.get_node("Worker") as Worker
	_management = _lab.get_node("ManagementLayer") as ManagementLayer
	_hud = _lab.get_node("UI/GameHUD") as GameHUD
	_worker.deselect()
	_set_hint("Tap operator, then Incoming to route the sample.")


func _unhandled_input(event: InputEvent) -> void:
	if not TouchInput.is_tap_pressed(event):
		return
	if GameManager.game_layer == GameManager.GameLayer.MICROSCOPY:
		return
	if GameManager.management_phase == GameManager.ManagementPhase.PIPELINE_ACTIVE:
		return
	var world_pos := TouchInput.screen_to_world(_lab, TouchInput.get_screen_position(event))
	_handle_tap(world_pos)
	get_viewport().set_input_as_handled()


func _handle_tap(world_pos: Vector2) -> void:
	if _worker.contains_world_point(world_pos):
		_toggle_worker_selection()
		return

	if not _worker.is_selected:
		_set_hint("Tap the operator first.")
		return

	var dock := _management.get_incoming_dock()
	if dock.contains_world_point(world_pos):
		if dock.try_accept(_worker, _management.get_pipeline()):
			_set_hint("Sample in automated prep. Microscope challenge soon.")
		else:
			_set_hint("No sample at Incoming.")
		return

	_worker.deselect()
	_set_hint("Tap operator, then Incoming.")


func _toggle_worker_selection() -> void:
	if _worker.is_selected:
		_worker.deselect()
		_set_hint("Operator deselected.")
	else:
		_worker.select()
		_set_hint("Operator ready. Tap Incoming.")


func _set_hint(text: String) -> void:
	if _hud:
		_hud.set_phase_hint(text)
