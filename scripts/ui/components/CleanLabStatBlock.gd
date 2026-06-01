class_name CleanLabStatBlock
extends VBoxContainer

@export var label := "LEVEL":
	set(value):
		label = value
		_refresh()

@export var value := "12":
	set(next_value):
		value = next_value
		_refresh()

@export_range(0.0, 1.0, 0.01) var progress := 0.0:
	set(next_progress):
		progress = next_progress
		_refresh()

var _label_node: Label
var _value_node: Label
var _progress_bar: ProgressBar


func _ready() -> void:
	custom_minimum_size = Vector2(CleanLabTokens.TOP_STATUS_SECTION_WIDTH, CleanLabTokens.TOP_STATUS_BAR_HEIGHT)
	add_theme_constant_override("separation", CleanLabTokens.SPACING_4)
	_label_node = Label.new()
	_value_node = Label.new()
	_progress_bar = ProgressBar.new()
	_progress_bar.max_value = 1.0
	_progress_bar.show_percentage = false
	_progress_bar.custom_minimum_size = Vector2(0, CleanLabTokens.SPACING_4)
	add_child(_label_node)
	add_child(_value_node)
	add_child(_progress_bar)
	_refresh()


func _refresh() -> void:
	if _label_node == null:
		return
	_label_node.text = label
	_label_node.add_theme_font_size_override("font_size", CleanLabTokens.FONT_SIZE_STAT_LABEL)
	_label_node.add_theme_color_override("font_color", CleanLabTokens.COLOR_TEXT_SECONDARY)
	_value_node.text = value
	_value_node.add_theme_font_size_override("font_size", CleanLabTokens.FONT_SIZE_STAT_VALUE)
	_value_node.add_theme_color_override("font_color", CleanLabTokens.COLOR_TEXT_PRIMARY)
	_progress_bar.value = progress
	_progress_bar.visible = progress > 0.0
	_progress_bar.add_theme_stylebox_override("background", CleanLabTheme.progress_background())
	_progress_bar.add_theme_stylebox_override("fill", CleanLabTheme.progress_fill())
