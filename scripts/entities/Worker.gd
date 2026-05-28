class_name Worker
extends CharacterBody2D
## Mobile operator: select with tap, assign station/sample as destination.

@export var move_speed: float = 280.0
@export var interaction_range: float = 72.0
@export var tap_radius: float = 56.0

var carried_sample: Sample = null
var is_selected: bool = false

signal arrived_at_target
signal sample_attached(sample: Sample)
signal sample_detached
signal selection_changed(selected: bool)


@onready var _visual: ColorRect = $Visual
@onready var _selection_ring: ColorRect = $SelectionRing
@onready var _carry_anchor: Marker2D = $CarryAnchor

var _target_position: Vector2
var _has_move_target: bool = false
var _assignment: Node = null
var _bob_time: float = 0.0


func _ready() -> void:
	add_to_group("worker")
	deselect()


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_carry_position()
	_update_idle_animation(delta)


func select() -> void:
	is_selected = true
	_selection_ring.visible = true
	selection_changed.emit(true)


func deselect() -> void:
	is_selected = false
	_selection_ring.visible = false
	_assignment = null
	selection_changed.emit(false)


func contains_world_point(world_pos: Vector2) -> bool:
	return global_position.distance_to(world_pos) <= tap_radius


func assign_target(target: Node) -> void:
	_assignment = target
	move_to(target.global_position)


func move_to(world_position: Vector2) -> void:
	_target_position = world_position
	_has_move_target = true


func attach_sample(sample: Sample) -> void:
	carried_sample = sample
	sample_attached.emit(sample)


func detach_sample() -> Sample:
	var sample := carried_sample
	carried_sample = null
	if sample:
		sample_detached.emit()
	return sample


func _update_movement(_delta: float) -> void:
	if not _has_move_target:
		velocity = Vector2.ZERO
		return
	var offset := _target_position - global_position
	if offset.length() <= 10.0:
		_has_move_target = false
		velocity = Vector2.ZERO
		arrived_at_target.emit()
		_on_arrived_at_assignment()
		return
	velocity = offset.normalized() * move_speed
	move_and_slide()


func _on_arrived_at_assignment() -> void:
	if _assignment == null:
		return
	var target := _assignment
	_assignment = null
	if target is Sample:
		(target as Sample).interact(self)
	elif target is StationBase:
		(target as StationBase).interact(self)


func _update_carry_position() -> void:
	if carried_sample == null:
		return
	carried_sample.global_position = _carry_anchor.global_position


func _update_idle_animation(delta: float) -> void:
	_bob_time += delta
	var bob := sin(_bob_time * 8.0) * 2.0 if velocity.length() > 1.0 else sin(_bob_time * 3.0) * 0.5
	_visual.position.y = -bob
