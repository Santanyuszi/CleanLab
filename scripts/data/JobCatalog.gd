class_name JobCatalog
extends RefCounted
## Catalog of available manufacturing job definitions.
## Call random_order(player_level, order_id) to spawn a contextually appropriate job.
##
## required_steps mirrors WorkStation.Kind int values:
##   0 = EXTRACTION, 1 = DRYING, 2 = MICROSCOPE, 3 = TRUCK, 4 = SEM, 5 = FTIR
## SEM and FTIR entries are data-ready for future station additions (unlock_level set high
## so they do not appear until those stations are physically present in the scene).

const _TEMPLATES: Array = [
	{
		"unlock_level": 1,
		"display_name": "Wipe Sample",
		"description": "Routine wipe test — extraction, drying, microscope.",
		"payout": 120,
		"required_steps": [0, 1, 2],
		"problem_chance": 0.25,
	},
	{
		"unlock_level": 1,
		"display_name": "Filter Membrane",
		"description": "Particle filter from clean-room assembly line.",
		"payout": 150,
		"required_steps": [0, 1, 2],
		"problem_chance": 0.30,
	},
	{
		"unlock_level": 2,
		"display_name": "Hydraulic Component",
		"description": "High-pressure hydraulic part — elevated contamination risk.",
		"payout": 200,
		"required_steps": [0, 1, 2],
		"problem_chance": 0.40,
	},
	{
		"unlock_level": 3,
		"display_name": "Precision Bearing",
		"description": "Tight-tolerance bearing — full wash/dry/microscope protocol.",
		"payout": 260,
		"required_steps": [0, 1, 2],
		"problem_chance": 0.35,
	},
	# Advanced orders below require stations not yet in the scene (unlock_level ≥ 15).
	{
		"unlock_level": 15,
		"display_name": "Aerospace Wipe",
		"description": "Aerospace component — FTIR analysis required after microscope.",
		"payout": 480,
		"required_steps": [0, 1, 2, 5],
		"problem_chance": 0.45,
	},
	{
		"unlock_level": 18,
		"display_name": "Medical Device Part",
		"description": "ISO-13485 critical part — SEM imaging required after microscope.",
		"payout": 640,
		"required_steps": [0, 1, 2, 4],
		"problem_chance": 0.50,
	},
]


## Return a new PartOrder appropriate for the given player level.
static func random_order(player_level: int, order_id: String) -> PartOrder:
	var available: Array = []
	for t in _TEMPLATES:
		if int(t["unlock_level"]) <= player_level:
			available.append(t)
	if available.is_empty():
		available = [_TEMPLATES[0]]
	var tmpl: Dictionary = available[randi() % available.size()]
	var order := PartOrder.new()
	order.order_id = order_id
	order.display_name = str(tmpl["display_name"])
	order.description = str(tmpl["description"])
	order.payout = int(tmpl["payout"])
	order.unlock_level = int(tmpl["unlock_level"])
	order.problem_chance = float(tmpl["problem_chance"])
	var steps: Array[int] = []
	for s in tmpl["required_steps"]:
		steps.append(int(s))
	order.required_steps = steps
	return order
