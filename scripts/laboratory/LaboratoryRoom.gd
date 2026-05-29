extends Node2D
## Lab floor: tap samples through stations, then send staged reports by truck.

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
	&"ReportsSlot",
	&"ReportsOutLabel",
	&"OasisLogo",
	&"OasisSub",
	&"IncomingLabel",
	&"TruckLabel",
]

@onready var _incoming_pad: Marker2D = %IncomingPad


func _ready() -> void:
	_hide_drawn_art()
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


func _hide_drawn_art() -> void:
	for node_name in DRAWN_ART_NODES:
		var node := get_node_or_null(NodePath(node_name))
		if node is CanvasItem:
			(node as CanvasItem).visible = false
