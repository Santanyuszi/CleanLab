class_name PartOrder
extends Resource
## Manufacturing order — payout and device requirements.

@export var order_id: String = "ORD-001"
@export var payout: int = 120
@export var needs_extraction: bool = true
@export var needs_drying: bool = true
@export var needs_microscope: bool = true
@export var min_extraction_level: int = 1
@export var min_drying_level: int = 1
@export var min_microscope_level: int = 1
