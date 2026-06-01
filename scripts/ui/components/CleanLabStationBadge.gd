class_name CleanLabStationBadge
extends PanelContainer

@export_enum("idle", "processing", "completed", "problem") var state := "idle":
	set(value):
		state = value
		_apply_style()

@export var station_name := "Extraction":
	set(value):
		station_name = value
		_refresh()

@export var status_text := "Idle":
	set(value):
		status_text = value
		_refresh()

var _name_label: Label
var _status_label: Label
var _progress: ProgressBar


func _ready() -> void:
	custom_minimum_size = Vector2(CleanLabTokens.STATION_LABEL_WIDTH, CleanLabTokens.STATION_LABEL_HEIGHT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", CleanLabTokens.SPACING_16)
	margin.add_theme_constant_override("margin_top", CleanLabTokens.SPACING_8)
	margin.add_theme_constant_override("margin_right", CleanLabTokens.SPACING_16)
	margin.add_theme_constant_override("margin_bottom", CleanLabTokens.SPACING_8)
	add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", CleanLabTokens.SPACING_4)
	margin.add_child(vbox)
	_name_label = Label.new()
	_status_label = Label.new()
	_progress = ProgressBar.new()
	_progress.max_value = 1.0
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, CleanLabTokens.SPACING_4)
	vbox.add_child(_name_label)
	vbox.add_child(_status_label)
	vbox.add_child(_progress)
	_apply_style()
	_refresh()


func set_progress(value: float) -> void:
	if _progress:
		_progress.value = clampf(value, 0.0, 1.0)


func _apply_style() -> void:
	if not is_inside_tree():
		return
	add_theme_stylebox_override("panel", CleanLabTheme.station_style(state))
	if _progress:
		_progress.visible = state == "processing"
		_progress.add_theme_stylebox_override("background", CleanLabTheme.progress_background())
		_progress.add_theme_stylebox_override("fill", CleanLabTheme.progress_fill())


func _refresh() -> void:
	if _name_label == null:
		return
	_name_label.text = station_name
	_name_label.add_theme_color_override("font_color", CleanLabTokens.COLOR_TEXT_PRIMARY)
	_name_label.add_theme_font_size_override("font_size", CleanLabTokens.FONT_SIZE_BODY)
	_status_label.text = status_text
	_status_label.add_theme_color_override("font_color", _status_color())
	_status_label.add_theme_font_size_override("font_size", CleanLabTokens.FONT_SIZE_STAT_LABEL)


func _status_color() -> Color:
	if state == "processing":
		return CleanLabTokens.COLOR_PRIMARY_ACCENT
	if state == "completed":
		return CleanLabTokens.COLOR_SUCCESS
	if state == "problem":
		return CleanLabTokens.COLOR_WARNING
	return CleanLabTokens.COLOR_TEXT_DISABLED
