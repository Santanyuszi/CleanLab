class_name GameHUD
extends Control

@onready var _money_label: Label = $TopBar/Margin/HBox/MoneyLabel
@onready var _xp_label: Label = $TopBar/Margin/HBox/XPLabel
@onready var _rep_label: Label = $TopBar/Margin/HBox/RepLabel
@onready var _hint_label: Label = $HintBar/HintLabel


func _ready() -> void:
	GameManager.economy_changed.connect(_refresh)
	GameManager.layer_changed.connect(_on_layer)
	GameManager.delivery_completed.connect(_on_delivery)
	_refresh()
	_on_layer(GameManager.game_layer)


func set_hint(text: String) -> void:
	_hint_label.text = text


func set_phase_hint(text: String) -> void:
	set_hint(text)


func _on_layer(layer: GameManager.GameLayer) -> void:
	match layer:
		GameManager.GameLayer.LAB:
			set_hint("Tap the sample, then tap finished stations to advance.")
		GameManager.GameLayer.MICROSCOPY:
			set_hint("Microscope active — classify quickly to keep quality high.")
		GameManager.GameLayer.PROBLEM_INSPECTION:
			set_hint("QC inspection open — verify the particle.")


func _on_delivery(payout: int) -> void:
	set_hint("Truck left! +$%d — new part incoming." % payout)


func _refresh() -> void:
	_money_label.text = "$%d" % GameManager.player_money
	_xp_label.text = "XP %d" % GameManager.player_xp
	_rep_label.text = "Rep %.0f" % GameManager.lab_reputation
