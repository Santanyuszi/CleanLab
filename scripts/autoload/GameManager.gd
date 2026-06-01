extends Node
## Global economy, layers, and sample queue.

enum GameLayer {
	LAB,
	MICROSCOPY,
	PROBLEM_INSPECTION,
}

enum ManagementPhase {
	WAITING_FOR_INCOMING,
	PIPELINE_ACTIVE,
	MICROSCOPE_ACTIVE,
}

const MINIGAME_PROBLEM_CHANCE: float = 0.0
const SAVE_PATH := "user://cleanlab_save_v1.json"

var game_layer: GameLayer = GameLayer.LAB
var management_phase: ManagementPhase = ManagementPhase.WAITING_FOR_INCOMING
var player_money: int = 220
var player_xp: int = 0
var player_xp_to_next: int = 140
var player_level: int = 1
var lab_reputation: float = 60.0
var contamination_trend: float = 0.35
var escalation_risk: float = 0.45
var alert_count: int = 0
var samples_in_lab: int = 0
var max_samples_in_lab: int = 20
var game_day: int = 1
var game_minutes: int = 480
var pending_ftir_count: int = 0
var sample_queue: Array[Dictionary] = []
var staged_reports: Array[Dictionary] = []
var contract_offers: Array[Dictionary] = []
var escalation_tickets: Array[Dictionary] = []

const MAX_DEVICE_LEVEL := 10
const CONTRACT_BREAK_SATISFACTION := 25.0
const MANUFACTURING_BUFFER_BY_TIER := {
	1: 3,
	2: 4,
	3: 5,
	4: 10,
}
const CONTRACT_OFFER_MIN_COUNT := 1
const CONTRACT_OFFER_MAX_COUNT := 2
const CONTRACT_OFFER_MIN_SECONDS := 55
const CONTRACT_OFFER_MAX_SECONDS := 130
const REPORT_XP_BY_TIER := {
	1: 70,
	2: 120,
	3: 190,
	4: 300,
}
const XP_TO_NEXT_BY_LEVEL := {
	1: 140,
	2: 210,
	3: 300,
}
const CONTRACT_CATALOG: Array[Dictionary] = [
	{
		"id": "door_lock_actuator",
		"name": "Door Lock Actuator",
		"tier": 1,
		"sell_price": 95,
		"manufacture_cost": 35,
		"satisfaction_required": 35.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_DoorLockActuator.png",
		"description": "Standard actuator assembly component.",
	},
	{
		"id": "sensor_module",
		"name": "Sensor Module",
		"tier": 2,
		"sell_price": 155,
		"manufacture_cost": 62,
		"satisfaction_required": 54.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_SensorModule.png",
		"description": "Electronic sensor module sensitive to contamination.",
	},
	{
		"id": "connector_module",
		"name": "Connector Module",
		"tier": 2,
		"sell_price": 145,
		"manufacture_cost": 58,
		"satisfaction_required": 48.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_ConnectorTerminal.png",
		"description": "Electrical connector module requiring particle control.",
	},
	{
		"id": "aluminum_ecu_housing",
		"name": "Aluminum ECU Housing",
		"tier": 2,
		"sell_price": 180,
		"manufacture_cost": 74,
		"satisfaction_required": 62.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_ECUHousing.png",
		"description": "Electronic control unit housing sensitive to particles.",
	},
	{
		"id": "egr_valve",
		"name": "EGR Valve",
		"tier": 2,
		"sell_price": 170,
		"manufacture_cost": 69,
		"satisfaction_required": 58.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_EGRValve.png",
		"description": "Exhaust gas recirculation valve component.",
	},
	{
		"id": "injector_valve",
		"name": "Injector Valve",
		"tier": 3,
		"sell_price": 260,
		"manufacture_cost": 118,
		"satisfaction_required": 72.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_InjectorVALVE.png",
		"description": "Precision fuel injector component with fine channels.",
	},
	{
		"id": "gear_component",
		"name": "Gear Component",
		"tier": 3,
		"sell_price": 285,
		"manufacture_cost": 132,
		"satisfaction_required": 78.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_GearComponent.png",
		"description": "Critical transmission gear component.",
	},
	{
		"id": "piston",
		"name": "Piston",
		"tier": 3,
		"sell_price": 245,
		"manufacture_cost": 110,
		"satisfaction_required": 66.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_Piston.png",
		"description": "Engine piston requiring clean oil passages.",
	},
	{
		"id": "bearing_race",
		"name": "Bearing Race",
		"tier": 3,
		"sell_price": 230,
		"manufacture_cost": 105,
		"satisfaction_required": 62.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_Bearing.png",
		"description": "Precision bearing surface with strict cleanliness.",
	},
	{
		"id": "brake_caliper",
		"name": "Brake Caliper",
		"tier": 3,
		"sell_price": 275,
		"manufacture_cost": 130,
		"satisfaction_required": 76.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_BrakeCaliper.png",
		"description": "Brake caliper component with hydraulic passages.",
	},
	{
		"id": "steering_rack_part",
		"name": "Steering Rack Part",
		"tier": 3,
		"sell_price": 255,
		"manufacture_cost": 122,
		"satisfaction_required": 70.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_SteeringRack.png",
		"description": "Steering system component requiring cleanliness.",
	},
	{
		"id": "fuel_pump_component",
		"name": "Fuel Pump Component",
		"tier": 3,
		"sell_price": 265,
		"manufacture_cost": 126,
		"satisfaction_required": 74.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_FuelPump.png",
		"description": "Fuel pump part requiring clean fluid passages.",
	},
	{
		"id": "transmission_solenoid",
		"name": "Transmission Solenoid",
		"tier": 2,
		"sell_price": 165,
		"manufacture_cost": 70,
		"satisfaction_required": 56.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_TransmissionSolenoid.png",
		"description": "Transmission solenoid valve component.",
	},
	{
		"id": "ev_battery_housing",
		"name": "EV Battery Housing",
		"tier": 4,
		"sell_price": 520,
		"manufacture_cost": 265,
		"satisfaction_required": 88.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_EVBatteryHousing.png",
		"description": "High-value EV component requiring strict cleanliness.",
	},
	{
		"id": "hydraulic_valve_body",
		"name": "Hydraulic Valve Body",
		"tier": 4,
		"sell_price": 475,
		"manufacture_cost": 240,
		"satisfaction_required": 82.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_HydraulicValveBody.png",
		"description": "Complex hydraulic control component with tight tolerances.",
	},
	{
		"id": "turbocharger_part",
		"name": "Turbocharger Part",
		"tier": 4,
		"sell_price": 540,
		"manufacture_cost": 280,
		"satisfaction_required": 92.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_TurboChargerPart.png",
		"description": "Turbocharger component with high precision.",
	},
	{
		"id": "camshaft",
		"name": "Camshaft",
		"tier": 4,
		"sell_price": 490,
		"manufacture_cost": 250,
		"satisfaction_required": 84.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_CamShaft.png",
		"description": "Engine camshaft requiring strict cleanliness.",
	},
	{
		"id": "cylinder_head_part",
		"name": "Cylinder Head Part",
		"tier": 4,
		"sell_price": 560,
		"manufacture_cost": 295,
		"satisfaction_required": 94.0,
		"thumbnail": "res://assets/contracts/ImageDataSet_CleanLab_CylinderHeadPart.png",
		"description": "Cylinder head component with multiple passages.",
	},
]
const DEVICE_CATALOG: Dictionary = {
	"extraction": {
		"title": "Extraction Machine",
		"kind": "Extraction machine",
		"max_level": 4,
		"purchase_cost": 0,
		"upgrade_costs": [0, 260, 700, 1500],
		"level_requirements": [1, 2, 4, 7],
	},
	"drying": {
		"title": "Drying Oven",
		"kind": "Drying oven",
		"max_level": 4,
		"purchase_cost": 0,
		"upgrade_costs": [0, 220, 620, 1350],
		"level_requirements": [1, 2, 4, 7],
	},
	"microscope": {
		"title": "Microscope",
		"kind": "Microscope",
		"max_level": 4,
		"purchase_cost": 0,
		"upgrade_costs": [0, 320, 850, 1800],
		"level_requirements": [1, 3, 5, 8],
	},
	"truck": {
		"title": "Truck Capacity",
		"kind": "Shipping",
		"max_level": 10,
		"purchase_cost": 0,
		"upgrade_costs": [0, 160, 360, 650, 1050, 1600, 2350, 3350, 4650, 6300],
		"level_requirements": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	},
}
const PERSONNEL_CATALOG: Dictionary = {
	"labor_worker": {
		"title": "Labor Worker",
		"kind": "Personnel",
		"max_level": 3,
		"upgrade_costs": [180, 520, 1100],
		"employ_cost": 95,
		"level_requirements": [2, 4, 7],
		"phase_text": [
			"Routes incoming samples to extraction",
			"Moves extracted samples to drying oven",
			"Moves dried samples to microscope analysis",
		],
	},
	"lab_manager": {
		"title": "Lab Manager",
		"kind": "Personnel",
		"max_level": 3,
		"upgrade_costs": [420, 900, 1750],
		"employ_cost": 180,
		"level_requirements": [3, 5, 8],
		"phase_text": [
			"Accepts suitable contracts automatically",
			"Supervises entry-to-extraction routing",
			"Sends trucks automatically when reports are ready",
		],
	},
}

var device_levels: Dictionary = {
	"extraction": 1,
	"drying": 1,
	"microscope": 1,
	"truck": 1,
	"storage": 1,
	"escalation": 1,
}

var device_owned: Dictionary = {
	"extraction": true,
	"drying": true,
	"microscope": true,
	"truck": true,
}
var personnel_levels: Dictionary = {
	"labor_worker": 0,
	"lab_manager": 0,
}
var personnel_employed: Dictionary = {
	"labor_worker": false,
	"lab_manager": false,
}

signal layer_changed(layer: GameLayer)
signal management_phase_changed(phase: ManagementPhase)
signal economy_changed
signal sample_queue_changed
signal device_changed(device_key: String)
signal personnel_changed(personnel_key: String)
signal problem_inspection_requested(part: Part, claims: Array)
signal problem_inspection_resolved(part: Part, approved: bool)
signal microscope_session_started(part: Part)
signal microscopy_results_applied(summary: Dictionary)
signal delivery_completed(payout: int)
signal delivery_reports_completed(payout: int, reports: Array)
signal shipping_changed
signal contract_offers_changed
signal contract_accepted(contract: Dictionary)
signal contract_cancelled(order_id: String)
signal station_completed(device_key: String)
signal microscope_minigame_requested(sample: Node)
signal escalation_queue_changed


func _ready() -> void:
	randomize()


func start_run(force_reset: bool = false) -> void:
	if not force_reset and load_progress():
		refresh_contract_offers(false)
		return
	game_layer = GameLayer.LAB
	management_phase = ManagementPhase.WAITING_FOR_INCOMING
	sample_queue.clear()
	staged_reports.clear()
	contract_offers.clear()
	escalation_tickets.clear()
	samples_in_lab = 0
	player_money = 220
	player_xp = 0
	player_xp_to_next = _xp_required_for_next_level(1)
	player_level = 1
	lab_reputation = 60.0
	alert_count = 0
	game_day = 1
	game_minutes = 480
	device_levels = {
		"extraction": 1,
		"drying": 1,
		"microscope": 1,
		"truck": 1,
		"storage": 1,
		"escalation": 1,
	}
	device_owned = {
		"extraction": true,
		"drying": true,
		"microscope": true,
		"truck": true,
	}
	personnel_levels = {
		"labor_worker": 0,
		"lab_manager": 0,
	}
	personnel_employed = {
		"labor_worker": false,
		"lab_manager": false,
	}
	layer_changed.emit(game_layer)
	management_phase_changed.emit(management_phase)
	economy_changed.emit()
	sample_queue_changed.emit()
	shipping_changed.emit()
	escalation_queue_changed.emit()
	if has_node("/root/AchievementManager"):
		AchievementManager.reset()
	refresh_contract_offers(true)
	save_progress()


func start_prototype_run() -> void:
	start_run(false)
	set_management_phase(ManagementPhase.WAITING_FOR_INCOMING)


func set_management_phase(phase: ManagementPhase) -> void:
	if management_phase == phase:
		return
	management_phase = phase
	management_phase_changed.emit(management_phase)


func register_incoming_sample(_sample: Node) -> void:
	if management_phase != ManagementPhase.PIPELINE_ACTIVE:
		set_management_phase(ManagementPhase.WAITING_FOR_INCOMING)


func notify_station_processing_started(_station_type: String) -> void:
	if management_phase != ManagementPhase.MICROSCOPE_ACTIVE:
		set_management_phase(ManagementPhase.PIPELINE_ACTIVE)


func notify_station_processing_complete(station_type: String) -> void:
	if station_type == "microscope":
		set_management_phase(ManagementPhase.MICROSCOPE_ACTIVE)


func request_microscope_minigame(sample: Node) -> void:
	if sample == null:
		return
	set_management_phase(ManagementPhase.MICROSCOPE_ACTIVE)
	var connections := get_signal_connection_list("microscope_minigame_requested")
	if connections.is_empty():
		apply_microscopy_results({
			"score": 90,
			"accuracy": 0.78,
			"avg_speed": 1.7,
			"ftir_flags": 0,
			"wrong": 0,
			"classified": 1,
		})
		return
	microscope_minigame_requested.emit(sample)


func apply_reputation_delta(delta: float) -> void:
	update_reputation(delta)


func get_time_string() -> String:
	var h: int = floori(game_minutes / 60.0)
	var m: int = game_minutes % 60
	return "%02d:%02d" % [h, m]


func get_device_level(device_key: String) -> int:
	return int(device_levels.get(device_key, 1))


func is_device_owned(device_key: String) -> bool:
	return bool(device_owned.get(device_key, false))


func process_time_for(device_key: String, base_seconds: float) -> float:
	var level: int = get_device_level(device_key)
	return maxf(base_seconds / (1.0 + (level - 1) * 0.18), 1.0)


func is_device_unlocked(device_key: String, required_level: int) -> bool:
	return is_device_owned(device_key) and get_device_level(device_key) >= required_level


func get_device_catalog() -> Dictionary:
	return DEVICE_CATALOG.duplicate(true)


func get_personnel_catalog() -> Dictionary:
	return PERSONNEL_CATALOG.duplicate(true)


func get_personnel_level(personnel_key: String) -> int:
	return int(personnel_levels.get(personnel_key, 0))


func is_personnel_employed(personnel_key: String) -> bool:
	return bool(personnel_employed.get(personnel_key, false))


func get_personnel_max_level(personnel_key: String) -> int:
	var data: Dictionary = PERSONNEL_CATALOG.get(personnel_key, {})
	return int(data.get("max_level", 3))


func get_personnel_upgrade_cost(personnel_key: String) -> int:
	var level := get_personnel_level(personnel_key)
	if level >= get_personnel_max_level(personnel_key):
		return 0
	var data: Dictionary = PERSONNEL_CATALOG.get(personnel_key, {})
	var costs: Array = data.get("upgrade_costs", [])
	if level >= costs.size():
		return 0
	return int(costs[level])


func get_personnel_upgrade_required_player_level(personnel_key: String) -> int:
	var level := get_personnel_level(personnel_key)
	var data: Dictionary = PERSONNEL_CATALOG.get(personnel_key, {})
	var requirements: Array = data.get("level_requirements", [])
	if level >= requirements.size():
		return level + 2
	return int(requirements[level])


func get_personnel_employ_cost(personnel_key: String) -> int:
	var data: Dictionary = PERSONNEL_CATALOG.get(personnel_key, {})
	return int(data.get("employ_cost", 0))


func can_upgrade_personnel_by_level(personnel_key: String) -> bool:
	return player_level >= get_personnel_upgrade_required_player_level(personnel_key)


func upgrade_personnel(personnel_key: String) -> bool:
	if not PERSONNEL_CATALOG.has(personnel_key):
		return false
	var level := get_personnel_level(personnel_key)
	if level >= get_personnel_max_level(personnel_key):
		return false
	if not can_upgrade_personnel_by_level(personnel_key):
		return false
	var cost := get_personnel_upgrade_cost(personnel_key)
	if player_money < cost:
		return false
	player_money -= cost
	personnel_levels[personnel_key] = level + 1
	economy_changed.emit()
	personnel_changed.emit(personnel_key)
	save_progress()
	return true


func employ_personnel(personnel_key: String) -> bool:
	if not PERSONNEL_CATALOG.has(personnel_key):
		return false
	if is_personnel_employed(personnel_key):
		return false
	if get_personnel_level(personnel_key) <= 0:
		return false
	var cost := get_personnel_employ_cost(personnel_key)
	if player_money < cost:
		return false
	player_money -= cost
	personnel_employed[personnel_key] = true
	economy_changed.emit()
	personnel_changed.emit(personnel_key)
	save_progress()
	return true


func fire_personnel(personnel_key: String) -> bool:
	if not is_personnel_employed(personnel_key):
		return false
	personnel_employed[personnel_key] = false
	personnel_changed.emit(personnel_key)
	save_progress()
	return true


func get_device_max_level(device_key: String) -> int:
	var data: Dictionary = DEVICE_CATALOG.get(device_key, {})
	return int(data.get("max_level", 4))


func get_device_upgrade_required_player_level(device_key: String) -> int:
	var level := get_device_level(device_key)
	var data: Dictionary = DEVICE_CATALOG.get(device_key, {})
	var requirements: Array = data.get("level_requirements", [])
	if level >= requirements.size():
		return level + 1
	return int(requirements[level])


func can_upgrade_device_by_level(device_key: String) -> bool:
	return player_level >= get_device_upgrade_required_player_level(device_key)


func get_contract_catalog() -> Array[Dictionary]:
	return CONTRACT_CATALOG.duplicate(true)


func get_available_contract_catalog() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var fallback: Dictionary = {}
	var tier := get_contract_tier()
	for contract in CONTRACT_CATALOG:
		if int(contract.get("tier", 1)) > tier:
			continue
		if fallback.is_empty() or _is_lower_margin_contract(contract, fallback):
			fallback = contract
		if float(contract.get("satisfaction_required", 0.0)) > lab_reputation:
			continue
		available.append(contract.duplicate(true))
	if available.is_empty() and not fallback.is_empty():
		available.append(fallback.duplicate(true))
	return available


func refresh_contract_offers(force: bool = false) -> void:
	var now := Time.get_ticks_msec()
	var retained: Array[Dictionary] = []
	for offer in contract_offers:
		if int(offer.get("expires_at_msec", 0)) > now:
			retained.append(offer)
	var changed := retained.size() != contract_offers.size()
	contract_offers = retained
	if force or contract_offers.is_empty():
		var available := get_available_contract_catalog()
		if available.is_empty():
			if changed or force:
				contract_offers_changed.emit()
			return
		available.shuffle()
		var target_count := randi_range(CONTRACT_OFFER_MIN_COUNT, CONTRACT_OFFER_MAX_COUNT)
		target_count = mini(target_count, available.size())
		for i in target_count:
			contract_offers.append(_build_contract_offer(available[i]))
		changed = true
	if changed:
		contract_offers_changed.emit()
		save_progress()


func get_contract_offers() -> Array[Dictionary]:
	return contract_offers.duplicate(true)


func accept_contract_offer(offer_id: String) -> Dictionary:
	refresh_contract_offers(false)
	for i in contract_offers.size():
		if str(contract_offers[i].get("offer_id", "")) == offer_id:
			var offer := contract_offers[i].duplicate(true)
			contract_offers.remove_at(i)
			contract_offers_changed.emit()
			return offer
	return {}


func record_contract_accepted(contract: Dictionary) -> void:
	contract_accepted.emit(contract.duplicate(true))


func record_station_completed(device_key: String) -> void:
	station_completed.emit(device_key)


func get_offer_seconds_left(offer: Dictionary) -> int:
	var expires_at := int(offer.get("expires_at_msec", 0))
	var remaining := expires_at - Time.get_ticks_msec()
	return maxi(ceili(float(remaining) / 1000.0), 0)


func _build_contract_offer(contract: Dictionary) -> Dictionary:
	var offer := contract.duplicate(true)
	var tier := int(offer.get("tier", 1))
	var cost := int(offer.get("manufacture_cost", 0))
	var batch_size := _roll_offer_batch_size(tier)
	var margin := _roll_offer_margin(tier)
	if tier == 1:
		var safe_requirement := maxf(CONTRACT_BREAK_SATISFACTION, lab_reputation - 2.0)
		offer["satisfaction_required"] = minf(float(offer.get("satisfaction_required", 35.0)), safe_requirement)
	offer["offer_id"] = "OFFER-%d-%03d" % [Time.get_ticks_msec(), randi_range(1, 999)]
	offer["batch_size"] = batch_size
	offer["margin"] = margin
	offer["sell_price"] = cost + margin
	offer["expires_at_msec"] = Time.get_ticks_msec() + randi_range(CONTRACT_OFFER_MIN_SECONDS, CONTRACT_OFFER_MAX_SECONDS) * 1000
	return offer


func _roll_offer_batch_size(tier: int) -> int:
	var max_batch := mini(get_manufacturing_buffer_capacity(), tier + 1)
	if tier == 1:
		return 2 if randf() < 0.25 and max_batch >= 2 else 1
	return randi_range(1, max_batch)


func _roll_offer_margin(tier: int) -> int:
	match tier:
		1:
			return randi_range(55, 85)
		2:
			return randi_range(90, 140)
		3:
			return randi_range(150, 230)
		4:
			return randi_range(250, 380)
	return randi_range(45, 75)


func _is_lower_margin_contract(a: Dictionary, b: Dictionary) -> bool:
	var margin_a := int(a.get("sell_price", 0)) - int(a.get("manufacture_cost", 0))
	var margin_b := int(b.get("sell_price", 0)) - int(b.get("manufacture_cost", 0))
	return margin_a < margin_b


func get_contract_tier() -> int:
	if player_level < 3:
		return 1
	if player_level < 7:
		return 2
	if player_level < 12:
		return 3
	return 4


func get_manufacturing_buffer_capacity() -> int:
	var tier := get_contract_tier()
	return int(MANUFACTURING_BUFFER_BY_TIER.get(tier, 3))


func has_manufacturing_capacity() -> bool:
	return samples_in_lab < get_manufacturing_buffer_capacity()


func get_manufacturing_free_slots() -> int:
	return maxi(get_manufacturing_buffer_capacity() - samples_in_lab, 0)


func get_escalation_tickets() -> Array[Dictionary]:
	return escalation_tickets.duplicate(true)


func get_next_escalation_ticket() -> Dictionary:
	if escalation_tickets.is_empty():
		return {}
	return escalation_tickets[0].duplicate(true)


func queue_escalation_ticket(title: String, severity: int, reward: int, penalty: float) -> Dictionary:
	var ticket := {
		"id": "ESC-%d-%03d" % [Time.get_ticks_msec(), randi_range(1, 999)],
		"title": title,
		"severity": clampi(severity, 1, 4),
		"reward": maxi(reward, 0),
		"penalty": maxf(penalty, 0.0),
		"created_at_msec": Time.get_ticks_msec(),
	}
	escalation_tickets.append(ticket)
	alert_count = escalation_tickets.size()
	escalation_risk = clampf(escalation_risk + 0.03 * float(int(ticket.get("severity", 1))), 0.05, 0.98)
	escalation_queue_changed.emit()
	economy_changed.emit()
	save_progress()
	return ticket.duplicate(true)


func resolve_next_escalation(success: bool) -> Dictionary:
	if escalation_tickets.is_empty():
		return {}
	var ticket := escalation_tickets.pop_front()
	var severity := int(ticket.get("severity", 1))
	if success:
		var reward := int(ticket.get("reward", 0))
		player_money += reward
		lab_reputation = clampf(lab_reputation + float(severity) * 0.6, 0.0, 100.0)
		escalation_risk = clampf(escalation_risk - 0.06 * float(severity), 0.02, 0.98)
		ticket["resolved"] = "success"
	else:
		var penalty := float(ticket.get("penalty", 1.0))
		lab_reputation = clampf(lab_reputation - penalty, 0.0, 100.0)
		escalation_risk = clampf(escalation_risk + 0.04 * float(severity), 0.02, 0.98)
		ticket["resolved"] = "failed"
	alert_count = escalation_tickets.size()
	_check_contract_breaks()
	escalation_queue_changed.emit()
	economy_changed.emit()
	sample_queue_changed.emit()
	save_progress()
	return ticket


func update_reputation(delta: float) -> void:
	lab_reputation = clampf(lab_reputation + delta, 0.0, 100.0)
	_check_contract_breaks()
	economy_changed.emit()
	sample_queue_changed.emit()
	save_progress()


func apply_manufacturing_halt_penalty() -> void:
	update_reputation(-2.5)


func create_order_from_contract(contract: Dictionary) -> PartOrder:
	var order := PartOrder.new()
	order.order_id = "CTR-%03d" % randi_range(1, 999)
	order.part_name = str(contract.get("name", "Contract Part"))
	order.contract_id = str(contract.get("id", "contract_part"))
	order.thumbnail_path = str(contract.get("thumbnail", ""))
	order.tier = int(contract.get("tier", 1))
	order.payout = int(contract.get("sell_price", 120))
	order.manufacture_cost = int(contract.get("manufacture_cost", 40))
	order.satisfaction_required = float(contract.get("satisfaction_required", 50.0))
	order.min_extraction_level = clampi(order.tier - 1, 1, MAX_DEVICE_LEVEL)
	order.min_drying_level = 1
	order.min_microscope_level = clampi(order.tier, 1, MAX_DEVICE_LEVEL)
	return order


func pay_manufacture_cost(amount: int) -> bool:
	if amount <= 0:
		return true
	if player_money < amount:
		return false
	player_money -= amount
	economy_changed.emit()
	save_progress()
	return true


func get_device_purchase_cost(device_key: String) -> int:
	var data: Dictionary = DEVICE_CATALOG.get(device_key, {})
	return int(data.get("purchase_cost", 0))


func get_device_upgrade_cost(device_key: String) -> int:
	var level := get_device_level(device_key)
	if level >= get_device_max_level(device_key):
		return 0
	var data: Dictionary = DEVICE_CATALOG.get(device_key, {})
	var costs: Array = data.get("upgrade_costs", [])
	if level >= costs.size():
		return 0
	return int(costs[level])


func purchase_device(device_key: String) -> bool:
	if is_device_owned(device_key):
		return false
	var cost := get_device_purchase_cost(device_key)
	if player_money < cost:
		return false
	player_money -= cost
	device_owned[device_key] = true
	device_levels[device_key] = max(1, get_device_level(device_key))
	economy_changed.emit()
	device_changed.emit(device_key)
	save_progress()
	return true


func upgrade_device(device_key: String) -> bool:
	if not is_device_owned(device_key):
		return false
	var level := get_device_level(device_key)
	if level >= get_device_max_level(device_key):
		return false
	if not can_upgrade_device_by_level(device_key):
		return false
	var cost := get_device_upgrade_cost(device_key)
	if player_money < cost:
		return false
	player_money -= cost
	device_levels[device_key] = level + 1
	economy_changed.emit()
	device_changed.emit(device_key)
	save_progress()
	return true


func get_station_capacity(device_key: String) -> int:
	match device_key:
		"extraction", "drying", "microscope":
			return clampi(get_device_level(device_key), 1, get_device_max_level(device_key))
	return 1


func get_truck_capacity() -> int:
	return clampi(get_device_level("truck"), 1, get_device_max_level("truck"))


func can_stage_report() -> bool:
	return staged_reports.size() < get_truck_capacity()


func register_part_in_queue(part: Part) -> void:
	samples_in_lab += 1
	sample_queue.append({
		"name": part.order.order_id,
		"display_name": part.order.display_name,
		"stage": "Incoming",
		"next_step": part.next_station_name(),
		"payout": part.order.payout,
		"priority": _priority_for_payout(part.order.payout),
		"broken": false,
		"manufacture_cost": part.order.manufacture_cost,
		"satisfaction_required": part.order.satisfaction_required,
	})
	sample_queue_changed.emit()
	save_progress()


func _priority_for_payout(payout: int) -> String:
	if payout >= 300:
		return "High"
	if payout >= 175:
		return "Medium"
	return "Low"


func update_queue_stage(part_id: String, stage: String) -> void:
	for entry in sample_queue:
		if entry.get("name", "") == part_id:
			entry["stage"] = stage
	sample_queue_changed.emit()


func update_queue_for_part(part: Part, stage: String) -> void:
	var part_id := part.order.order_id
	for entry in sample_queue:
		if entry.get("name", "") == part_id:
			entry["stage"] = stage
			entry["next_step"] = part.next_station_name()
	sample_queue_changed.emit()


func unregister_part(part_id: String) -> void:
	for i in sample_queue.size():
		if sample_queue[i].get("name", "") == part_id:
			sample_queue.remove_at(i)
			break
	samples_in_lab = maxi(samples_in_lab - 1, 0)
	sample_queue_changed.emit()
	save_progress()


func cancel_active_contract(order_id: String) -> bool:
	for entry in sample_queue:
		if entry.get("name", "") != order_id:
			continue
		var refund := roundi(float(entry.get("manufacture_cost", 0)) * 0.5)
		player_money += refund
		lab_reputation = clampf(lab_reputation - 1.0, 0.0, 100.0)
		unregister_part(order_id)
		economy_changed.emit()
		contract_cancelled.emit(order_id)
		save_progress()
		return true
	return false


func stage_report_for_shipping(part: Part) -> bool:
	if part == null or part.current_step != Part.Step.REPORT_READY:
		return false
	if is_order_broken(part.order.order_id):
		return false
	if not can_stage_report():
		return false
	staged_reports.append({
		"name": part.order.order_id,
		"payout": part.order.payout,
		"tier": part.order.tier,
		"satisfaction_required": part.order.satisfaction_required,
		"manufacture_cost": part.order.manufacture_cost,
	})
	unregister_part(part.order.order_id)
	shipping_changed.emit()
	save_progress()
	return true


func is_order_broken(order_id: String) -> bool:
	for entry in sample_queue:
		if entry.get("name", "") == order_id:
			return bool(entry.get("broken", false))
	return false


func get_staged_report_count() -> int:
	return staged_reports.size()


func get_staged_report_total() -> int:
	var total := 0
	for report in staged_reports:
		total += int(report.get("payout", 0))
	return total


func send_truck() -> int:
	if staged_reports.is_empty():
		return 0
	var payout := get_staged_report_total()
	var delivered_reports := staged_reports.duplicate(true)
	staged_reports.clear()
	complete_delivery(payout, delivered_reports)
	shipping_changed.emit()
	save_progress()
	return payout


func start_microscope_session(part: Part) -> void:
	game_layer = GameLayer.MICROSCOPY
	set_management_phase(ManagementPhase.MICROSCOPE_ACTIVE)
	layer_changed.emit(game_layer)
	microscope_session_started.emit(part)


func enter_problem_inspection(part: Part, claims: Array) -> void:
	if game_layer == GameLayer.PROBLEM_INSPECTION:
		return
	game_layer = GameLayer.PROBLEM_INSPECTION
	layer_changed.emit(game_layer)
	problem_inspection_requested.emit(part, claims)


func leave_problem_inspection() -> void:
	game_layer = GameLayer.LAB
	layer_changed.emit(game_layer)


func resolve_problem_inspection(part: Part, approved: bool) -> void:
	problem_inspection_resolved.emit(part, approved)


func complete_delivery(payout: int, delivered_reports: Array = []) -> void:
	player_money += payout
	player_xp += _delivery_xp_for_reports(delivered_reports, payout)
	_apply_level_progress()
	lab_reputation = clampf(lab_reputation + 3.0, 0.0, 100.0)
	game_minutes += 3
	_check_contract_breaks()
	economy_changed.emit()
	sample_queue_changed.emit()
	delivery_reports_completed.emit(payout, delivered_reports)
	delivery_completed.emit(payout)
	save_progress()


func _delivery_xp_for_reports(delivered_reports: Array, payout: int) -> int:
	if delivered_reports.is_empty():
		return maxi(floori(float(payout) / 6.0), REPORT_XP_BY_TIER[1])
	var xp := 0
	for report in delivered_reports:
		var tier := int(report.get("tier", 1))
		xp += int(REPORT_XP_BY_TIER.get(tier, REPORT_XP_BY_TIER[1]))
	return xp


func _check_contract_breaks() -> void:
	var raised := false
	for entry in sample_queue:
		if bool(entry.get("broken", false)):
			continue
		var required := float(entry.get("satisfaction_required", 0.0))
		if lab_reputation < required or lab_reputation < CONTRACT_BREAK_SATISFACTION:
			entry["broken"] = true
			entry["stage"] = "Contract broken"
			raised = true
	if raised:
		queue_escalation_ticket("Contract break investigation", 2, 18, 2.0)


func _apply_level_progress() -> void:
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = _xp_required_for_next_level(player_level)


func _xp_required_for_next_level(level: int) -> int:
	if XP_TO_NEXT_BY_LEVEL.has(level):
		return int(XP_TO_NEXT_BY_LEVEL[level])
	var xp := int(XP_TO_NEXT_BY_LEVEL[3])
	for _i in range(4, level + 1):
		xp = floori(float(xp) * 1.32)
	return xp


func apply_inspection_penalty() -> void:
	var penalty := 1.5 if player_level < 4 else 3.5
	lab_reputation = clampf(lab_reputation - penalty, 0.0, 100.0)
	queue_escalation_ticket("QC mismatch escalation", 2, 14, penalty)
	economy_changed.emit()
	save_progress()


func apply_reputation_delta(delta: float) -> void:
	lab_reputation = clampf(lab_reputation + delta, 0.0, 100.0)
	economy_changed.emit()


func apply_microscopy_results(summary: Dictionary) -> void:
	var score: int = int(summary.get("score", 0))
	var accuracy: float = float(summary.get("accuracy", 0.0))
	var wrong: int = int(summary.get("wrong", 0))
	var xp_gain := mini(floori(float(score) / 14.0) + int(accuracy * 14.0), 24)
	var payout := mini(floori(float(score) / 7.0) + int(accuracy * 4.0), 26)
	player_xp += xp_gain
	player_money += payout
	lab_reputation = clampf(lab_reputation + (accuracy - 0.45) * 4.0 - float(wrong) * 0.35, 0.0, 100.0)
	if wrong > 0 or accuracy < 0.6:
		var severity := 1 if accuracy >= 0.55 else 2
		queue_escalation_ticket("Microscope discrepancy follow-up", severity, 10 + severity * 4, 1.5 + float(severity))
	_apply_level_progress()
	_check_contract_breaks()
	game_layer = GameLayer.LAB
	set_management_phase(ManagementPhase.WAITING_FOR_INCOMING)
	layer_changed.emit(game_layer)
	economy_changed.emit()
	sample_queue_changed.emit()
	microscopy_results_applied.emit(summary)
	save_progress()


func save_progress() -> bool:
	var payload := {
		"player_money": player_money,
		"player_xp": player_xp,
		"player_xp_to_next": player_xp_to_next,
		"player_level": player_level,
		"lab_reputation": lab_reputation,
		"contamination_trend": contamination_trend,
		"escalation_risk": escalation_risk,
		"alert_count": alert_count,
		"samples_in_lab": samples_in_lab,
		"max_samples_in_lab": max_samples_in_lab,
		"game_day": game_day,
		"game_minutes": game_minutes,
		"pending_ftir_count": pending_ftir_count,
		"sample_queue": sample_queue.duplicate(true),
		"staged_reports": staged_reports.duplicate(true),
		"contract_offers": contract_offers.duplicate(true),
		"device_levels": device_levels.duplicate(true),
		"device_owned": device_owned.duplicate(true),
		"personnel_levels": personnel_levels.duplicate(true),
		"personnel_employed": personnel_employed.duplicate(true),
		"escalation_tickets": escalation_tickets.duplicate(true),
		"game_layer": int(game_layer),
		"management_phase": int(management_phase),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload))
	return true


func load_progress() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed := JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	player_money = int(data.get("player_money", 220))
	player_xp = max(0, int(data.get("player_xp", 0)))
	player_xp_to_next = max(1, int(data.get("player_xp_to_next", _xp_required_for_next_level(1))))
	player_level = max(1, int(data.get("player_level", 1)))
	lab_reputation = clampf(float(data.get("lab_reputation", 60.0)), 0.0, 100.0)
	contamination_trend = clampf(float(data.get("contamination_trend", 0.35)), 0.0, 1.0)
	escalation_risk = clampf(float(data.get("escalation_risk", 0.45)), 0.02, 0.98)
	alert_count = max(0, int(data.get("alert_count", 0)))
	samples_in_lab = max(0, int(data.get("samples_in_lab", 0)))
	max_samples_in_lab = max(1, int(data.get("max_samples_in_lab", 20)))
	game_day = max(1, int(data.get("game_day", 1)))
	game_minutes = max(0, int(data.get("game_minutes", 480)))
	pending_ftir_count = max(0, int(data.get("pending_ftir_count", 0)))
	sample_queue = _as_dictionary_array(data.get("sample_queue", []))
	staged_reports = _as_dictionary_array(data.get("staged_reports", []))
	contract_offers = _as_dictionary_array(data.get("contract_offers", []))
	escalation_tickets = _as_dictionary_array(data.get("escalation_tickets", []))
	device_levels = (data.get("device_levels", device_levels) as Dictionary).duplicate(true)
	device_owned = (data.get("device_owned", device_owned) as Dictionary).duplicate(true)
	personnel_levels = (data.get("personnel_levels", personnel_levels) as Dictionary).duplicate(true)
	personnel_employed = (data.get("personnel_employed", personnel_employed) as Dictionary).duplicate(true)
	game_layer = clampi(int(data.get("game_layer", int(GameLayer.LAB))), int(GameLayer.LAB), int(GameLayer.PROBLEM_INSPECTION))
	management_phase = clampi(
		int(data.get("management_phase", int(ManagementPhase.WAITING_FOR_INCOMING))),
		int(ManagementPhase.WAITING_FOR_INCOMING),
		int(ManagementPhase.MICROSCOPE_ACTIVE)
	)
	_sanitize_progression_state()
	layer_changed.emit(game_layer)
	management_phase_changed.emit(management_phase)
	economy_changed.emit()
	sample_queue_changed.emit()
	shipping_changed.emit()
	escalation_queue_changed.emit()
	return true


func _as_dictionary_array(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for entry in value:
		if typeof(entry) == TYPE_DICTIONARY:
			output.append((entry as Dictionary).duplicate(true))
	return output


func _sanitize_progression_state() -> void:
	for key in DEVICE_CATALOG.keys():
		if not device_levels.has(key):
			device_levels[key] = 1
		device_levels[key] = clampi(int(device_levels[key]), 1, get_device_max_level(str(key)))
		if not device_owned.has(key):
			device_owned[key] = key in ["extraction", "drying", "microscope", "truck"]
	for key in PERSONNEL_CATALOG.keys():
		if not personnel_levels.has(key):
			personnel_levels[key] = 0
		if not personnel_employed.has(key):
			personnel_employed[key] = false
		var max_level := get_personnel_max_level(str(key))
		personnel_levels[key] = clampi(int(personnel_levels[key]), 0, max_level)
		if int(personnel_levels[key]) <= 0:
			personnel_employed[key] = false
	samples_in_lab = sample_queue.size()
	alert_count = escalation_tickets.size()
