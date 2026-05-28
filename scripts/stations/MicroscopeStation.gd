class_name MicroscopeStation
extends StationBase
## Microscope station: short prep timer, then launches the classification mini-game.


@export var prep_time: float = 1.0

var _prep_done: bool = false


func _ready() -> void:
	station_type = "microscope"
	processing_time = prep_time
	required_sample_state = Sample.ProcessingState.DRIED
	output_sample_state = Sample.ProcessingState.INSPECTING


func _finish_processing() -> void:
	# Do not spawn a pickup sample; mini-game takes over the flow.
	current_state = StationState.COMPLETE
	_set_visual_state(StationState.COMPLETE)
	if _current_sample:
		_current_sample.set_processing_state(Sample.ProcessingState.INSPECTING)
	processing_completed.emit(_current_sample)
	GameManager.notify_station_processing_complete(station_type)
	# Sample stays at station until minigame closes.
	_prep_done = true


func consume_sample_after_minigame() -> void:
	if _current_sample:
		_current_sample.queue_free()
		_current_sample = null
	current_state = StationState.IDLE
	progress_bar.value = 0.0
	_set_visual_state(StationState.IDLE)
