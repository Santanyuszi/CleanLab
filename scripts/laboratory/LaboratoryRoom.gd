extends Node2D
## Kitchen-style lab floor — multiple tables, drag parts, truck payout.

@export var part_scene: PackedScene

@onready var _incoming_pad: Marker2D = %IncomingPad
func _ready() -> void:
	GameManager.start_run()
	_spawn_next_order()


func _spawn_next_order() -> void:
	var part: Part = part_scene.instantiate()
	var order: PartOrder = PartOrder.new()
	order.order_id = "PRT-%03d" % randi_range(1, 999)
	order.payout = randi_range(80, 160)
	part.order = order
	part.global_position = _incoming_pad.global_position
	add_child(part)
	GameManager.register_part_in_queue(part)
