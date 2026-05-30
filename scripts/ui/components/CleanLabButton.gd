class_name CleanLabButton
extends Button

@export var selected := false:
	set(value):
		selected = value
		_apply_style()


func _ready() -> void:
	custom_minimum_size = Vector2(CleanLabTokens.BOTTOM_NAV_BUTTON_WIDTH, CleanLabTokens.BOTTOM_NAV_BUTTON_HEIGHT)
	_apply_style()


func _apply_style() -> void:
	if not is_inside_tree():
		return
	if selected:
		add_theme_stylebox_override("normal", CleanLabTheme.nav_style(true))
		add_theme_stylebox_override("hover", CleanLabTheme.nav_style(true, true))
		add_theme_color_override("font_color", CleanLabTokens.COLOR_PRIMARY_ACCENT)
		add_theme_color_override("font_hover_color", CleanLabTokens.COLOR_BRIGHT_ACCENT)
		return
	add_theme_stylebox_override("normal", CleanLabTheme.nav_style(false))
	add_theme_stylebox_override("hover", CleanLabTheme.nav_style(false, true))
	add_theme_stylebox_override("pressed", CleanLabTheme.button_pressed())
	add_theme_color_override("font_color", CleanLabTokens.COLOR_TEXT_SECONDARY)
	add_theme_color_override("font_hover_color", CleanLabTokens.COLOR_PRIMARY_ACCENT)
