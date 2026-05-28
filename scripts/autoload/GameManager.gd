extends Node
## Global game state and prototype flow orchestration.
## Stations and the lab room report events here; UI listens for phase changes.

enum GamePhase {
	SETUP,
	SAMPLE_ARRIVED,
	AT_WASHING,
	WASHING,
	AT_DRYING,
	DRYING,
	AT_MICROSCOPE,
	MINIGAME,
	COMPLETE,
}

var current_phase: GamePhase = GamePhase.SETUP
var lab_reputation: float = 100.0
var active_sample: Sample = null

signal phase_changed(phase: GamePhase)
signal microscope_minigame_requested(sample: Sample)
signal prototype_run_finished(score: int)


func start_prototype_run() -> void:
	current_phase = GamePhase.SETUP
	lab_reputation = 100.0
	active_sample = null
	phase_changed.emit(current_phase)


func register_sample(sample: Sample) -> void:
	active_sample = sample
	current_phase = GamePhase.SAMPLE_ARRIVED
	phase_changed.emit(current_phase)


func notify_sample_picked_up() -> void:
	current_phase = GamePhase.AT_WASHING
	phase_changed.emit(current_phase)


func notify_station_processing_started(station_type: String) -> void:
	match station_type:
		"washing":
			current_phase = GamePhase.WASHING
		"drying":
			current_phase = GamePhase.DRYING
		_:
			pass
	phase_changed.emit(current_phase)


func notify_station_processing_complete(station_type: String) -> void:
	match station_type:
		"washing":
			current_phase = GamePhase.AT_DRYING
			if active_sample:
				active_sample.set_processing_state(Sample.ProcessingState.WASHED)
		"drying":
			current_phase = GamePhase.AT_MICROSCOPE
			if active_sample:
				active_sample.set_processing_state(Sample.ProcessingState.DRIED)
		"microscope":
			current_phase = GamePhase.MINIGAME
			if active_sample:
				active_sample.set_processing_state(Sample.ProcessingState.INSPECTING)
			microscope_minigame_requested.emit(active_sample)
	phase_changed.emit(current_phase)


func apply_reputation_delta(delta: float) -> void:
	lab_reputation = clampf(lab_reputation + delta, 0.0, 100.0)


func notify_minigame_complete(score: int, reputation_delta: float) -> void:
	apply_reputation_delta(reputation_delta)
	if active_sample:
		active_sample.set_processing_state(Sample.ProcessingState.COMPLETE)
	current_phase = GamePhase.COMPLETE
	phase_changed.emit(current_phase)
	prototype_run_finished.emit(score)
