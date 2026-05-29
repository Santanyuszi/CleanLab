extends Node2D
## Kitchen-style lab floor — multiple tables, drag parts, truck payout.

@export var part_scene: PackedScene

@onready var _incoming_pad: Marker2D = %IncomingPad

var _order_counter: int = 0


func _ready() -> void:
	GameManager.start_run()
	_spawn_next_order()


func _spawn_next_order() -> void:
	_order_counter += 1
	var order_id := "PRT-%03d" % _order_counter
	var order := JobCatalog.random_order(GameManager.player_level, order_id)
	var part: Part = part_scene.instantiate()
	part.order = order
	part.global_position = _incoming_pad.global_position
	add_child(part)
	GameManager.register_part_in_queue(part)
