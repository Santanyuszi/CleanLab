class_name HeaderBar
extends PanelContainer

@onready var _reputation: Label = %ReputationLabel
@onready var _level: Label = %LevelLabel
@onready var _xp: Label = %XPLabel
@onready var _money: Label = %MoneyLabel
@onready var _samples: Label = %SamplesLabel
@onready var _time: Label = %TimeLabel


func refresh() -> void:
	_reputation.text = "Reputation: %.0f%%" % GameManager.lab_reputation
	_level.text = "Level %d · Senior Analyst" % GameManager.player_level
	_xp.text = "XP: %d / %d" % [GameManager.player_xp, GameManager.player_xp_to_next]
	_money.text = "$%s" % _format_money(GameManager.player_money)
	_samples.text = "Samples in Lab: %d / %d" % [
		GameManager.samples_in_lab,
		GameManager.max_samples_in_lab,
	]
	_time.text = "Day %d · %s" % [GameManager.game_day, GameManager.get_time_string()]


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
