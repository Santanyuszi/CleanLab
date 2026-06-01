class_name HeaderBar
extends PanelContainer

@onready var _reputation: Label = %ReputationLabel
@onready var _level: Label = %LevelLabel
@onready var _xp: Label = %XPLabel
@onready var _energy: Label = get_node_or_null("%EnergyLabel") as Label
@onready var _money: Label = %MoneyLabel
@onready var _samples: Label = get_node_or_null("%SamplesLabel") as Label
@onready var _time: Label = get_node_or_null("%TimeLabel") as Label


func refresh() -> void:
	_level.text = "LEVEL\n%d  SENIOR ANALYST" % GameManager.player_level
	_xp.text = "XP\n%d / %d" % [GameManager.player_xp, GameManager.player_xp_to_next]
	if _energy:
		_energy.text = "ENERGY\n%d / %d" % [GameManager.player_energy, GameManager.player_energy_max]
	_money.text = "MONEY\n$ %s" % _format_money(GameManager.player_money)
	_reputation.text = "REPUTATION\n%.0f%%" % GameManager.lab_reputation
	if _samples:
		_samples.visible = false
	if _time:
		_time.visible = false


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
