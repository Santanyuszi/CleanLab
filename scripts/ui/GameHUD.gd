extends Control
## Minimal dark UI overlay for prototype feedback.

@onready var _phase_label: Label = $Panel/Margin/VBox/PhaseLabel
@onready var _reputation_label: Label = $Panel/Margin/VBox/ReputationLabel
@onready var _hint_label: Label = $Panel/Margin/VBox/HintLabel


func _ready() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)
	GameManager.prototype_run_finished.connect(_on_run_finished)
	_update_reputation()


func set_phase_hint(text: String) -> void:
	_hint_label.text = text


func _on_phase_changed(phase: GameManager.GamePhase) -> void:
	_phase_label.text = "Phase: %s" % GameManager.GamePhase.keys()[phase]
	_update_reputation()
	match phase:
		GameManager.GamePhase.SAMPLE_ARRIVED:
			set_phase_hint("Click the sample to pick it up.")
		GameManager.GamePhase.AT_WASHING:
			set_phase_hint("Click Washing station to deposit. Wait, then click again to collect.")
		GameManager.GamePhase.WASHING:
			set_phase_hint("Washing in progress…")
		GameManager.GamePhase.AT_DRYING:
			set_phase_hint("Deliver washed sample to Drying station.")
		GameManager.GamePhase.DRYING:
			set_phase_hint("Drying in progress…")
		GameManager.GamePhase.AT_MICROSCOPE:
			set_phase_hint("Deliver dried sample to Microscope station.")
		GameManager.GamePhase.MINIGAME:
			set_phase_hint("Classify particles quickly!")
		GameManager.GamePhase.COMPLETE:
			set_phase_hint("Run complete. Restart scene to play again.")


func _on_run_finished(score: int) -> void:
	_hint_label.text = "Prototype complete! Score: %d" % score


func _update_reputation() -> void:
	_reputation_label.text = "Lab reputation: %.0f" % GameManager.lab_reputation
