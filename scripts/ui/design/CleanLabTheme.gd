class_name CleanLabTheme
extends RefCounted


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = CleanLabTokens.FONT_SIZE_BODY

	theme.set_color("font_color", "Label", CleanLabTokens.COLOR_TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Label", CleanLabTokens.COLOR_TEXT_DISABLED)
	theme.set_color("font_color", "Button", CleanLabTokens.COLOR_TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", CleanLabTokens.COLOR_PRIMARY_ACCENT)
	theme.set_color("font_pressed_color", "Button", CleanLabTokens.COLOR_TEXT_PRIMARY)
	theme.set_font_size("font_size", "Label", CleanLabTokens.FONT_SIZE_BODY)
	theme.set_font_size("font_size", "Button", CleanLabTokens.FONT_SIZE_BUTTON)

	theme.set_stylebox("panel", "PanelContainer", glass_panel())
	theme.set_stylebox("normal", "Button", button_normal())
	theme.set_stylebox("hover", "Button", button_hover())
	theme.set_stylebox("pressed", "Button", button_pressed())
	theme.set_stylebox("disabled", "Button", button_disabled())
	theme.set_stylebox("background", "ProgressBar", progress_background())
	theme.set_stylebox("fill", "ProgressBar", progress_fill())
	return theme


static func glass_panel(radius: int = CleanLabTokens.RADIUS_PANEL) -> StyleBoxFlat:
	return style_box(
		CleanLabTokens.COLOR_GLASS_BACKGROUND,
		CleanLabTokens.COLOR_GLASS_BORDER,
		radius,
		1,
		CleanLabTokens.SPACING_16
	)


static func solid_panel(radius: int = CleanLabTokens.RADIUS_PANEL) -> StyleBoxFlat:
	return style_box(
		Color(CleanLabTokens.COLOR_PANEL_BACKGROUND, 0.94),
		Color(CleanLabTokens.COLOR_STATION_IDLE, 0.35),
		radius,
		1,
		CleanLabTokens.SPACING_16
	)


static func station_style(state: String) -> StyleBoxFlat:
	var border := CleanLabTokens.COLOR_STATION_IDLE
	if state == "processing":
		border = CleanLabTokens.COLOR_PRIMARY_ACCENT
	elif state == "completed":
		border = CleanLabTokens.COLOR_SUCCESS
	elif state == "problem":
		border = CleanLabTokens.COLOR_WARNING
	return style_box(Color(CleanLabTokens.COLOR_PANEL_BACKGROUND, 0.95), Color(border, 0.75), CleanLabTokens.RADIUS_STATION, 1, CleanLabTokens.SPACING_8)


static func nav_style(selected: bool = false, hover: bool = false) -> StyleBoxFlat:
	var bg := Color(0, 0, 0, 0)
	var border := Color(0, 0, 0, 0)
	if hover:
		bg = Color(CleanLabTokens.COLOR_PRIMARY_ACCENT, 0.08)
	if selected:
		bg = Color(CleanLabTokens.COLOR_PRIMARY_ACCENT, 0.15)
		border = Color(CleanLabTokens.COLOR_PRIMARY_ACCENT, 0.4)
	return style_box(bg, border, CleanLabTokens.RADIUS_NAV, 1 if selected else 0, CleanLabTokens.SPACING_16)


static func send_truck_button() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PANEL_BACKGROUND, CleanLabTokens.COLOR_PRIMARY_ACCENT, CleanLabTokens.RADIUS_BUTTON, 1, CleanLabTokens.SPACING_16)


static func button_normal() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PANEL_BACKGROUND, CleanLabTokens.COLOR_STATION_IDLE, CleanLabTokens.RADIUS_BUTTON, 1, CleanLabTokens.SPACING_16)


static func button_hover() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PANEL_HOVER, CleanLabTokens.COLOR_PRIMARY_ACCENT, CleanLabTokens.RADIUS_BUTTON, 1, CleanLabTokens.SPACING_16)


static func button_pressed() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_BUTTON_PRESSED, CleanLabTokens.COLOR_BUTTON_PRESSED, CleanLabTokens.RADIUS_BUTTON, 1, CleanLabTokens.SPACING_16)


static func button_disabled() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PANEL_BACKGROUND, CleanLabTokens.COLOR_STATION_IDLE, CleanLabTokens.RADIUS_BUTTON, 1, CleanLabTokens.SPACING_16)


static func progress_background() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PANEL_HOVER, Color(0, 0, 0, 0), 4, 0, 0)


static func progress_fill() -> StyleBoxFlat:
	return style_box(CleanLabTokens.COLOR_PRIMARY_ACCENT, CleanLabTokens.COLOR_PRIMARY_ACCENT, 4, 0, 0)


static func style_box(bg: Color, border: Color, radius: int, border_width: int, content_margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = content_margin
	style.content_margin_top = content_margin
	style.content_margin_right = content_margin
	style.content_margin_bottom = content_margin
	return style
