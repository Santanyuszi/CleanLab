class_name CleanLabTokens
extends RefCounted

const FONT_PRIMARY := "DM Sans"
const FONT_FALLBACK := "Inter"

const COLOR_MAIN_BACKGROUND := Color("#F2F9F8")
const COLOR_ALT_DARK := Color("#8FB1B4")
const COLOR_PANEL_BACKGROUND := Color("#FFFFFF")
const COLOR_PANEL_HOVER := Color("#F2F9F8")

const COLOR_PRIMARY_ACCENT := Color("#4CFFBD")
const COLOR_BRIGHT_ACCENT := Color("#4CFFBD")
const COLOR_SELECTION_ACCENT := Color("#4CFFBD")
const COLOR_SUCCESS := Color("#2AAE68")
const COLOR_WARNING := Color("#FFB340")
const COLOR_DANGER := Color("#FF5B5B")

const COLOR_TEXT_PRIMARY := Color("#002121")
const COLOR_TEXT_SECONDARY := Color("#316263")
const COLOR_TEXT_DISABLED := Color("#8FB1B4")

const COLOR_GLASS_BACKGROUND := Color(0.949, 0.976, 0.973, 0.9)
const COLOR_GLASS_BORDER := Color(0.561, 0.694, 0.706, 0.42)

const COLOR_STATION_IDLE := Color("#8FB1B4")
const COLOR_BUTTON_PRESSED := Color("#4CFFBD")

const SPACING_4 := 4
const SPACING_8 := 8
const SPACING_16 := 16
const SPACING_24 := 24
const SPACING_32 := 32
const SPACING_48 := 48
const SPACING_64 := 64

const RADIUS_BUTTON := 14
const RADIUS_PANEL := 20
const RADIUS_NAV := 18
const RADIUS_TOP_BAR := 16
const RADIUS_STATION := 14

const FONT_SIZE_LOGO := 64
const FONT_SIZE_STAT_LABEL := 12
const FONT_SIZE_STAT_VALUE := 32
const FONT_SIZE_PANEL_HEADER := 18
const FONT_SIZE_BODY := 15
const FONT_SIZE_BUTTON := 18

const TOP_STATUS_BAR_HEIGHT := 80
const TOP_STATUS_SECTION_WIDTH := 220
const LEFT_TASK_PANEL_WIDTH := 260
const RIGHT_ORDERS_PANEL_WIDTH := 280
const SHIPPING_PANEL_HEIGHT := 300
const BOTTOM_NAV_HEIGHT := 90
const BOTTOM_NAV_BUTTON_WIDTH := 220
const BOTTOM_NAV_BUTTON_HEIGHT := 70
const STATION_LABEL_WIDTH := 180
const STATION_LABEL_HEIGHT := 72


static func spacing(value: int) -> int:
	var allowed := [4, 8, 16, 24, 32, 48, 64]
	return value if value in allowed else 8
