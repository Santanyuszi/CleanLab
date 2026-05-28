class_name EscalationPanel
extends PanelContainer

@onready var _body: Label = %BodyLabel


func _ready() -> void:
	GameManager.economy_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if GameManager.alert_count > 0:
		_body.text = (
			"Blue fibers detected repeatedly.\n"
			"Risk: %.0f%% · %d open ticket(s)\n"
			"(Investigation UI coming soon)"
			% [GameManager.escalation_risk * 100.0, GameManager.alert_count]
		)
	else:
		_body.text = "No active escalations."
