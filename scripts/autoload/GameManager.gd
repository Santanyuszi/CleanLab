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
const STARTING_MONEY := 18

var game_layer: GameLayer = GameLayer.LAB
var management_phase: ManagementPhase = ManagementPhase.WAITING_FOR_INCOMING
var player_money: int = STARTING_MONEY
var player_xp: int = 0
var player_xp_to_next: int = 140
var player_level: int = 1
var player_energy: int = 30
var player_energy_max: int = 30
var lab_reputation: float = 60.0
var contamination_trend: float = 0.35
var samples_in_lab: int = 0
var max_samples_in_lab: int = 20
var game_day: int = 1
var game_minutes: int = 480
var sample_queue: Array[Dictionary] = []
var staged_reports: Array[Dictionary] = []
var contract_offers: Array[Dictionary] = []
var challenge_offers: Array[Dictionary] = []
var active_challenges: Array[Dictionary] = []
var _last_energy_update_unix: int = 0
var _energy_recharge_timer: Timer = null

const MAX_DEVICE_LEVEL := 10
const BASE_ENERGY_MAX := 30
const ENERGY_PER_LEVEL := 5
const ENERGY_RECHARGE_SECONDS := 60.0
const CONTRACT_BREAK_SATISFACTION := 25.0
const MANUFACTURING_BUFFER_BY_TIER := {
	1: 3,
	2: 4,
	3: 5,
	4: 10,
}
const SAMPLE_ENTRY_BUFFER_CAPACITY := 10
const CONTRACT_OFFER_MIN_COUNT := 2
const CONTRACT_OFFER_MAX_COUNT := 3
const CONTRACT_OFFER_MIN_SECONDS := 10
const CONTRACT_OFFER_MAX_SECONDS := 30
const CHALLENGE_OFFER_MIN_COUNT := 2
const CHALLENGE_OFFER_MAX_COUNT := 3
const CHALLENGE_OFFER_MIN_SECONDS := 75
const CHALLENGE_OFFER_MAX_SECONDS := 180
const PART_DELIVERY_XP_BY_TIER := {
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
			"Sends trucks automatically when finished parts are ready",
		],
	},
}

var device_levels: Dictionary = {
	"extraction": 1,
	"drying": 1,
	"microscope": 1,
	"truck": 1,
	"storage": 1,
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
signal delivery_parts_completed(payout: int, parts: Array)
signal delivery_reports_completed(payout: int, reports: Array)
signal shipping_changed
signal contract_offers_changed
signal contract_accepted(contract: Dictionary)
signal contract_cancelled(order_id: String)
signal energy_changed
signal challenges_changed
signal challenge_completed(challenge: Dictionary)
signal station_completed(device_key: String)


func _ready() -> void:
	randomize()
	_start_energy_timer()


func _start_energy_timer() -> void:
	_energy_recharge_timer = Timer.new()
	_energy_recharge_timer.name = "EnergyRechargeTimer"
	_energy_recharge_timer.wait_time = ENERGY_RECHARGE_SECONDS
	_energy_recharge_timer.one_shot = false
	_energy_recharge_timer.timeout.connect(_on_energy_recharge_tick)
	add_child(_energy_recharge_timer)
	_energy_recharge_timer.start()


func _on_energy_recharge_tick() -> void:
	restore_energy(1)
	_last_energy_update_unix = int(Time.get_unix_time_from_system())


func start_run(force_reset: bool = false) -> void:
	if not force_reset and load_progress():
		refresh_contract_offers(false)
		refresh_challenge_offers(false)
		return
	game_layer = GameLayer.LAB
	management_phase = ManagementPhase.WAITING_FOR_INCOMING
	sample_queue.clear()
	staged_reports.clear()
	contract_offers.clear()
	challenge_offers.clear()
	active_challenges.clear()
	samples_in_lab = 0
	player_xp = 0
	player_xp_to_next = _xp_required_for_next_level(1)
	player_level = 1
	player_money = _min_affordable_contract_cost()
	player_energy_max = _energy_max_for_level(player_level)
	player_energy = player_energy_max
	_last_energy_update_unix = int(Time.get_unix_time_from_system())
	lab_reputation = 60.0
	game_day = 1
	game_minutes = 480
	device_levels = {
		"extraction": 1,
		"drying": 1,
		"microscope": 1,
		"truck": 1,
		"storage": 1,
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
	energy_changed.emit()
	challenges_changed.emit()
	if has_node("/root/AchievementManager"):
		AchievementManager.reset()
	refresh_contract_offers(true)
	refresh_challenge_offers(true)
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



func spend_energy(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if player_energy < amount:
		return false
	player_energy -= amount
	energy_changed.emit()
	economy_changed.emit()
	save_progress()
	return true


func has_energy(amount: int = 1) -> bool:
	return player_energy >= amount


func restore_energy(amount: int = 1) -> void:
	if amount <= 0 or player_energy >= player_energy_max:
		return
	player_energy = mini(player_energy + amount, player_energy_max)
	energy_changed.emit()
	economy_changed.emit()
	save_progress()


func _energy_max_for_level(level: int) -> int:
	return BASE_ENERGY_MAX + maxi(level - 1, 0) * ENERGY_PER_LEVEL


func _sync_energy_max(fill_new_capacity: bool = false) -> void:
	var old_max := player_energy_max
	player_energy_max = _energy_max_for_level(player_level)
	if fill_new_capacity and player_energy_max > old_max:
		player_energy += player_energy_max - old_max
	player_energy = clampi(player_energy, 0, player_energy_max)


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
	var max_expiry := now + CONTRACT_OFFER_MAX_SECONDS * 1000
	var retained: Array[Dictionary] = []
	var clamped_offer_timer := false
	for offer in contract_offers:
		var expires_at := int(offer.get("expires_at_msec", 0))
		if expires_at <= now:
			continue
		if expires_at > max_expiry:
			offer["expires_at_msec"] = now + randi_range(CONTRACT_OFFER_MIN_SECONDS, CONTRACT_OFFER_MAX_SECONDS) * 1000
			clamped_offer_timer = true
		retained.append(offer)
	var changed := retained.size() != contract_offers.size() or clamped_offer_timer
	contract_offers = retained
	if force or contract_offers.size() < CONTRACT_OFFER_MIN_COUNT:
		var available := get_available_contract_catalog()
		if available.is_empty():
			if changed or force:
				contract_offers_changed.emit()
			return
		available.shuffle()
		var target_count := randi_range(CONTRACT_OFFER_MIN_COUNT, CONTRACT_OFFER_MAX_COUNT)
		var missing_count := maxi(target_count - contract_offers.size(), 0)
		for i in missing_count:
			contract_offers.append(_build_contract_offer(available[i % available.size()]))
		changed = true
	if changed:
		contract_offers_changed.emit()


func get_contract_offers() -> Array[Dictionary]:
	return contract_offers.duplicate(true)


func can_accept_contract_offer(contract: Dictionary) -> bool:
	var batch_size := int(contract.get("batch_size", 1))
	var total_cost := int(contract.get("manufacture_cost", 0)) * batch_size
	return get_manufacturing_free_slots() >= batch_size and player_money >= total_cost


func reserve_contract_offer(contract: Dictionary) -> bool:
	var batch_size := int(contract.get("batch_size", 1))
	var total_cost := int(contract.get("manufacture_cost", 0)) * batch_size
	if get_manufacturing_free_slots() < batch_size:
		return false
	return pay_manufacture_cost(total_cost)


func accept_contract_offer(offer_id: String) -> Dictionary:
	refresh_contract_offers(false)
	for i in contract_offers.size():
		if str(contract_offers[i].get("offer_id", "")) == offer_id:
			var offer := contract_offers[i].duplicate(true)
			contract_offers.remove_at(i)
			contract_offers_changed.emit()
			return offer
	return {}


func try_accept_contract_offer(offer_id: String) -> Dictionary:
	refresh_contract_offers(false)
	for i in contract_offers.size():
		if str(contract_offers[i].get("offer_id", "")) != offer_id:
			continue
		var offer := contract_offers[i].duplicate(true)
		if not can_accept_contract_offer(offer):
			return {}
		var batch_size := int(offer.get("batch_size", 1))
		var total_cost := int(offer.get("manufacture_cost", 0)) * batch_size
		player_money -= total_cost
		contract_offers.remove_at(i)
		contract_offers_changed.emit()
		economy_changed.emit()
		save_progress()
		return offer
	return {}


func refund_contract_acceptance(contract: Dictionary) -> void:
	var batch_size := int(contract.get("batch_size", 1))
	var total_cost := int(contract.get("manufacture_cost", 0)) * batch_size
	if total_cost <= 0:
		return
	player_money += total_cost
	economy_changed.emit()
	save_progress()


func record_contract_accepted(contract: Dictionary) -> void:
	contract_accepted.emit(contract.duplicate(true))


func record_station_completed(device_key: String) -> void:
	station_completed.emit(device_key)


func get_offer_seconds_left(offer: Dictionary) -> int:
	var expires_at := int(offer.get("expires_at_msec", 0))
	var remaining := expires_at - Time.get_ticks_msec()
	return maxi(ceili(float(remaining) / 1000.0), 0)


func _market_price_multiplier() -> float:
	## 0.5 at level 1 → 1.0 at level 8 → 1.5 at level 15+
	return clampf(lerpf(0.5, 1.5, float(player_level - 1) / 14.0), 0.5, 1.5)


func _build_contract_offer(contract: Dictionary) -> Dictionary:
	var offer := contract.duplicate(true)
	var tier := int(offer.get("tier", 1))
	var price_mult := _market_price_multiplier()
	var base_cost := int(offer.get("manufacture_cost", 0))
	var cost := maxi(5, roundi(float(base_cost) * price_mult))
	var batch_size := _roll_offer_batch_size(tier)
	var margin := maxi(10, roundi(float(_roll_offer_margin(tier, batch_size)) * price_mult))
	if tier == 1:
		var safe_requirement := maxf(CONTRACT_BREAK_SATISFACTION, lab_reputation - 2.0)
		offer["satisfaction_required"] = minf(float(offer.get("satisfaction_required", 35.0)), safe_requirement)
	offer["offer_id"] = "OFFER-%d-%03d" % [Time.get_ticks_msec(), randi_range(1, 999)]
	offer["batch_size"] = batch_size
	offer["manufacture_cost"] = cost
	offer["margin"] = margin
	offer["sell_price"] = cost + margin
	offer["expires_at_msec"] = Time.get_ticks_msec() + randi_range(CONTRACT_OFFER_MIN_SECONDS, CONTRACT_OFFER_MAX_SECONDS) * 1000
	return offer


func _roll_offer_batch_size(tier: int) -> int:
	var max_batch := get_manufacturing_buffer_capacity()
	var choices: Array[int] = []
	match tier:
		1:
			choices = [1, 1, 1, 2, 3]
		2:
			choices = [1, 2, 2, 3, 4]
		3:
			choices = [2, 3, 3, 5]
		4:
			choices = [3, 5, 5, 10]
		_:
			choices = [1, 2]
	var available: Array[int] = []
	for choice in choices:
		if choice <= max_batch:
			available.append(choice)
	if available.is_empty():
		return maxi(1, max_batch)
	return available.pick_random()


func _roll_offer_margin(tier: int, batch_size: int = 1) -> int:
	var min_margin := 45
	var max_margin := 75
	match tier:
		1:
			min_margin = 55
			max_margin = 85
		2:
			min_margin = 90
			max_margin = 140
		3:
			min_margin = 150
			max_margin = 230
		4:
			min_margin = 250
			max_margin = 380
	var discount := 1.0
	if batch_size >= 10:
		discount = 0.62
	elif batch_size >= 5:
		discount = 0.72
	elif batch_size >= 3:
		discount = 0.84
	elif batch_size >= 2:
		discount = 0.92
	var reputation_factor := remap(clampf(lab_reputation, 0.0, 100.0), 0.0, 100.0, 0.82, 1.18)
	var market_noise := randf_range(0.9, 1.1)
	return maxi(25, roundi(float(randi_range(min_margin, max_margin)) * discount * reputation_factor * market_noise))


func _is_lower_margin_contract(a: Dictionary, b: Dictionary) -> bool:
	var margin_a := int(a.get("sell_price", 0)) - int(a.get("manufacture_cost", 0))
	var margin_b := int(b.get("sell_price", 0)) - int(b.get("manufacture_cost", 0))
	return margin_a < margin_b


func refresh_challenge_offers(force: bool = false) -> void:
	var now := Time.get_ticks_msec()
	var retained: Array[Dictionary] = []
	for offer in challenge_offers:
		if int(offer.get("expires_at_msec", 0)) > now:
			retained.append(offer)
	var changed := retained.size() != challenge_offers.size()
	challenge_offers = retained
	if force or challenge_offers.size() < CHALLENGE_OFFER_MIN_COUNT:
		var available := get_available_contract_catalog()
		if available.is_empty():
			if changed or force:
				challenges_changed.emit()
			return
		available.shuffle()
		var target_count := randi_range(CHALLENGE_OFFER_MIN_COUNT, CHALLENGE_OFFER_MAX_COUNT)
		var missing_count := maxi(target_count - challenge_offers.size(), 0)
		for i in missing_count:
			challenge_offers.append(_build_challenge_offer(available[i % available.size()]))
		changed = true
	if changed:
		challenges_changed.emit()


func get_challenge_offers() -> Array[Dictionary]:
	return challenge_offers.duplicate(true)


func get_active_challenges() -> Array[Dictionary]:
	return active_challenges.duplicate(true)


func get_challenge_seconds_left(challenge: Dictionary) -> int:
	var expires_at := int(challenge.get("expires_at_msec", 0))
	var remaining := expires_at - Time.get_ticks_msec()
	return maxi(ceili(float(remaining) / 1000.0), 0)


func accept_challenge_offer(challenge_id: String) -> Dictionary:
	refresh_challenge_offers(false)
	for i in challenge_offers.size():
		if str(challenge_offers[i].get("challenge_id", "")) == challenge_id:
			var challenge := challenge_offers[i].duplicate(true)
			challenge_offers.remove_at(i)
			challenge.erase("expires_at_msec")
			challenge["accepted_at_msec"] = Time.get_ticks_msec()
			challenge["progress"] = 0
			active_challenges.append(challenge)
			challenges_changed.emit()
			save_progress()
			return challenge
	return {}


func _build_challenge_offer(contract: Dictionary) -> Dictionary:
	var tier := int(contract.get("tier", 1))
	var quantity := _roll_challenge_quantity(tier)
	var margin := int(contract.get("sell_price", 0)) - int(contract.get("manufacture_cost", 0))
	return {
		"challenge_id": "CHG-%d-%03d" % [Time.get_ticks_msec(), randi_range(1, 999)],
		"contract_id": str(contract.get("id", "")),
		"part_name": str(contract.get("name", "Part")),
		"thumbnail": str(contract.get("thumbnail", "")),
		"tier": tier,
		"quantity": quantity,
		"progress": 0,
		"reward_money": maxi(40, margin * quantity + tier * 35),
		"reward_xp": roundi(float(int(PART_DELIVERY_XP_BY_TIER.get(tier, PART_DELIVERY_XP_BY_TIER[1])) * quantity) / 2.0) + tier * 15,
		"reward_energy": mini(20, 4 + quantity + tier * 2),
		"expires_at_msec": Time.get_ticks_msec() + randi_range(CHALLENGE_OFFER_MIN_SECONDS, CHALLENGE_OFFER_MAX_SECONDS) * 1000,
	}


func _roll_challenge_quantity(tier: int) -> int:
	match tier:
		1:
			return [2, 2, 3].pick_random()
		2:
			return [2, 3, 4].pick_random()
		3:
			return [3, 4, 5].pick_random()
		4:
			return [4, 5, 6].pick_random()
	return 2


func _update_challenges_for_delivery(parts: Array) -> Array[Dictionary]:
	if parts.is_empty() or active_challenges.is_empty():
		return []
	var completed: Array[Dictionary] = []
	for part in parts:
		var contract_id := str(part.get("contract_id", ""))
		if contract_id.is_empty():
			continue
		for challenge in active_challenges:
			if str(challenge.get("contract_id", "")) != contract_id:
				continue
			var progress := int(challenge.get("progress", 0)) + 1
			challenge["progress"] = mini(progress, int(challenge.get("quantity", 1)))
	for i in range(active_challenges.size() - 1, -1, -1):
		var challenge := active_challenges[i]
		if int(challenge.get("progress", 0)) < int(challenge.get("quantity", 1)):
			continue
		active_challenges.remove_at(i)
		_grant_challenge_reward(challenge)
		completed.append(challenge.duplicate(true))
		challenge_completed.emit(challenge.duplicate(true))
	if not completed.is_empty():
		challenges_changed.emit()
		save_progress()
	return completed


func _grant_challenge_reward(challenge: Dictionary) -> void:
	player_money += int(challenge.get("reward_money", 0))
	player_xp += int(challenge.get("reward_xp", 0))
	_apply_level_progress()
	restore_energy(int(challenge.get("reward_energy", 0)))


func get_contract_tier() -> int:
	if player_level < 3:
		return 1
	if player_level < 7:
		return 2
	if player_level < 12:
		return 3
	return 4


func get_manufacturing_buffer_capacity() -> int:
	return SAMPLE_ENTRY_BUFFER_CAPACITY


func has_manufacturing_capacity() -> bool:
	return samples_in_lab < get_manufacturing_buffer_capacity()


func get_manufacturing_free_slots() -> int:
	return maxi(get_manufacturing_buffer_capacity() - samples_in_lab, 0)


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
	order.display_name = str(contract.get("name", "Contract Part"))
	order.contract_id = str(contract.get("id", "contract_part"))
	order.thumbnail_path = str(contract.get("thumbnail", ""))
	order.tier = int(contract.get("tier", 1))
	order.payout = int(contract.get("sell_price", 120))
	order.manufacture_cost = int(contract.get("manufacture_cost", 40))
	order.satisfaction_required = float(contract.get("satisfaction_required", 50.0))
	var steps: Array[int] = [
		int(WorkStation.Kind.EXTRACTION),
		int(WorkStation.Kind.DRYING),
		int(WorkStation.Kind.MICROSCOPE),
	]
	order.required_steps = steps
	return order


func pay_manufacture_cost(amount: int) -> bool:
	if amount <= 0:
		return true
	if player_money < amount:
		return false
	player_money -= amount
	_guard_minimum_money()
	economy_changed.emit()
	save_progress()
	return true


func _min_affordable_contract_cost() -> int:
	var min_base := 9999
	for contract in CONTRACT_CATALOG:
		if int(contract.get("tier", 99)) <= get_contract_tier():
			min_base = mini(min_base, int(contract.get("manufacture_cost", 9999)))
	var scaled := maxi(5, roundi(float(min_base) * _market_price_multiplier()))
	return maxi(scaled, 5)


func _guard_minimum_money() -> void:
	var floor_cost := _min_affordable_contract_cost()
	if player_money < floor_cost:
		player_money = floor_cost


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


func can_stage_part() -> bool:
	return staged_reports.size() < get_truck_capacity()


func can_stage_report() -> bool:
	return can_stage_part()


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


func stage_part_for_shipping(part: Part) -> bool:
	if part == null or part.current_step != Part.Step.REPORT_READY:
		return false
	if is_order_broken(part.order.order_id):
		return false
	if not can_stage_part():
		return false
	staged_reports.append({
		"name": part.order.order_id,
		"part_name": part.order.display_name,
		"contract_id": part.order.contract_id,
		"thumbnail": part.order.thumbnail_path,
		"payout": part.order.payout,
		"tier": part.order.tier,
		"satisfaction_required": part.order.satisfaction_required,
		"manufacture_cost": part.order.manufacture_cost,
	})
	unregister_part(part.order.order_id)
	shipping_changed.emit()
	save_progress()
	return true


func stage_report_for_shipping(part: Part) -> bool:
	return stage_part_for_shipping(part)


func is_order_broken(order_id: String) -> bool:
	for entry in sample_queue:
		if entry.get("name", "") == order_id:
			return bool(entry.get("broken", false))
	return false


func get_staged_part_count() -> int:
	return staged_reports.size()


func get_staged_report_count() -> int:
	return get_staged_part_count()


func get_staged_part_total() -> int:
	var total := 0
	for part in staged_reports:
		total += int(part.get("payout", 0))
	return total


func get_staged_report_total() -> int:
	return get_staged_part_total()


func send_truck() -> int:
	if staged_reports.is_empty():
		return 0
	var payout := get_staged_part_total()
	var delivered_parts := staged_reports.duplicate(true)
	staged_reports.clear()
	complete_delivery(payout, delivered_parts)
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


func complete_delivery(payout: int, delivered_parts: Array = []) -> void:
	player_money += payout
	player_xp += _delivery_xp_for_parts(delivered_parts, payout)
	_apply_level_progress()
	lab_reputation = clampf(lab_reputation + 3.0, 0.0, 100.0)
	game_minutes += 3
	_update_challenges_for_delivery(delivered_parts)
	_check_contract_breaks()
	economy_changed.emit()
	sample_queue_changed.emit()
	energy_changed.emit()
	challenges_changed.emit()
	delivery_parts_completed.emit(payout, delivered_parts)
	delivery_reports_completed.emit(payout, delivered_parts)
	delivery_completed.emit(payout)
	save_progress()


func _delivery_xp_for_parts(delivered_parts: Array, payout: int) -> int:
	if delivered_parts.is_empty():
		return maxi(floori(float(payout) / 6.0), PART_DELIVERY_XP_BY_TIER[1])
	var xp := 0
	for part in delivered_parts:
		var tier := int(part.get("tier", 1))
		xp += int(PART_DELIVERY_XP_BY_TIER.get(tier, PART_DELIVERY_XP_BY_TIER[1]))
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
		sample_queue_changed.emit()


func _apply_level_progress() -> void:
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = _xp_required_for_next_level(player_level)
		_sync_energy_max(true)


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
		"player_energy": player_energy,
		"player_energy_max": player_energy_max,
		"last_energy_update_unix": _last_energy_update_unix,
		"lab_reputation": lab_reputation,
		"contamination_trend": contamination_trend,
		"samples_in_lab": samples_in_lab,
		"max_samples_in_lab": max_samples_in_lab,
		"game_day": game_day,
		"game_minutes": game_minutes,
		"sample_queue": sample_queue.duplicate(true),
		"staged_reports": staged_reports.duplicate(true),
		"contract_offers": contract_offers.duplicate(true),
		"challenge_offers": challenge_offers.duplicate(true),
		"active_challenges": active_challenges.duplicate(true),
		"device_levels": device_levels.duplicate(true),
		"device_owned": device_owned.duplicate(true),
		"personnel_levels": personnel_levels.duplicate(true),
		"personnel_employed": personnel_employed.duplicate(true),
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
	var text := file.get_as_text()
	if text.strip_edges().is_empty():
		return false
	var json := JSON.new()
	if json.parse(text) != OK:
		return false
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed
	player_money = int(data.get("player_money", STARTING_MONEY))
	player_xp = max(0, int(data.get("player_xp", 0)))
	player_xp_to_next = max(1, int(data.get("player_xp_to_next", _xp_required_for_next_level(1))))
	player_level = max(1, int(data.get("player_level", 1)))
	player_energy_max = max(BASE_ENERGY_MAX, int(data.get("player_energy_max", _energy_max_for_level(player_level))))
	player_energy = clampi(int(data.get("player_energy", player_energy_max)), 0, player_energy_max)
	_last_energy_update_unix = max(0, int(data.get("last_energy_update_unix", Time.get_unix_time_from_system())))
	lab_reputation = clampf(float(data.get("lab_reputation", 60.0)), 0.0, 100.0)
	contamination_trend = clampf(float(data.get("contamination_trend", 0.35)), 0.0, 1.0)
	samples_in_lab = max(0, int(data.get("samples_in_lab", 0)))
	max_samples_in_lab = max(1, int(data.get("max_samples_in_lab", 20)))
	game_day = max(1, int(data.get("game_day", 1)))
	game_minutes = max(0, int(data.get("game_minutes", 480)))
	sample_queue = _as_dictionary_array(data.get("sample_queue", []))
	staged_reports = _as_dictionary_array(data.get("staged_reports", []))
	contract_offers = _as_dictionary_array(data.get("contract_offers", []))
	_sanitize_contract_offers()
	challenge_offers = _as_dictionary_array(data.get("challenge_offers", []))
	active_challenges = _as_dictionary_array(data.get("active_challenges", []))
	_sanitize_challenges()
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
	_clear_unspawned_in_progress_samples()
	_sync_energy_max(false)
	_apply_offline_energy_recharge()
	layer_changed.emit(game_layer)
	management_phase_changed.emit(management_phase)
	economy_changed.emit()
	sample_queue_changed.emit()
	shipping_changed.emit()
	energy_changed.emit()
	challenges_changed.emit()
	save_progress()
	return true


func _as_dictionary_array(value: Variant) -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return output
	for entry in value:
		if typeof(entry) == TYPE_DICTIONARY:
			output.append((entry as Dictionary).duplicate(true))
	return output


func _sanitize_contract_offers() -> void:
	var now := Time.get_ticks_msec()
	var max_expiry := now + CONTRACT_OFFER_MAX_SECONDS * 1000
	var sanitized: Array[Dictionary] = []
	for offer in contract_offers:
		var expires_at := int(offer.get("expires_at_msec", 0))
		if expires_at <= now:
			continue
		if expires_at > max_expiry:
			offer["expires_at_msec"] = now + randi_range(CONTRACT_OFFER_MIN_SECONDS, CONTRACT_OFFER_MAX_SECONDS) * 1000
		if not offer.has("offer_id") or str(offer.get("offer_id", "")).is_empty():
			offer["offer_id"] = "OFFER-%d-%03d" % [now, randi_range(1, 999)]
		sanitized.append(offer)
	contract_offers = sanitized


func _sanitize_challenges() -> void:
	var now := Time.get_ticks_msec()
	var sanitized_offers: Array[Dictionary] = []
	for offer in challenge_offers:
		if int(offer.get("expires_at_msec", 0)) > now:
			sanitized_offers.append(offer)
	challenge_offers = sanitized_offers

	var sanitized_active: Array[Dictionary] = []
	for challenge in active_challenges:
		var quantity := maxi(1, int(challenge.get("quantity", 1)))
		challenge["quantity"] = quantity
		challenge["progress"] = clampi(int(challenge.get("progress", 0)), 0, quantity)
		if str(challenge.get("contract_id", "")).is_empty():
			continue
		sanitized_active.append(challenge)
	active_challenges = sanitized_active


func _apply_offline_energy_recharge() -> void:
	var now := int(Time.get_unix_time_from_system())
	if _last_energy_update_unix <= 0:
		_last_energy_update_unix = now
		return
	if player_energy >= player_energy_max:
		_last_energy_update_unix = now
		return
	var elapsed := maxi(now - _last_energy_update_unix, 0)
	var gained := floori(float(elapsed) / ENERGY_RECHARGE_SECONDS)
	_energy_recharge_accumulator = fmod(float(elapsed), ENERGY_RECHARGE_SECONDS)
	if gained > 0:
		player_energy = mini(player_energy + gained, player_energy_max)
	_last_energy_update_unix = now


func _sanitize_progression_state() -> void:
	for key in device_levels.keys():
		if not DEVICE_CATALOG.has(str(key)):
			device_levels.erase(key)
	for key in device_owned.keys():
		if not DEVICE_CATALOG.has(str(key)):
			device_owned.erase(key)
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


func _clear_unspawned_in_progress_samples() -> void:
	if sample_queue.is_empty():
		return
	sample_queue.clear()
	samples_in_lab = 0
