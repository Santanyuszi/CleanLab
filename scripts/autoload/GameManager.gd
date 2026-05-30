extends Node
## Global economy, layers, and sample queue.

enum GameLayer {
	LAB,
	MICROSCOPY,
	PROBLEM_INSPECTION,
}

const MINIGAME_PROBLEM_CHANCE: float = 0.35

var game_layer: GameLayer = GameLayer.LAB
var player_money: int = 450
var player_xp: int = 0
var player_xp_to_next: int = 500
var player_level: int = 1
var lab_reputation: float = 55.0
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
		"upgrade_costs": [0, 1200, 2800, 5200],
		"level_requirements": [1, 2, 4, 7],
	},
	"drying": {
		"title": "Drying Oven",
		"kind": "Drying oven",
		"max_level": 4,
		"purchase_cost": 0,
		"upgrade_costs": [0, 900, 2100, 4400],
		"level_requirements": [1, 2, 4, 7],
	},
	"microscope": {
		"title": "Microscope",
		"kind": "Microscope",
		"max_level": 4,
		"purchase_cost": 0,
		"upgrade_costs": [0, 1600, 3600, 6800],
		"level_requirements": [1, 3, 5, 8],
	},
	"truck": {
		"title": "Truck Capacity",
		"kind": "Shipping",
		"max_level": 10,
		"purchase_cost": 0,
		"upgrade_costs": [0, 350, 700, 1200, 1800, 2600, 3600, 4800, 6200, 8000],
		"level_requirements": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
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

signal layer_changed(layer: GameLayer)
signal economy_changed
signal sample_queue_changed
signal device_changed(device_key: String)
signal problem_inspection_requested(part: Part, claims: Array)
signal problem_inspection_resolved(part: Part, approved: bool)
signal microscope_session_started(part: Part)
signal microscopy_results_applied(summary: Dictionary)
signal delivery_completed(payout: int)
signal shipping_changed
signal contract_offers_changed


func start_run() -> void:
	game_layer = GameLayer.LAB
	sample_queue.clear()
	staged_reports.clear()
	contract_offers.clear()
	samples_in_lab = 0
	player_money = 450
	player_xp = 0
	player_xp_to_next = 500
	player_level = 1
	lab_reputation = 55.0
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
	layer_changed.emit(game_layer)
	economy_changed.emit()
	sample_queue_changed.emit()
	shipping_changed.emit()
	refresh_contract_offers(true)


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


func get_offer_seconds_left(offer: Dictionary) -> int:
	var expires_at := int(offer.get("expires_at_msec", 0))
	var remaining := expires_at - Time.get_ticks_msec()
	return maxi(ceili(float(remaining) / 1000.0), 0)


func _build_contract_offer(contract: Dictionary) -> Dictionary:
	var offer := contract.duplicate(true)
	var required_reputation := float(offer.get("satisfaction_required", 35.0))
	var tier := int(offer.get("tier", 1))
	var cost := int(offer.get("manufacture_cost", 0))
	var batch_size := randi_range(1, mini(get_manufacturing_buffer_capacity(), tier + 1))
	var margin_multiplier := randf_range(0.9, 1.25)
	var margin := maxi(roundi(required_reputation * tier * margin_multiplier), 10)
	offer["offer_id"] = "OFFER-%d-%03d" % [Time.get_ticks_msec(), randi_range(1, 999)]
	offer["batch_size"] = batch_size
	offer["margin"] = margin
	offer["sell_price"] = cost + margin
	offer["expires_at_msec"] = Time.get_ticks_msec() + randi_range(CONTRACT_OFFER_MIN_SECONDS, CONTRACT_OFFER_MAX_SECONDS) * 1000
	return offer


func _is_lower_margin_contract(a: Dictionary, b: Dictionary) -> bool:
	var margin_a := int(a.get("sell_price", 0)) - int(a.get("manufacture_cost", 0))
	var margin_b := int(b.get("sell_price", 0)) - int(b.get("manufacture_cost", 0))
	return margin_a < margin_b


func get_contract_tier() -> int:
	if player_level < 4:
		return 1
	if player_level < 8:
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


func update_reputation(delta: float) -> void:
	lab_reputation = clampf(lab_reputation + delta, 0.0, 100.0)
	_check_contract_breaks()
	economy_changed.emit()
	sample_queue_changed.emit()


func apply_manufacturing_halt_penalty() -> void:
	update_reputation(-2.5)


func create_order_from_contract(contract: Dictionary) -> PartOrder:
	var order := PartOrder.new()
	order.order_id = "CTR-%03d" % randi_range(1, 999)
	order.part_name = str(contract.get("name", "Contract Part"))
	order.contract_id = str(contract.get("id", "contract_part"))
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
		"part_name": part.order.part_name,
		"stage": "Incoming",
		"priority": "Tier %d" % part.order.tier,
		"satisfaction_required": part.order.satisfaction_required,
		"manufacture_cost": part.order.manufacture_cost,
		"payout": part.order.payout,
		"broken": false,
	})
	sample_queue_changed.emit()


func update_queue_stage(part_id: String, stage: String) -> void:
	for entry in sample_queue:
		if entry.get("name", "") == part_id:
			entry["stage"] = stage
	sample_queue_changed.emit()


func unregister_part(part_id: String) -> void:
	for i in sample_queue.size():
		if sample_queue[i].get("name", "") == part_id:
			sample_queue.remove_at(i)
			break
	samples_in_lab = maxi(samples_in_lab - 1, 0)
	sample_queue_changed.emit()


func cancel_active_contract(order_id: String) -> bool:
	for entry in sample_queue:
		if entry.get("name", "") != order_id:
			continue
		var refund := roundi(float(entry.get("manufacture_cost", 0)) * 0.5)
		player_money += refund
		lab_reputation = clampf(lab_reputation - 1.0, 0.0, 100.0)
		unregister_part(order_id)
		economy_changed.emit()
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
		"satisfaction_required": part.order.satisfaction_required,
	})
	unregister_part(part.order.order_id)
	shipping_changed.emit()
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
	staged_reports.clear()
	complete_delivery(payout)
	shipping_changed.emit()
	return payout


func start_microscope_session(part: Part) -> void:
	game_layer = GameLayer.MICROSCOPY
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


func complete_delivery(payout: int) -> void:
	player_money += payout
	player_xp += floori(payout / 5.0)
	_apply_level_progress()
	lab_reputation = clampf(lab_reputation + 3.0, 0.0, 100.0)
	game_minutes += 3
	_check_contract_breaks()
	economy_changed.emit()
	sample_queue_changed.emit()
	delivery_completed.emit(payout)


func _check_contract_breaks() -> void:
	for entry in sample_queue:
		if bool(entry.get("broken", false)):
			continue
		var required := float(entry.get("satisfaction_required", 0.0))
		if lab_reputation < required or lab_reputation < CONTRACT_BREAK_SATISFACTION:
			entry["broken"] = true
			entry["stage"] = "Contract broken"
			alert_count += 1


func _apply_level_progress() -> void:
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = floori(float(player_xp_to_next) * 1.35)


func apply_inspection_penalty() -> void:
	lab_reputation = clampf(lab_reputation - 5.0, 0.0, 100.0)
	alert_count += 1
	economy_changed.emit()


func apply_microscopy_results(summary: Dictionary) -> void:
	var score: int = int(summary.get("score", 0))
	var accuracy: float = float(summary.get("accuracy", 0.0))
	var wrong: int = int(summary.get("wrong", 0))
	player_xp += floori(score / 8.0) + int(accuracy * 20.0)
	player_money += floori(score / 4.0)
	lab_reputation = clampf(lab_reputation + (accuracy - 0.5) * 6.0 - wrong, 0.0, 100.0)
	_apply_level_progress()
	_check_contract_breaks()
	game_layer = GameLayer.LAB
	layer_changed.emit(game_layer)
	economy_changed.emit()
	sample_queue_changed.emit()
	microscopy_results_applied.emit(summary)
