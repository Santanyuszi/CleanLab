class_name PartOrder
extends Resource
## Manufacturing order — recipe chain, payout, and device requirements.

@export var order_id: String = "ORD-001"
@export var display_name: String = "Sample"
@export var description: String = ""
@export var payout: int = 120
@export var unlock_level: int = 1
## Ordered sequence of WorkStation.Kind int values this part must visit before the truck.
@export var required_steps: Array[int] = []
## Chance a QC problem triggers at the microscope step (0 = never, 1 = always).
@export var problem_chance: float = 0.35
