class_name Worker
extends CharacterBody2D
## Click-to-move operator. Picks up samples and delivers them to stations.

@export var move_speed: float = 220.0
@export var interaction_range: float = 48.0

var carried_sample: Sample = null

signal arrived_at_target
signal sample_attached(sample: Sample)
signal sample_detached


@onready var _visual: ColorRect = $Visual
@onready var _carry_anchor: Marker2D = $CarryAnchor

var _target_position: Vector2
var _has_move_target: bool = false
var _bob_time: float = 0.0


func _ready() -> void:
	add_to_group("worker")


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_carry_position()
	_update_idle_animation(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("click"):
		return
	var mouse_world := get_global_mouse_position()
	var interactable := _find_interactable_at(mouse_world)
	if interactable:
		interactable.interact(self)
	else:
		move_to(mouse_world)


func move_to(world_position: Vector2) -> void:
	_target_position = world_position
	_has_move_target = true


func attach_sample(sample: Sample) -> void:
	carried_sample = sample
	sample_attached.emit(sample)
	GameManager.notify_sample_picked_up()


func detach_sample() -> Sample:
	var sample := carried_sample
	carried_sample = null
	if sample:
		sample_detached.emit()
	return sample


func try_deliver_to_station(station: StationBase) -> bool:
	if carried_sample == null:
		return false
	if global_position.distance_to(station.global_position) > interaction_range:
		move_to(station.global_position)
		return false
	var sample := detach_sample()
	station.accept_sample(sample)
	return true


func _update_movement(delta: float) -> void:
	if not _has_move_target:
		velocity = Vector2.ZERO
		return
	var offset := _target_position - global_position
	if offset.length() <= 6.0:
		_has_move_target = false
		velocity = Vector2.ZERO
		arrived_at_target.emit()
		return
	velocity = offset.normalized() * move_speed
	move_and_slide()


func _update_carry_position() -> void:
	if carried_sample == null:
		return
	carried_sample.global_position = _carry_anchor.global_position


func _update_idle_animation(delta: float) -> void:
	_bob_time += delta
	var bob := sin(_bob_time * 8.0) * 2.0 if velocity.length() > 1.0 else sin(_bob_time * 3.0) * 0.5
	_visual.position.y = -bob


func _find_interactable_at(world_position: Vector2) -> Node:
	var space := get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = world_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 4 # layer 3 – interactable
	var hits := space.intersect_point(query, 8)
	for hit in hits:
		var collider: Object = hit.collider
		if collider.has_method("interact"):
			return collider as Node
	return null
