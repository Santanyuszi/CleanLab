class_name StationSidebarRow
extends PanelContainer

@onready var _title: Label = $RowMargin/RowVBox/TitleHBox/TitleLabel
@onready var _level: Label = $RowMargin/RowVBox/TitleHBox/LevelLabel
@onready var _status: Label = $RowMargin/RowVBox/StatusLabel
@onready var _progress: ProgressBar = $RowMargin/RowVBox/ProgressBar
@onready var _timer: Label = $RowMargin/RowVBox/TimerLabel


func setup(title: String) -> void:
	_title.text = title
	_progress.max_value = 1.0
	_progress.value = 0.0
	_timer.text = ""


func set_level(lvl: int) -> void:
	_level.text = "Level %d" % lvl


func update_status(status: String, progress: float, time_left: float) -> void:
	_status.text = status
	_progress.value = progress
	if time_left > 0.0:
		var sec: int = int(ceilf(time_left))
		_timer.text = "%02d:%02d" % [floori(sec / 60.0), sec % 60]
	else:
		_timer.text = ""
