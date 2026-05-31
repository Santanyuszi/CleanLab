class_name PartOrder
extends Resource
## Manufacturing order — payout and device requirements.

@export var order_id: String = "ORD-001"
@export var contract_id: String = ""
@export var part_name: String = "Sample Part"
@export var thumbnail_path: String = ""
@export var tier: int = 1
@export var payout: int = 120
@export var manufacture_cost: int = 40
@export var satisfaction_required: float = 50.0
@export var needs_extraction: bool = true
@export var needs_drying: bool = true
@export var needs_microscope: bool = true
@export var min_extraction_level: int = 1
@export var min_drying_level: int = 1
@export var min_microscope_level: int = 1
