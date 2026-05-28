class_name ProblemInspectionPopup
extends CanvasLayer
## QC problem popup ONLY — appears sometimes after microscope; hidden otherwise.

@onready var _root: Control = $Root
@onready var _particle_view: ColorRect = $Root/Panel/Margin/VBox/ParticleView
@onready var _claim_label: Label = $Root/Panel/Margin/VBox/ClaimLabel
@onready var _approve_btn: Button = $Root/Panel/Margin/VBox/Buttons/ApproveBtn
@onready var _reject_btn: Button = $Root/Panel/Margin/VBox/Buttons/RejectBtn

var _part: Part = null
var _station: WorkStation = null
var _true_class: int = 0
var _displayed_class: int = 0


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_approve_btn.custom_minimum_size = Vector2(0, TouchInput.MIN_TOUCH_TARGET_PX)
	_reject_btn.custom_minimum_size = Vector2(0, TouchInput.MIN_TOUCH_TARGET_PX)
	GameManager.problem_inspection_requested.connect(_on_requested)


func _on_requested(part: Part, claims: Array) -> void:
	var station: WorkStation = null
	for node in get_tree().get_nodes_in_group("work_station"):
		var s: WorkStation = node as WorkStation
		if s and s.station_kind == WorkStation.Kind.MICROSCOPE and s.held_part == part:
			station = s
			break
	open(part, claims, station)


func open(part: Part, claims: Array, station: WorkStation) -> void:
	_part = part
	_station = station
	var claim: Dictionary = (claims[0] as Dictionary) if claims.size() > 0 else {}
	_true_class = int(claim.get("true_class", 0))
	_displayed_class = int(claim.get("displayed_class", 0))
	_particle_view.color = ParticleTypes.color_for(_true_class as ParticleTypes.Class)
	_claim_label.text = (
		"Particle detected\nOperator claims: %s\nApprove classification?"
		% ParticleTypes.display_name(_displayed_class as ParticleTypes.Class)
	)
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT


func _on_approve_pressed() -> void:
	_close(true)


func _on_reject_pressed() -> void:
	_close(false)


func _close(approved: bool) -> void:
	var claim_correct: bool = _displayed_class == _true_class
	var passed: bool = (approved and claim_correct) or (not approved and not claim_correct)
	if _station:
		_station.resume_after_inspection(passed)
	GameManager.leave_problem_inspection()
	GameManager.problem_inspection_resolved.emit(_part, passed)
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	_part = null
	_station = null
