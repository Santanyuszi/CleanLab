class_name HeaderBar
extends PanelContainer

@onready var _reputation: Label = %ReputationLabel
@onready var _level: Label = %LevelLabel
@onready var _xp: Label = %XPLabel
@onready var _money: Label = %MoneyLabel
@onready var _samples: Label = %SamplesLabel
@onready var _time: Label = %TimeLabel


func refresh() -> void:
	_level.text = "LEVEL\n%d  SENIOR ANALYST" % GameManager.player_level
	_xp.text = "XP\n%d / %d" % [GameManager.player_xp, GameManager.player_xp_to_next]
	_money.text = "MONEY\n$ %s" % _format_money(GameManager.player_money)
	_reputation.text = "REPUTATION\n%.0f%%" % GameManager.lab_reputation
	_samples.text = "SAMPLES\n%d / %d" % [
		GameManager.samples_in_lab,
		GameManager.get_manufacturing_buffer_capacity(),
	]
	_time.text = "DAY %d\n%s" % [GameManager.game_day, GameManager.get_time_string()]


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
