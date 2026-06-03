class_name LabShell
extends Control
## Landscape dashboard shell (mockup layout): header, lab view, sidebar, bottom panels.

const WHITE := Color("#FFFFFF")
const OFF_WHITE := Color("#F2F9F8")
const SOFT_TEAL := Color("#8FB1B4")
const MID_TEAL := Color("#316263")
const DEEP_TEAL := Color("#002121")
const MINT_ACCENT := Color("#4CFFBD")
const CYAN := MINT_ACCENT
const PANEL_BG := Color(1.0, 1.0, 1.0, 0.94)
const PANEL_BG_SOFT := Color(0.949, 0.976, 0.973, 0.92)
const PANEL_BORDER := Color(0.561, 0.694, 0.706, 0.72)
const TEXT_DARK := DEEP_TEAL
const TEXT_DIM := MID_TEAL
const MINT_WASH := Color(0.949, 0.976, 0.973, 0.88)
const MUSIC_LOOP_PATH := "res://assets/audio/855613__noisera__nostalgic-retro-game-music-loop.mp3"
const CLAIM_SFX_PATH := "res://assets/audio/467951__benzix2__ui-button-click.ogg"
const TRUCK_BUTTON_PATH := "res://assets/ui/CleanLab_TruckButton.png"
const AUDIO_BUS_MUSIC := "Music"
const AUDIO_BUS_SFX := "SFX"
const TOUCH_TARGET := 56.0
const MOBILE_SIDE_MARGIN := 24.0
const SHOP_CARD_SIZE := Vector2(250, 376)
const SHOP_THUMBNAIL_PANEL_HEIGHT := 170.0
const CONTRACT_POPUP_MAX_SIZE := Vector2(1180, 820)
const CHALLENGE_POPUP_MAX_SIZE := Vector2(980, 720)
const SHOP_POPUP_MAX_SIZE := Vector2(900, 820)
const ACHIEVEMENT_POPUP_MAX_SIZE := Vector2(1320, 720)
const MICROSCOPE_POPUP_MAX_SIZE := Vector2(920, 560)
const ACHIEVEMENT_BADGE_ATLAS_PATH := "res://assets/achievements/Achievements.png"
const ACHIEVEMENT_COMPOSED_BADGE_PATH := "res://assets/achievements/composed_badges/%s/%s_%s.png"
const TABLER_ICON_PATH := "res://assets/icons/tabler/%s.svg"
const ACHIEVEMENT_BADGE_REGIONS := {
	0: Rect2(0, 0, 297, 423),
	1: Rect2(297, 0, 297, 423),
	2: Rect2(594, 0, 297, 423),
	3: Rect2(891, 0, 297, 423),
	4: Rect2(1188, 0, 297, 423),
}
const SHOP_DEVICE_IMAGES := {
	"extraction": "res://assets/shop/extraction_thumbnail.png",
	"drying": "res://assets/shop/drying_thumbnail.png",
	"microscope": "res://assets/shop/microscope_thumbnail.png",
	"truck": "res://assets/ui/ImageDataSet_CleanLab_Truck.png",
}
const SHOP_PERSONNEL_IMAGES := {
	"labor_worker": "res://assets/shop/lab_worker_thumbnail.png",
	"lab_manager": "res://assets/shop/lab_manager_thumbnail.png",
}

@onready var _header: HeaderBar = %StatusBar
@onready var _sidebar: StationSidebar = %StationSidebar
@onready var _sample_queue: SampleQueuePanel = get_node_or_null("VBox/BottomRow/SampleQueuePanel") as SampleQueuePanel
@onready var _microscope_dock: MicroscopeDock = %MicroscopeDock
@onready var _lab_viewport: SubViewport = %LabViewport
@onready var _bottom_row: HBoxContainer = $VBox/BottomRow

var _shipping_status: Label = null
var _shipping_payout: Label = null
var _send_truck_button: BaseButton = null
var _contracts_status: Label = null
var _active_contracts_list: VBoxContainer = null
var _contracts_popup: PanelContainer = null
var _contracts_sections: VBoxContainer = null
var _challenges_popup: PanelContainer = null
var _challenges_list: VBoxContainer = null
var _shop_panel: PanelContainer = null
var _shop_grid: GridContainer = null
var _shop_rows: Dictionary = {}
var _offer_refresh_accumulator: float = 0.0
var _music_player: AudioStreamPlayer = null
var _sfx_player: AudioStreamPlayer = null
var _claim_sfx_player: AudioStreamPlayer = null
var _music_button: Button = null
var _music_icon: Control = null
var _sfx_button: Button = null
var _sfx_icon: Control = null
var _achievement_button: Button = null
var _achievement_icon: Control = null
var _achievement_unread_badge: Label = null
var _achievements_panel: PanelContainer = null
var _achievements_grid: GridContainer = null
var _achievements_summary: Label = null
var _achievements_scroll: ScrollContainer = null
var _menu_button: Button = null
var _menu_panel: PanelContainer = null
var _music_muted: bool = false
var _sfx_muted: bool = false
var _brand_title: Label = null
var _contract_add_button: Button = null
var _contract_add_tween: Tween = null
var _refreshing_contracts: bool = false
var _last_hint: String = ""


func _ready() -> void:
	add_to_group("lab_shell")
	_remove_sample_queue_panel()
	_bottom_row.visible = false
	call_deferred("_remove_right_panel_from_layout")
	resized.connect(_layout_mobile_shell)
	_apply_reference_skin()
	_promote_microscope_dock_to_popup()
	_ensure_audio_buses()
	_add_music_loop()
	_add_sfx_player()
	_add_claim_sfx_player()
	_add_main_menu()
	_add_achievement_button()
	_add_audio_buttons()
	_add_contract_picker_popup()
	_add_challenges_popup()
	_add_device_shop_panel()
	_add_achievements_panel()
	GameManager.economy_changed.connect(_refresh_header)
	GameManager.economy_changed.connect(_refresh_contracts)
	GameManager.economy_changed.connect(_refresh_shop)
	GameManager.energy_changed.connect(_refresh_header)
	GameManager.sample_queue_changed.connect(_refresh_header)
	GameManager.sample_queue_changed.connect(_refresh_contracts)
	GameManager.contract_offers_changed.connect(_refresh_contracts)
	GameManager.challenges_changed.connect(_refresh_challenges)
	GameManager.challenge_completed.connect(_on_challenge_completed)
	GameManager.device_changed.connect(_on_device_changed)
	GameManager.personnel_changed.connect(_on_personnel_changed)
	GameManager.device_changed.connect(func(_key: String) -> void: _refresh_shipping())
	GameManager.shipping_changed.connect(_refresh_shipping)
	GameManager.layer_changed.connect(_on_layer_changed)
	GameManager.delivery_completed.connect(_on_delivery)
	GameManager.problem_inspection_requested.connect(_on_problem_inspection)
	GameManager.problem_inspection_resolved.connect(_on_problem_resolved)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	AchievementManager.unread_changed.connect(_on_achievement_unread_changed)
	_refresh_header()
	_refresh_contracts()
	_refresh_challenges()
	_refresh_shipping()
	_refresh_shop()
	_refresh_achievements()
	_refresh_achievement_button()
	_on_layer_changed(GameManager.game_layer)
	set_hint("Open Menu > Contracts to accept your first job.")
	call_deferred("_layout_mobile_shell")


func _add_music_loop() -> void:
	if _music_player != null:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicLoop"
	_music_player.bus = AUDIO_BUS_MUSIC
	_music_player.volume_db = -7.0
	var stream := load(MUSIC_LOOP_PATH)
	if stream is AudioStreamWAV:
		stream = (stream as AudioStreamWAV).duplicate()
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		stream = (stream as AudioStreamMP3).duplicate()
		(stream as AudioStreamMP3).loop = true
	_music_player.stream = stream
	add_child(_music_player)
	call_deferred("_start_music_loop")


func _ensure_audio_buses() -> void:
	_ensure_audio_bus(AUDIO_BUS_MUSIC)
	_ensure_audio_bus(AUDIO_BUS_SFX)


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _add_sfx_player() -> void:
	if _sfx_player != null:
		return
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.bus = AUDIO_BUS_SFX
	_sfx_player.volume_db = -10.0
	_sfx_player.stream = _make_click_stream()
	add_child(_sfx_player)


func _add_claim_sfx_player() -> void:
	if _claim_sfx_player != null:
		return
	_claim_sfx_player = AudioStreamPlayer.new()
	_claim_sfx_player.name = "ClaimSfxPlayer"
	_claim_sfx_player.bus = AUDIO_BUS_SFX
	_claim_sfx_player.volume_db = -4.0
	_claim_sfx_player.stream = load(CLAIM_SFX_PATH)
	add_child(_claim_sfx_player)


func _make_click_stream() -> AudioStreamWAV:
	var sample_rate := 44100
	var frames := int(sample_rate * 0.055)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in frames:
		var t := float(i) / float(sample_rate)
		var env := maxf(1.0 - (t / 0.055), 0.0)
		var wave := sin(TAU * 880.0 * t) * env * 0.18
		var sample := clampi(int(wave * 32767.0), -32768, 32767)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	return stream


func _start_music_loop() -> void:
	if _music_player and _music_player.stream:
		_music_player.play()


func _add_audio_buttons() -> void:
	if _music_button != null:
		return
	_music_button = _make_audio_button("MusicButton", "Mute music", _toggle_music_mute, _draw_music_icon)
	_music_icon = _music_button.get_node("Icon") as Control
	_set_button_tabler_icon(_music_button, "music")
	_sfx_button = _make_audio_button("SfxButton", "Mute sound effects", _toggle_sfx_mute, _draw_sfx_icon)
	_sfx_icon = _sfx_button.get_node("Icon") as Control
	_set_button_tabler_icon(_sfx_button, "volume")


func _add_main_menu() -> void:
	if _menu_button != null:
		return
	_menu_button = Button.new()
	_menu_button.name = "MainMenuButton"
	_menu_button.tooltip_text = "Menu"
	_menu_button.custom_minimum_size = Vector2(TOUCH_TARGET, TOUCH_TARGET)
	_menu_button.pressed.connect(_toggle_main_menu)
	_style_icon_button(_menu_button)
	_set_button_tabler_icon(_menu_button, "menu-2")
	var header_row := get_node_or_null("VBox/HeaderBar/Margin/HBox") as HBoxContainer
	if header_row:
		header_row.add_child(_menu_button)
	else:
		add_child(_menu_button)

	_menu_panel = PanelContainer.new()
	_menu_panel.name = "MainMenuPanel"
	_menu_panel.visible = false
	_menu_panel.z_index = 45
	_menu_panel.custom_minimum_size = Vector2(360, 384)
	_apply_panel_style(_menu_panel, Color(WHITE, 0.98), PANEL_BORDER, 12, 1)
	add_child(_menu_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_menu_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	vbox.add_child(_build_menu_action("LAB", "building-factory", _on_menu_lab_pressed))
	vbox.add_child(_build_menu_action("CONTRACTS", "clipboard-list", _on_menu_contracts_pressed))
	vbox.add_child(_build_menu_action("CHALLENGES", "target-arrow", _on_menu_challenges_pressed))
	vbox.add_child(_build_menu_action("REPORTS", "report-analytics", _on_menu_reports_pressed))
	vbox.add_child(_build_menu_action("SHOP", "shopping-cart", _on_menu_shop_pressed))
	vbox.add_child(_build_menu_action("ACHIEVEMENTS", "award", _on_menu_achievements_pressed))
	vbox.add_child(_build_menu_action("MUSIC", "music", _on_menu_music_pressed))
	vbox.add_child(_build_menu_action("SOUND", "volume", _on_menu_sfx_pressed))
	_style_buttons(_menu_panel)
	_refresh_main_menu_labels()
	_layout_main_menu()


func _build_menu_action(label: String, icon_name: String, action: Callable) -> Button:
	var button := Button.new()
	if label == "MUSIC":
		button.name = "MusicMenuButton"
	elif label == "SOUND":
		button.name = "SfxMenuButton"
	elif label == "ACHIEVEMENTS":
		button.name = "AchievementMenuButton"
	button.text = label
	button.icon = _tabler_texture(icon_name)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(336, TOUCH_TARGET)
	button.pressed.connect(action)
	return button


func _layout_main_menu() -> void:
	if _menu_panel:
		var viewport_size := get_viewport_rect().size
		var panel_size := Vector2(
			minf(360.0, maxf(viewport_size.x - MOBILE_SIDE_MARGIN * 2.0, 300.0)),
			minf(500.0, maxf(viewport_size.y - MOBILE_SIDE_MARGIN * 2.0, 300.0))
		)
		_menu_panel.size = panel_size
		_menu_panel.position = ((viewport_size - panel_size) * 0.5).floor()


func _toggle_main_menu() -> void:
	if _menu_panel == null:
		return
	_menu_panel.visible = not _menu_panel.visible
	if _menu_panel.visible:
		_refresh_main_menu_labels()
		_layout_main_menu()


func _close_main_menu() -> void:
	if _menu_panel:
		_menu_panel.visible = false


func _on_menu_lab_pressed() -> void:
	_close_main_menu()
	set_hint("Lab view ready.")


func _on_menu_contracts_pressed() -> void:
	_close_main_menu()
	if _contracts_popup != null and not _contracts_popup.visible:
		_toggle_contract_picker()


func _on_menu_challenges_pressed() -> void:
	_close_main_menu()
	_toggle_challenges()


func _on_menu_reports_pressed() -> void:
	_close_main_menu()
	set_hint("QC reports show whether finished parts are clean enough for shipment.")


func _on_menu_shop_pressed() -> void:
	_close_main_menu()
	_toggle_shop()


func _on_menu_achievements_pressed() -> void:
	_close_main_menu()
	_toggle_achievements()


func _on_menu_music_pressed() -> void:
	_toggle_music_mute()
	_refresh_main_menu_labels()


func _on_menu_sfx_pressed() -> void:
	_toggle_sfx_mute()
	_refresh_main_menu_labels()


func _refresh_main_menu_labels() -> void:
	if _menu_panel == null:
		return
	var music := _menu_panel.find_child("MusicMenuButton", true, false) as Button
	if music:
		music.text = "MUSIC: OFF" if _music_muted else "MUSIC: ON"
		music.icon = _tabler_texture("music")
	var sfx := _menu_panel.find_child("SfxMenuButton", true, false) as Button
	if sfx:
		sfx.text = "SOUND: OFF" if _sfx_muted else "SOUND: ON"
		sfx.icon = _tabler_texture("volume-off" if _sfx_muted else "volume")


func _add_achievement_button() -> void:
	if _achievement_button != null:
		return
	_achievement_button = _make_audio_button("AchievementButton", "Achievements", _toggle_achievements, _draw_achievement_icon)
	_achievement_icon = _achievement_button.get_node("Icon") as Control
	_set_button_tabler_icon(_achievement_button, "award")

	_achievement_unread_badge = Label.new()
	_achievement_unread_badge.name = "UnreadBadge"
	_achievement_unread_badge.visible = false
	_achievement_unread_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_achievement_unread_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_achievement_unread_badge.add_theme_font_size_override("font_size", 10)
	_achievement_unread_badge.add_theme_color_override("font_color", Color.WHITE)
	_achievement_unread_badge.position = Vector2(34, 6)
	_achievement_unread_badge.size = Vector2(18, 18)
	_achievement_button.add_child(_achievement_unread_badge)


func _make_audio_button(button_name: String, tooltip: String, pressed_callable: Callable, draw_callable: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(TOUCH_TARGET, TOUCH_TARGET)
	button.pressed.connect(pressed_callable)
	_style_buttons(button)
	_style_icon_button(button)

	var icon := Control.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(28, 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(draw_callable)
	icon.position = (button.custom_minimum_size - icon.custom_minimum_size) * 0.5
	button.add_child(icon)
	return button


func _set_button_tabler_icon(button: Button, icon_name: String) -> void:
	var icon_draw := button.get_node_or_null("Icon") as Control
	if icon_draw:
		icon_draw.visible = false
	var texture := _tabler_texture(icon_name)
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.name = "TablerIcon"
	icon.custom_minimum_size = Vector2(28, 28)
	icon.position = Vector2(14, 14)
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = MID_TEAL
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(icon)


func _update_button_tabler_icon(button: Button, icon_name: String, muted: bool = false) -> void:
	if button == null:
		return
	var icon := button.get_node_or_null("TablerIcon") as TextureRect
	if icon == null:
		_set_button_tabler_icon(button, icon_name)
		icon = button.get_node_or_null("TablerIcon") as TextureRect
	if icon:
		icon.texture = _tabler_texture(icon_name)
		icon.modulate = SOFT_TEAL if muted else MID_TEAL


func _tabler_texture(icon_name: String) -> Texture2D:
	var path := TABLER_ICON_PATH % icon_name
	if not FileAccess.file_exists(path):
		return null
	return load(path) as Texture2D


func _toggle_music_mute() -> void:
	_music_muted = not _music_muted
	var index := AudioServer.get_bus_index(AUDIO_BUS_MUSIC)
	if index >= 0:
		AudioServer.set_bus_mute(index, _music_muted)
	if _music_button:
		_music_button.tooltip_text = "Unmute music" if _music_muted else "Mute music"
		_update_button_tabler_icon(_music_button, "music", _music_muted)
	if _music_icon:
		_music_icon.queue_redraw()


func _toggle_sfx_mute() -> void:
	_sfx_muted = not _sfx_muted
	var index := AudioServer.get_bus_index(AUDIO_BUS_SFX)
	if index >= 0:
		AudioServer.set_bus_mute(index, _sfx_muted)
	if _sfx_button:
		_sfx_button.tooltip_text = "Unmute sound effects" if _sfx_muted else "Mute sound effects"
		_update_button_tabler_icon(_sfx_button, "volume-off" if _sfx_muted else "volume", _sfx_muted)
	if _sfx_icon:
		_sfx_icon.queue_redraw()


func _style_icon_button(button: Button) -> void:
	var transparent := _button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	var hover := _button_style(Color(OFF_WHITE, 0.72), Color(0, 0, 0, 0))
	var pressed := _button_style(Color(MINT_ACCENT, 0.28), Color(0, 0, 0, 0))
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", transparent)
	button.focus_mode = Control.FOCUS_NONE


func _draw_music_icon() -> void:
	if _music_icon == null:
		return
	var stroke := MID_TEAL
	var muted_stroke := SOFT_TEAL
	var color := muted_stroke if _music_muted else stroke
	var width := 2.2
	_music_icon.draw_line(Vector2(9, 6), Vector2(9, 17), color, width, true)
	_music_icon.draw_line(Vector2(9, 6), Vector2(18, 4), color, width, true)
	_music_icon.draw_line(Vector2(18, 4), Vector2(18, 15), color, width, true)
	_music_icon.draw_circle(Vector2(7, 18), 3.0, Color(color, 0.16))
	_music_icon.draw_arc(Vector2(7, 18), 3.0, 0.0, TAU, 18, color, width, true)
	_music_icon.draw_circle(Vector2(16, 16), 3.0, Color(color, 0.16))
	_music_icon.draw_arc(Vector2(16, 16), 3.0, 0.0, TAU, 18, color, width, true)
	if _music_muted:
		_music_icon.draw_line(Vector2(4, 5), Vector2(21, 20), color, width, true)


func _draw_sfx_icon() -> void:
	_draw_speaker_icon(_sfx_icon, _sfx_muted)
	if _sfx_icon == null:
		return
	var color := SOFT_TEAL if _sfx_muted else MID_TEAL
	_sfx_icon.draw_circle(Vector2(18, 7), 1.2, color)
	_sfx_icon.draw_circle(Vector2(20, 12), 1.2, color)
	_sfx_icon.draw_circle(Vector2(18, 17), 1.2, color)


func _draw_achievement_icon() -> void:
	if _achievement_icon == null:
		return
	var color := MID_TEAL
	var fill := Color(MINT_ACCENT, 0.16)
	var badge := PackedVector2Array([
		Vector2(14, 4),
		Vector2(22, 8),
		Vector2(21, 17),
		Vector2(14, 23),
		Vector2(7, 17),
		Vector2(6, 8),
	])
	_achievement_icon.draw_colored_polygon(badge, fill)
	_achievement_icon.draw_polyline(badge, color, 2.1, true)
	_achievement_icon.draw_line(Vector2(10, 15), Vector2(13, 18), color, 2.1, true)
	_achievement_icon.draw_line(Vector2(13, 18), Vector2(19, 10), color, 2.1, true)


func _draw_speaker_icon(icon: Control, muted: bool) -> void:
	if icon == null:
		return
	var stroke := MID_TEAL
	var muted_stroke := SOFT_TEAL
	var color := muted_stroke if muted else stroke
	var width := 2.2
	var body := PackedVector2Array([
		Vector2(4, 10),
		Vector2(8, 10),
		Vector2(14, 5),
		Vector2(14, 19),
		Vector2(8, 14),
		Vector2(4, 14),
	])
	icon.draw_colored_polygon(body, Color(color, 0.14))
	icon.draw_polyline(body, color, width, true)
	if muted:
		icon.draw_line(Vector2(17, 8), Vector2(22, 16), color, width, true)
		icon.draw_line(Vector2(22, 8), Vector2(17, 16), color, width, true)
	else:
		icon.draw_arc(Vector2(14, 12), 5.0, -0.8, 0.8, 12, color, width, true)
		icon.draw_arc(Vector2(14, 12), 8.0, -0.75, 0.75, 16, color, width, true)


func _play_ui_click() -> void:
	if _sfx_player == null or _sfx_muted:
		return
	_sfx_player.stop()
	_sfx_player.play()


func play_claim_sfx() -> void:
	if _claim_sfx_player == null or _claim_sfx_player.stream == null or _sfx_muted:
		return
	_claim_sfx_player.stop()
	_claim_sfx_player.play()


func _process(delta: float) -> void:
	_offer_refresh_accumulator += delta
	if _offer_refresh_accumulator < 1.0:
		return
	_offer_refresh_accumulator = 0.0
	GameManager.refresh_contract_offers(false)
	GameManager.refresh_challenge_offers(false)
	if _contracts_popup != null and _contracts_popup.visible:
		_refresh_contracts()
	if _challenges_popup != null and _challenges_popup.visible:
		_refresh_challenges()
	_update_contract_add_highlight()


func get_lab_root() -> Node2D:
	return _lab_viewport.get_node("LaboratoryRoom") as Node2D


func set_hint(text: String) -> void:
	_last_hint = text
	if _sample_queue:
		_sample_queue.set_status_line(text)


func _layout_mobile_shell() -> void:
	_layout_header()
	_layout_main_menu()
	_layout_popup(_contracts_popup, CONTRACT_POPUP_MAX_SIZE)
	_layout_popup(_challenges_popup, CHALLENGE_POPUP_MAX_SIZE)
	_layout_popup(_shop_panel, SHOP_POPUP_MAX_SIZE)
	_layout_achievements_popup()
	_layout_microscope_popup()
	_refresh_contract_grid_columns()
	_refresh_achievement_grid_columns()
	_refresh_shop_grid_columns()


func _layout_header() -> void:
	var width := size.x
	var header_margin := get_node_or_null("VBox/HeaderBar/Margin") as MarginContainer
	if header_margin:
		header_margin.add_theme_constant_override("margin_left", 12)
		header_margin.add_theme_constant_override("margin_right", 12)
	var header_row := get_node_or_null("VBox/HeaderBar/Margin/HBox") as HBoxContainer
	if header_row:
		header_row.add_theme_constant_override("separation", 5 if width < 1500.0 else 6)
	var status_margin := get_node_or_null("VBox/StatusBar/Margin") as MarginContainer
	if status_margin:
		status_margin.add_theme_constant_override("margin_left", 12)
		status_margin.add_theme_constant_override("margin_right", 12)
	var status_row := get_node_or_null("VBox/StatusBar/Margin/HBox") as HBoxContainer
	if status_row:
		status_row.add_theme_constant_override("separation", 4 if width < 1500.0 else 6)
	if _brand_title:
		_brand_title.add_theme_font_size_override("font_size", 28 if width < 1500.0 else 32)
		_brand_title.size = Vector2(150, 56)


func _layout_popup(panel: PanelContainer, max_size: Vector2) -> void:
	if panel == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var margin := Vector2(MOBILE_SIDE_MARGIN, MOBILE_SIDE_MARGIN)
	var target_size := Vector2(
		minf(max_size.x, maxf(viewport_size.x - margin.x * 2.0, 320.0)),
		minf(max_size.y, maxf(viewport_size.y - margin.y * 2.0, 320.0))
	)
	panel.position = ((viewport_size - target_size) * 0.5).floor()
	panel.size = target_size


func _layout_achievements_popup() -> void:
	if _achievements_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var edge_margin := maxf(MOBILE_SIDE_MARGIN, 18.0)
	var safe_top := edge_margin
	var safe_bottom := viewport_size.y - edge_margin
	var header_bar := get_node_or_null("VBox/HeaderBar") as PanelContainer
	if header_bar:
		var header_bottom := header_bar.global_position.y + header_bar.size.y
		if header_bottom > 0.0:
			safe_top = maxf(safe_top, header_bottom + edge_margin)
	var status_bar := get_node_or_null("VBox/StatusBar") as PanelContainer
	if status_bar:
		var status_top := status_bar.global_position.y
		if status_top > 0.0:
			safe_bottom = minf(safe_bottom, status_top - edge_margin)
		else:
			safe_bottom -= maxf(status_bar.size.y, status_bar.custom_minimum_size.y)
	var safe_height := safe_bottom - safe_top
	if safe_height <= 0.0:
		return
	var safe_width := maxf(viewport_size.x - edge_margin * 2.0, 300.0)
	var target_size := Vector2(
		minf(ACHIEVEMENT_POPUP_MAX_SIZE.x, safe_width),
		minf(ACHIEVEMENT_POPUP_MAX_SIZE.y, safe_height)
	)
	_achievements_panel.position = Vector2(
		floor((viewport_size.x - target_size.x) * 0.5),
		floor(safe_top + (safe_height - target_size.y) * 0.5)
	)
	_achievements_panel.size = target_size
	if _achievements_scroll:
		_achievements_scroll.custom_minimum_size = Vector2(0, maxf(target_size.y - 156.0, 160.0))


func _deferred_layout_achievements_popup() -> void:
	await get_tree().process_frame
	if _achievements_panel == null or not _achievements_panel.visible:
		return
	_layout_achievements_popup()
	_refresh_achievement_grid_columns()


func _layout_microscope_popup() -> void:
	if _microscope_dock == null:
		return
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var edge_margin := maxf(MOBILE_SIDE_MARGIN, 18.0)
	var safe_top := edge_margin
	var safe_bottom := viewport_size.y - edge_margin
	var status_bar := get_node_or_null("VBox/StatusBar") as PanelContainer
	if status_bar:
		var status_top := status_bar.global_position.y
		if status_top > 0.0:
			safe_bottom = minf(safe_bottom, status_top - edge_margin)
		else:
			safe_bottom -= maxf(status_bar.size.y, status_bar.custom_minimum_size.y)
	var safe_height := safe_bottom - safe_top
	if safe_height <= 0.0:
		return
	var target_size := Vector2(
		minf(MICROSCOPE_POPUP_MAX_SIZE.x, maxf(viewport_size.x - edge_margin * 2.0, 320.0)),
		minf(MICROSCOPE_POPUP_MAX_SIZE.y, safe_height)
	)
	_microscope_dock.position = Vector2(
		floor((viewport_size.x - target_size.x) * 0.5),
		floor(safe_top + (safe_height - target_size.y) * 0.5)
	)
	_microscope_dock.size = target_size

	var particle_field := _microscope_dock.get_node_or_null("Margin/VBox/ParticleField") as Control
	if particle_field:
		particle_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		particle_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
		particle_field.custom_minimum_size = Vector2(0, maxf(target_size.y - 142.0, 260.0))
	var prompt := _microscope_dock.get_node_or_null("Margin/VBox/PromptLabel") as Label
	if prompt:
		prompt.custom_minimum_size = Vector2(0, 34)


func _contract_grid_columns() -> int:
	if _contracts_popup == null:
		return 2
	var available_width := _contracts_popup.size.x - 72.0
	if available_width >= 1040.0:
		return 3
	if available_width >= 650.0:
		return 2
	return 1


func _achievement_grid_columns() -> int:
	if _achievements_panel == null:
		return 2
	var available_width := _achievements_panel.size.x - 72.0
	if available_width >= 1180.0:
		return 4
	if available_width >= 900.0:
		return 3
	if available_width >= 620.0:
		return 2
	return 1


func _shop_grid_columns() -> int:
	if _shop_panel == null:
		return 2
	var available_width := _shop_panel.size.x - 72.0
	if available_width >= 780.0:
		return 3
	if available_width >= 520.0:
		return 2
	return 1


func _refresh_contract_grid_columns() -> void:
	if _contracts_sections == null:
		return
	var columns := _contract_grid_columns()
	for section in _contracts_sections.get_children():
		var grid := section.get_node_or_null("Cards") as GridContainer
		if grid:
			grid.columns = columns


func _refresh_achievement_grid_columns() -> void:
	if _achievements_grid != null:
		_achievements_grid.columns = _achievement_grid_columns()


func _refresh_shop_grid_columns() -> void:
	if _shop_grid != null:
		_shop_grid.columns = _shop_grid_columns()


func _update_contract_add_highlight() -> void:
	if _contract_add_button == null:
		return
	var popup_open := _contracts_popup != null and _contracts_popup.visible
	var should_pulse := GameManager.sample_queue.is_empty() and not popup_open
	if should_pulse and _contract_add_tween == null:
		_contract_add_button.modulate = Color.WHITE
		_contract_add_tween = create_tween().set_loops()
		_contract_add_tween.tween_property(_contract_add_button, "modulate", MINT_ACCENT, 0.45)
		_contract_add_tween.tween_property(_contract_add_button, "modulate", Color.WHITE, 0.45)
	elif not should_pulse and _contract_add_tween != null:
		_contract_add_tween.kill()
		_contract_add_tween = null
		_contract_add_button.modulate = Color.WHITE


func _refresh_header() -> void:
	_header.refresh()


func _on_layer_changed(layer: GameManager.GameLayer) -> void:
	var show_dock := layer == GameManager.GameLayer.MICROSCOPY
	if _bottom_row:
		_bottom_row.visible = false
	_microscope_dock.visible = show_dock
	if show_dock:
		_layout_microscope_popup()
	_microscope_dock.set_active(show_dock)


func _on_delivery(payout: int) -> void:
	set_hint("Truck departed with finished parts — +$%d." % payout)


func _on_problem_inspection(_part: Part, _claims: Array) -> void:
	set_hint("QC problem — verify particle in inspection overlay.")


func _on_problem_resolved(_part: Part, _passed: bool) -> void:
	set_hint("QC resolved. Load the finished part for shipment.")


func _apply_reference_skin() -> void:
	add_theme_color_override("font_color", TEXT_DARK)
	var background := get_node_or_null("Background") as ColorRect
	if background:
		background.color = OFF_WHITE
	var visual_header := get_node_or_null("VBox/HeaderBar") as PanelContainer
	if visual_header:
		_apply_panel_style(visual_header, Color(WHITE, 0.94), PANEL_BORDER, 0, 1)
	_apply_panel_style(_header, Color(WHITE, 0.94), PANEL_BORDER, 0, 1)
	if _sample_queue:
		_apply_panel_style(_sample_queue, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_microscope_dock, PANEL_BG, PANEL_BORDER, 8, 1)
	var viewport_panel := get_node_or_null("VBox/MiddleRow/LabViewportContainer") as PanelContainer
	if viewport_panel:
		_apply_panel_style(viewport_panel, WHITE, Color(SOFT_TEAL, 0.36), 4, 1)
	var subviewport_container := get_node_or_null("VBox/MiddleRow/LabViewportContainer/SubViewportContainer") as SubViewportContainer
	if subviewport_container:
		subviewport_container.self_modulate = WHITE
	var lab_viewport := get_node_or_null("VBox/MiddleRow/LabViewportContainer/SubViewportContainer/LabViewport") as SubViewport
	if lab_viewport:
		lab_viewport.transparent_bg = true
	_style_labels(self)
	_style_progress_bars(self)
	_style_buttons(self)
	_brand_title = Label.new()
	_brand_title.name = "BrandTitle"
	_brand_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brand_title.text = "CLEANLAB"
	_brand_title.add_theme_font_size_override("font_size", 32)
	_brand_title.add_theme_color_override("font_color", TEXT_DARK)
	_brand_title.position = Vector2(20, 9)
	_brand_title.size = Vector2(140, 56)
	add_child(_brand_title)


func _remove_sample_queue_panel() -> void:
	if _sample_queue == null:
		return
	if _sample_queue.get_parent():
		_sample_queue.get_parent().remove_child(_sample_queue)
	_sample_queue.queue_free()
	_sample_queue = null


func _remove_right_panel_from_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var middle_row := get_node_or_null("VBox/MiddleRow") as HBoxContainer
	if middle_row == null or _sidebar == null or _sidebar.get_parent() != middle_row:
		return
	middle_row.remove_child(_sidebar)
	_sidebar.visible = false
	_sidebar.custom_minimum_size = Vector2.ZERO


func _promote_microscope_dock_to_popup() -> void:
	if _microscope_dock == null or _microscope_dock.get_parent() == self:
		return
	var old_parent := _microscope_dock.get_parent()
	old_parent.remove_child(_microscope_dock)
	add_child(_microscope_dock)
	_microscope_dock.z_index = 42
	_microscope_dock.visible = false
	_microscope_dock.custom_minimum_size = Vector2(320, 320)
	_apply_panel_style(_microscope_dock, Color(WHITE, 0.985), PANEL_BORDER, 16, 1)
	_layout_microscope_popup()


func _add_shipping_panel() -> void:
	var sidebar_margin := get_node_or_null("VBox/MiddleRow/StationSidebar/Margin") as MarginContainer
	if sidebar_margin == null or sidebar_margin.has_node("RightStack"):
		return
	var old_vbox := sidebar_margin.get_node_or_null("VBox")
	if old_vbox == null:
		return
	sidebar_margin.remove_child(old_vbox)

	var stack := VBoxContainer.new()
	stack.name = "RightStack"
	stack.add_theme_constant_override("separation", 12)
	sidebar_margin.add_child(stack)
	stack.add_child(old_vbox)
	old_vbox.visible = false
	_add_contracts_panel(stack)

	var panel := PanelContainer.new()
	panel.name = "ShippingPanel"
	panel.custom_minimum_size = Vector2(0, 190)
	_apply_panel_style(panel, PANEL_BG_SOFT, PANEL_BORDER, 8, 1)
	stack.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "SHIPPING"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TEXT_DARK)
	vbox.add_child(title)

	_shipping_status = Label.new()
	_shipping_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shipping_status.add_theme_font_size_override("font_size", 16)
	_shipping_status.add_theme_color_override("font_color", TEXT_DARK)
	vbox.add_child(_shipping_status)

	_shipping_payout = Label.new()
	_shipping_payout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shipping_payout.add_theme_font_size_override("font_size", 13)
	_shipping_payout.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(_shipping_payout)

	_style_buttons(panel)


func _add_contracts_panel(stack: VBoxContainer) -> void:
	if stack.has_node("ContractsPanel"):
		return
	var panel := PanelContainer.new()
	panel.name = "ContractsPanel"
	panel.custom_minimum_size = Vector2(0, 210)
	_apply_panel_style(panel, PANEL_BG_SOFT, PANEL_BORDER, 8, 1)
	stack.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "CONTRACTS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(title)

	var add_button := Button.new()
	add_button.text = ""
	add_button.icon = _tabler_texture("plus")
	add_button.custom_minimum_size = Vector2(TOUCH_TARGET, TOUCH_TARGET)
	add_button.add_theme_font_size_override("font_size", 22)
	add_button.pressed.connect(_toggle_contract_picker)
	header.add_child(add_button)
	_contract_add_button = add_button

	_contracts_status = Label.new()
	_contracts_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contracts_status.add_theme_font_size_override("font_size", 13)
	_contracts_status.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(_contracts_status)

	var hint := Label.new()
	hint.text = "Check timed offers and accept work when the margin is worth the buffer space."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(MID_TEAL, 0.86))
	vbox.add_child(hint)

	_active_contracts_list = VBoxContainer.new()
	_active_contracts_list.add_theme_constant_override("separation", 6)
	vbox.add_child(_active_contracts_list)

	_style_buttons(panel)


func _add_contract_picker_popup() -> void:
	if _contracts_popup != null:
		return
	_contracts_popup = PanelContainer.new()
	_contracts_popup.name = "ContractPicker"
	_contracts_popup.visible = false
	_contracts_popup.z_index = 35
	_apply_panel_style(_contracts_popup, Color(OFF_WHITE, 0.98), PANEL_BORDER, 12, 1)
	add_child(_contracts_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	_contracts_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "MARKET OFFERS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(title)

	var close := Button.new()
	close.text = "CLOSE"
	close.icon = _tabler_texture("x")
	close.custom_minimum_size = Vector2(104, TOUCH_TARGET)
	close.pressed.connect(_toggle_contract_picker)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_contracts_sections = VBoxContainer.new()
	_contracts_sections.add_theme_constant_override("separation", 16)
	_contracts_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_contracts_sections)
	_style_buttons(_contracts_popup)
	_layout_popup(_contracts_popup, CONTRACT_POPUP_MAX_SIZE)


func _add_challenges_popup() -> void:
	if _challenges_popup != null:
		return
	_challenges_popup = PanelContainer.new()
	_challenges_popup.name = "ChallengesPopup"
	_challenges_popup.visible = false
	_challenges_popup.z_index = 36
	_apply_panel_style(_challenges_popup, Color(OFF_WHITE, 0.98), PANEL_BORDER, 12, 1)
	add_child(_challenges_popup)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	_challenges_popup.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "CHALLENGES"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(title)

	var close := Button.new()
	close.text = "CLOSE"
	close.icon = _tabler_texture("x")
	close.custom_minimum_size = Vector2(104, TOUCH_TARGET)
	close.pressed.connect(_toggle_challenges)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_challenges_list = VBoxContainer.new()
	_challenges_list.add_theme_constant_override("separation", 12)
	_challenges_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_challenges_list)
	_style_buttons(_challenges_popup)
	_layout_popup(_challenges_popup, CHALLENGE_POPUP_MAX_SIZE)


func _add_device_shop_panel() -> void:
	if has_node("DeviceShopPanel"):
		return
	_shop_panel = PanelContainer.new()
	_shop_panel.name = "DeviceShopPanel"
	_shop_panel.visible = false
	_shop_panel.z_index = 30
	_apply_panel_style(_shop_panel, Color(OFF_WHITE, 0.98), PANEL_BORDER, 16, 1)
	add_child(_shop_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	_shop_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "DEVICE SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(title)

	var close := Button.new()
	close.text = "CLOSE"
	close.icon = _tabler_texture("x")
	close.custom_minimum_size = Vector2(104, TOUCH_TARGET)
	close.pressed.connect(_toggle_shop)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_shop_grid = GridContainer.new()
	_shop_grid.columns = _shop_grid_columns()
	_shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_shop_grid.add_theme_constant_override("h_separation", 12)
	_shop_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(_shop_grid)

	var catalog := GameManager.get_device_catalog()
	for key in ["extraction", "drying", "microscope", "truck"]:
		var row := _build_shop_row(key, catalog.get(key, {}))
		_shop_grid.add_child(row)
	var personnel_catalog := GameManager.get_personnel_catalog()
	for key in ["labor_worker", "lab_manager"]:
		var row := _build_personnel_row(key, personnel_catalog.get(key, {}))
		_shop_grid.add_child(row)

	_style_buttons(_shop_panel)
	_layout_popup(_shop_panel, SHOP_POPUP_MAX_SIZE)
	_refresh_shop_grid_columns()


func _add_achievements_panel() -> void:
	if _achievements_panel != null:
		return
	_achievements_panel = PanelContainer.new()
	_achievements_panel.name = "AchievementsPanel"
	_achievements_panel.visible = false
	_achievements_panel.z_index = 40
	_achievements_panel.clip_contents = true
	_apply_panel_style(_achievements_panel, Color(OFF_WHITE, 0.985), PANEL_BORDER, 16, 1)
	add_child(_achievements_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	_achievements_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "ACHIEVEMENTS"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(title)

	var close := Button.new()
	close.text = "CLOSE"
	close.icon = _tabler_texture("x")
	close.custom_minimum_size = Vector2(104, TOUCH_TARGET)
	close.pressed.connect(_toggle_achievements)
	header.add_child(close)

	var play_games_button := Button.new()
	play_games_button.name = "PlayGamesButton"
	play_games_button.text = "PLAY GAMES"
	play_games_button.custom_minimum_size = Vector2(148, TOUCH_TARGET)
	play_games_button.visible = PlatformServices.is_available()
	play_games_button.pressed.connect(_on_play_games_achievements_pressed)
	header.add_child(play_games_button)

	_achievements_summary = Label.new()
	_achievements_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_achievements_summary.add_theme_font_size_override("font_size", 13)
	_achievements_summary.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(_achievements_summary)

	_achievements_scroll = ScrollContainer.new()
	_achievements_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_achievements_scroll.custom_minimum_size = Vector2(0, 220)
	_achievements_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_achievements_scroll)

	_achievements_grid = GridContainer.new()
	_achievements_grid.columns = _achievement_grid_columns()
	_achievements_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_achievements_grid.add_theme_constant_override("h_separation", 12)
	_achievements_grid.add_theme_constant_override("v_separation", 12)
	_achievements_scroll.add_child(_achievements_grid)

	_style_buttons(_achievements_panel)
	_layout_achievements_popup()


func _toggle_achievements() -> void:
	if _achievements_panel == null:
		return
	_achievements_panel.visible = not _achievements_panel.visible
	if _achievements_panel.visible:
		AchievementManager.clear_unread()
		_layout_achievements_popup()
		_refresh_achievements()
		_deferred_layout_achievements_popup()
		var pg_btn := _achievements_panel.find_child("PlayGamesButton", true, false) as Button
		if pg_btn:
			pg_btn.visible = PlatformServices.is_available()
	_refresh_achievement_button()


func _on_play_games_achievements_pressed() -> void:
	PlatformServices.show_achievements_ui()


func _refresh_achievements() -> void:
	if _achievements_grid == null:
		return
	for child in _achievements_grid.get_children():
		child.queue_free()
	var catalog := AchievementManager.get_catalog()
	var certified := 0
	var unlocked := 0
	for achievement in catalog:
		var tier := int(achievement.get("tier", AchievementManager.Tier.LOCKED))
		if tier > AchievementManager.Tier.LOCKED:
			unlocked += 1
		if tier >= AchievementManager.Tier.CERTIFIED:
			certified += 1
		_achievements_grid.add_child(_build_achievement_card(achievement))
	if _achievements_summary:
		var sync_hint: String
		if PlatformServices.is_available():
			sync_hint = "   Google Play Games ready."
		else:
			sync_hint = "   Google Play Games not configured for this build."
		_achievements_summary.text = "Unlocked %d / %d   Certified %d%s" % [
			unlocked,
			catalog.size(),
			certified,
			sync_hint,
		]
	_refresh_achievement_grid_columns()
	_style_buttons(_achievements_grid)


func _build_achievement_card(achievement: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 286)
	_apply_panel_style(card, Color(WHITE, 0.97), PANEL_BORDER, 10, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	var badge := _build_achievement_badge(achievement)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(badge)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 2)
	vbox.add_child(copy)

	var name := Label.new()
	name.text = str(achievement.get("name", "Achievement"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", 15)
	name.add_theme_color_override("font_color", TEXT_DARK)
	copy.add_child(name)

	var tier := int(achievement.get("tier", AchievementManager.Tier.LOCKED))
	var tier_label := Label.new()
	tier_label.text = AchievementManager.tier_name(tier)
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 13)
	tier_label.add_theme_color_override("font_color", AchievementManager.tier_color(tier))
	copy.add_child(tier_label)

	var desc := Label.new()
	desc.text = str(achievement.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 34)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(desc)

	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(0, 14)
	progress.max_value = 1.0
	progress.value = float(achievement.get("progress_ratio", 0.0))
	progress.show_percentage = false
	vbox.add_child(progress)

	var progress_label := Label.new()
	var value := int(achievement.get("progress", 0))
	var threshold := int(achievement.get("next_threshold", 0))
	if tier >= AchievementManager.Tier.CERTIFIED:
		progress_label.text = "Certified"
	else:
		progress_label.text = "%d / %d to next badge" % [value, threshold]
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(progress_label)
	_style_progress_bars(card)
	return card


func _build_achievement_badge(achievement: Dictionary) -> Control:
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(98, 140)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var frame := TextureRect.new()
	frame.custom_minimum_size = Vector2(98, 140)
	frame.texture = _achievement_badge_texture(achievement)
	frame.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(frame)

	return badge


func _achievement_badge_texture(achievement: Dictionary) -> Texture2D:
	var tier_key := _achievement_tier_key(int(achievement.get("tier", AchievementManager.Tier.LOCKED)))
	var id := str(achievement.get("id", ""))
	var path := ACHIEVEMENT_COMPOSED_BADGE_PATH % [tier_key, id, tier_key]
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(path)) == OK:
			return ImageTexture.create_from_image(image)
	return _achievement_badge_frame(int(achievement.get("tier", AchievementManager.Tier.LOCKED)))


func _achievement_tier_key(tier: int) -> String:
	match tier:
		AchievementManager.Tier.BRONZE:
			return "bronze"
		AchievementManager.Tier.SILVER:
			return "silver"
		AchievementManager.Tier.GOLD:
			return "gold"
		AchievementManager.Tier.CERTIFIED:
			return "certified"
		_:
			return "locked"


func _achievement_badge_frame(tier: int) -> Texture2D:
	if not FileAccess.file_exists(ACHIEVEMENT_BADGE_ATLAS_PATH):
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = load(ACHIEVEMENT_BADGE_ATLAS_PATH)
	atlas.region = ACHIEVEMENT_BADGE_REGIONS.get(tier, ACHIEVEMENT_BADGE_REGIONS[0])
	return atlas


func _badge_icon_color(tier: int) -> Color:
	if tier == AchievementManager.Tier.LOCKED:
		return Color(SOFT_TEAL, 0.88)
	return Color(DEEP_TEAL, 0.94)


func _on_achievement_unlocked(achievement: Dictionary, tier: int) -> void:
	set_hint("%s achievement: %s" % [AchievementManager.tier_name(tier), str(achievement.get("name", "Achievement"))])
	if _achievements_panel != null and _achievements_panel.visible:
		_refresh_achievements()
	_refresh_achievement_button()


func _on_achievement_unread_changed(_count: int) -> void:
	_refresh_achievement_button()


func _refresh_achievement_button() -> void:
	if _achievement_button == null or _achievement_unread_badge == null:
		return
	var count := AchievementManager.get_unread_count()
	_achievement_unread_badge.visible = count > 0
	_achievement_unread_badge.text = str(mini(count, 9))
	if count > 0:
		_achievement_button.tooltip_text = "%d new achievement updates" % count
	else:
		_achievement_button.tooltip_text = "Achievements"
	var achievement_menu := _menu_panel.find_child("AchievementMenuButton", true, false) as Button if _menu_panel else null
	if achievement_menu:
		achievement_menu.text = "ACHIEVEMENTS (%d)" % count if count > 0 else "ACHIEVEMENTS"
	var style := StyleBoxFlat.new()
	style.bg_color = DEEP_TEAL
	style.set_corner_radius_all(9)
	_achievement_unread_badge.add_theme_stylebox_override("normal", style)
	if _achievement_icon:
		_achievement_icon.queue_redraw()


func _toggle_contract_picker() -> void:
	if _contracts_popup == null:
		return
	_contracts_popup.visible = not _contracts_popup.visible
	if _contracts_popup.visible:
		_layout_popup(_contracts_popup, CONTRACT_POPUP_MAX_SIZE)
	_refresh_contracts()
	_update_contract_add_highlight()


func _toggle_challenges() -> void:
	if _challenges_popup == null:
		return
	_challenges_popup.visible = not _challenges_popup.visible
	if _challenges_popup.visible:
		_layout_popup(_challenges_popup, CHALLENGE_POPUP_MAX_SIZE)
	_refresh_challenges()


func _refresh_challenges() -> void:
	GameManager.refresh_challenge_offers(false)
	if _challenges_list == null:
		return
	for child in _challenges_list.get_children():
		child.queue_free()

	var active := GameManager.get_active_challenges()
	if not active.is_empty():
		_challenges_list.add_child(_build_challenge_section_label("ACTIVE CHALLENGES"))
		for challenge in active:
			_challenges_list.add_child(_build_challenge_card(challenge, false))

	var offers: Array[Dictionary] = []
	for offer in GameManager.get_challenge_offers():
		if GameManager.get_challenge_seconds_left(offer) > 0:
			offers.append(offer)
	_challenges_list.add_child(_build_challenge_section_label("TIMED OFFERS"))
	if offers.is_empty():
		var empty := Label.new()
		empty.text = "No challenge offers right now. New ones arrive shortly."
		empty.add_theme_color_override("font_color", TEXT_DIM)
		_challenges_list.add_child(empty)
	else:
		for offer in offers:
			_challenges_list.add_child(_build_challenge_card(offer, true))
	_style_buttons(_challenges_list)


func _build_challenge_section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(0, 30)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", MID_TEAL)
	return label


func _build_challenge_card(challenge: Dictionary, is_offer: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 148)
	_apply_panel_style(card, Color(WHITE, 0.96), PANEL_BORDER, 8, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	var thumb_panel := PanelContainer.new()
	thumb_panel.custom_minimum_size = Vector2(116, 116)
	_apply_panel_style(thumb_panel, Color(OFF_WHITE, 0.72), Color(SOFT_TEAL, 0.58), 8, 1)
	row.add_child(thumb_panel)

	var thumbnail := TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(112, 112)
	thumbnail.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := str(challenge.get("thumbnail", ""))
	if not path.is_empty():
		thumbnail.texture = load(path)
	thumb_panel.add_child(thumbnail)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 5)
	row.add_child(copy)

	var title := Label.new()
	title.text = "%s x%d" % [str(challenge.get("part_name", "Part")), int(challenge.get("quantity", 1))]
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_DARK)
	copy.add_child(title)

	var progress := int(challenge.get("progress", 0))
	var quantity := int(challenge.get("quantity", 1))
	var meta := Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	meta.text = "Progress %d/%d\nReward: $%s  +%d XP  +%d energy" % [
		progress,
		quantity,
		_format_money(int(challenge.get("reward_money", 0))),
		int(challenge.get("reward_xp", 0)),
		int(challenge.get("reward_energy", 0)),
	]
	copy.add_child(meta)

	var button := Button.new()
	button.custom_minimum_size = Vector2(124, TOUCH_TARGET)
	if is_offer:
		var seconds_left := GameManager.get_challenge_seconds_left(challenge)
		button.text = "ACCEPT\n%ds" % seconds_left
		button.disabled = seconds_left <= 0
		button.pressed.connect(_on_challenge_offer_pressed.bind(challenge))
	else:
		button.text = "ACTIVE"
		button.disabled = true
	row.add_child(button)
	return card


func _on_challenge_offer_pressed(challenge: Dictionary) -> void:
	var accepted := GameManager.accept_challenge_offer(str(challenge.get("challenge_id", "")))
	if accepted.is_empty():
		set_hint("That challenge offer expired.")
	else:
		set_hint("Challenge accepted: manufacture %d %s." % [
			int(accepted.get("quantity", 1)),
			str(accepted.get("part_name", "parts")),
		])
	if _challenges_popup:
		_challenges_popup.visible = false
	_refresh_challenges()


func _on_challenge_completed(challenge: Dictionary) -> void:
	set_hint("Challenge complete: +$%s, +%d XP, +%d energy." % [
		_format_money(int(challenge.get("reward_money", 0))),
		int(challenge.get("reward_xp", 0)),
		int(challenge.get("reward_energy", 0)),
	])
	if _challenges_popup and _challenges_popup.visible:
		_refresh_challenges()


func _refresh_contracts() -> void:
	if _refreshing_contracts:
		return
	_refreshing_contracts = true
	GameManager.refresh_contract_offers(false)
	var tier := GameManager.get_contract_tier()
	if _contracts_status:
		_contracts_status.text = "Tier %d market\nEntry buffer: %d / %d\nReputation: %.0f%%" % [
			tier,
			GameManager.samples_in_lab,
			GameManager.get_manufacturing_buffer_capacity(),
			GameManager.lab_reputation,
		]
	_refresh_active_contracts()
	if _contracts_sections == null:
		_refreshing_contracts = false
		return
	for child in _contracts_sections.get_children():
		child.queue_free()
	var catalog: Array[Dictionary] = []
	for offer in GameManager.get_contract_offers():
		if GameManager.get_offer_seconds_left(offer) > 0:
			catalog.append(offer)
	if catalog.is_empty():
		var empty := Label.new()
		empty.text = "No active offers. New offers will arrive shortly."
		empty.add_theme_color_override("font_color", TEXT_DIM)
		_contracts_sections.add_child(empty)
		_update_contract_add_highlight()
		_refreshing_contracts = false
		return
	catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var tier_a := int(a.get("tier", 1))
		var tier_b := int(b.get("tier", 1))
		if tier_a == tier_b:
			return str(a.get("name", "")) < str(b.get("name", ""))
		return tier_a < tier_b
	)
	var sections: Dictionary = {}
	for contract in catalog:
		var contract_tier := int(contract.get("tier", 1))
		if contract_tier > tier:
			continue
		if not sections.has(contract_tier):
			var section := _build_contract_section(contract_tier)
			sections[contract_tier] = section
			_contracts_sections.add_child(section)
		var grid := (sections[contract_tier] as VBoxContainer).get_node("Cards") as GridContainer
		grid.add_child(_build_contract_card(contract))
	_refresh_contract_grid_columns()
	_style_buttons(_contracts_sections)
	_refreshing_contracts = false


func _refresh_active_contracts() -> void:
	if _active_contracts_list == null:
		return
	for child in _active_contracts_list.get_children():
		child.queue_free()
	if GameManager.sample_queue.is_empty():
		var empty := Label.new()
		empty.text = "No active contracts"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", SOFT_TEAL)
		_active_contracts_list.add_child(empty)
		_update_contract_add_highlight()
		return
	var title := Label.new()
	title.text = "ACTIVE"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", TEXT_DARK)
	_active_contracts_list.add_child(title)
	for entry in GameManager.sample_queue:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		_active_contracts_list.add_child(row)

		var label := Label.new()
		label.text = "%s - %s" % [entry.get("part_name", entry.get("name", "Contract")), entry.get("stage", "")]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", MID_TEAL)
		row.add_child(label)

		var cancel := Button.new()
		cancel.text = "CANCEL"
		cancel.custom_minimum_size = Vector2(86, TOUCH_TARGET)
		cancel.disabled = bool(entry.get("broken", false))
		cancel.pressed.connect(_on_cancel_contract_pressed.bind(str(entry.get("name", ""))))
		row.add_child(cancel)
	_style_buttons(_active_contracts_list)
	_update_contract_add_highlight()


func _build_contract_section(tier: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	section.add_child(_build_contract_section_label(tier))

	var grid := GridContainer.new()
	grid.name = "Cards"
	grid.columns = _contract_grid_columns()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	section.add_child(grid)
	return section


func _build_contract_section_label(tier: int) -> Label:
	var label := Label.new()
	label.text = "TIER %d" % tier
	label.custom_minimum_size = Vector2(0, 30)
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", _tier_color(tier))
	return label


func _build_contract_card(contract: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 300)
	_apply_panel_style(card, Color(WHITE, 0.96), PANEL_BORDER, 8, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 7)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)

	var name := Label.new()
	name.text = str(contract.get("name", "Contract"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", 14)
	name.add_theme_color_override("font_color", TEXT_DARK)
	header.add_child(name)

	var tier := int(contract.get("tier", 1))
	var tier_label := Label.new()
	tier_label.text = "T%d" % tier
	tier_label.add_theme_font_size_override("font_size", 13)
	tier_label.add_theme_color_override("font_color", _tier_color(tier))
	header.add_child(tier_label)

	var thumbnail_panel := PanelContainer.new()
	thumbnail_panel.custom_minimum_size = Vector2(0, 128)
	thumbnail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(thumbnail_panel, Color(OFF_WHITE, 0.68), Color(SOFT_TEAL, 0.58), 8, 1)
	vbox.add_child(thumbnail_panel)

	var thumbnail := TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(0, 128)
	thumbnail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thumbnail.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thumbnail_path := str(contract.get("thumbnail", ""))
	if not thumbnail_path.is_empty():
		thumbnail.texture = load(thumbnail_path)
	thumbnail_panel.add_child(thumbnail)

	var description := Label.new()
	description.text = str(contract.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.custom_minimum_size = Vector2(0, 40)
	description.add_theme_font_size_override("font_size", 13)
	description.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(description)

	var sell := int(contract.get("sell_price", 0))
	var cost := int(contract.get("manufacture_cost", 0))
	var batch_size := int(contract.get("batch_size", 1))
	var seconds_left := GameManager.get_offer_seconds_left(contract)
	var economics := Label.new()
	var margin_per_part := int(contract.get("margin", sell - cost))
	economics.text = "Batch %d   Sell $%s   Cost $%s\nMargin $%s/part   Total $%s   Rep %.0f%%   %ds left" % [
		batch_size,
		_format_money(sell),
		_format_money(cost),
		_format_money(margin_per_part),
		_format_money(margin_per_part * batch_size),
		float(contract.get("satisfaction_required", 0.0)),
		seconds_left,
	]
	economics.add_theme_font_size_override("font_size", 13)
	economics.add_theme_color_override("font_color", MID_TEAL)
	vbox.add_child(economics)

	var button := Button.new()
	var disabled_reason := _contract_disabled_reason(cost, batch_size, seconds_left)
	button.text = "EXPIRED" if seconds_left <= 0 else "ACCEPT"
	if not disabled_reason.is_empty() and seconds_left > 0:
		button.tooltip_text = disabled_reason
	button.custom_minimum_size = Vector2(0, TOUCH_TARGET)
	button.disabled = seconds_left <= 0
	button.pressed.connect(_on_contract_selected.bind(contract))
	vbox.add_child(button)
	return card


func _contract_disabled_reason(cost: int, batch_size: int, seconds_left: int) -> String:
	if seconds_left <= 0:
		return "EXPIRED"
	if GameManager.get_manufacturing_free_slots() < batch_size:
		return "BUFFER FULL"
	if GameManager.player_money < cost * batch_size:
		return "NEED $%s" % _format_money(cost * batch_size)
	return ""


func _on_contract_selected(contract: Dictionary) -> void:
	var cost := int(contract.get("manufacture_cost", 0))
	var batch_size := int(contract.get("batch_size", 1))
	if GameManager.get_manufacturing_free_slots() < batch_size:
		set_hint("Entry buffer is full.")
		return
	if GameManager.player_money < cost * batch_size:
		set_hint("Not enough money for manufacturing cost.")
		GameManager.refresh_contract_offers(true)
		return
	var accepted_offer := GameManager.try_accept_contract_offer(str(contract.get("offer_id", "")))
	if accepted_offer.is_empty():
		set_hint("That offer expired, was already taken, or cannot fit right now.")
		GameManager.refresh_contract_offers(true)
		_refresh_contracts()
		return
	var lab := get_lab_root()
	var spawned := 0
	if lab and lab.has_method("spawn_contract_batch"):
		spawned = int(lab.spawn_contract_batch(accepted_offer))
	if spawned <= 0:
		GameManager.refund_contract_acceptance(accepted_offer)
		set_hint("Could not place the samples in the lab. Try again.")
		GameManager.refresh_contract_offers(true)
		_refresh_contracts()
		return
	if spawned > 0:
		GameManager.record_contract_accepted(accepted_offer)
	set_hint("%s accepted. %d batch queued. Manufacturing cost: $%s." % [
		str(accepted_offer.get("name", "Contract")),
		spawned,
		_format_money(cost * batch_size),
	])
	if _contracts_popup:
		_contracts_popup.visible = false
	_refresh_contracts()


func _on_cancel_contract_pressed(order_id: String) -> void:
	var lab := get_lab_root()
	if lab and lab.has_method("cancel_contract_order") and lab.cancel_contract_order(order_id):
		set_hint("Contract cancelled.")
	else:
		set_hint("This contract can no longer be cancelled.")
	_refresh_contracts()


func _tier_color(tier: int) -> Color:
	match tier:
		1:
			return Color(0.5, 0.95, 0.2)
		2:
			return Color(1.0, 0.86, 0.05)
		3:
			return Color(1.0, 0.5, 0.0)
		4:
			return Color(1.0, 0.28, 0.35)
	return CYAN


func _build_shop_row(device_key: String, data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = SHOP_CARD_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(card, Color(WHITE, 0.96), PANEL_BORDER, 8, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(0, SHOP_THUMBNAIL_PANEL_HEIGHT)
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(preview_panel, Color(OFF_WHITE, 0.72), Color(SOFT_TEAL, 0.7), 8, 1)
	vbox.add_child(preview_panel)

	var display_size := _shop_device_thumbnail_size(device_key)
	var preview := _build_shop_thumbnail(
		str(SHOP_DEVICE_IMAGES.get(device_key, "")),
		display_size,
		device_key == "truck",
		Color(1.18, 1.18, 1.18, 1.0) if device_key == "truck" else Color.WHITE
	)
	preview_panel.add_child(preview)

	var title := Label.new()
	title.text = str(data.get("title", device_key.capitalize()))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_DARK)
	vbox.add_child(title)

	var meta := Label.new()
	meta.name = "Meta"
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.custom_minimum_size = Vector2(0, 44)
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(meta)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button := Button.new()
	button.name = "ActionButton"
	button.custom_minimum_size = Vector2(0, TOUCH_TARGET)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(_on_shop_action_pressed.bind(device_key))
	vbox.add_child(button)

	_shop_rows[device_key] = {
		"type": "device",
		"meta": meta,
		"button": button,
	}
	return card


func _build_personnel_row(personnel_key: String, data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = SHOP_CARD_SIZE
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(card, Color(WHITE, 0.96), PANEL_BORDER, 8, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(0, SHOP_THUMBNAIL_PANEL_HEIGHT)
	preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(preview_panel, Color(OFF_WHITE, 0.72), Color(SOFT_TEAL, 0.7), 8, 1)
	vbox.add_child(preview_panel)

	var icon := _build_shop_thumbnail(
		str(SHOP_PERSONNEL_IMAGES.get(personnel_key, "")),
		_shop_personnel_thumbnail_size(personnel_key),
		false,
		Color.WHITE
	)
	preview_panel.add_child(icon)

	var title := Label.new()
	title.text = str(data.get("title", personnel_key.capitalize()))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_DARK)
	vbox.add_child(title)

	var meta := Label.new()
	meta.name = "Meta"
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.custom_minimum_size = Vector2(0, 58)
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(meta)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 8)
	vbox.add_child(actions)

	var train_button := Button.new()
	train_button.name = "TrainButton"
	train_button.custom_minimum_size = Vector2(0, TOUCH_TARGET)
	train_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	train_button.pressed.connect(_on_personnel_action_pressed.bind(personnel_key))
	actions.add_child(train_button)

	var employ_button := Button.new()
	employ_button.name = "EmployButton"
	employ_button.custom_minimum_size = Vector2(0, TOUCH_TARGET)
	employ_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	employ_button.pressed.connect(_on_personnel_employ_pressed.bind(personnel_key))
	actions.add_child(employ_button)

	_shop_rows[personnel_key] = {
		"type": "personnel",
		"meta": meta,
		"button": train_button,
		"employ_button": employ_button,
	}
	return card


func _build_shop_thumbnail(path: String, display_size: Vector2, flip_h: bool, tint: Color) -> CenterContainer:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, SHOP_THUMBNAIL_PANEL_HEIGHT)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var texture := TextureRect.new()
	texture.custom_minimum_size = display_size
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.texture = _texture_from_png(path)
	texture.flip_h = flip_h
	texture.modulate = tint
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(texture)
	return center


func _shop_device_thumbnail_size(device_key: String) -> Vector2:
	match device_key:
		"extraction":
			return Vector2(96, 152)
		"drying":
			return Vector2(112, 100)
		"microscope":
			return Vector2(74, 118)
		"truck":
			return Vector2(156, 124)
	return Vector2(128, 128)


func _shop_personnel_thumbnail_size(personnel_key: String) -> Vector2:
	match personnel_key:
		"lab_manager":
			return Vector2(78, 150)
		"labor_worker":
			return Vector2(82, 158)
	return Vector2(82, 158)


func _build_truck_button() -> TextureButton:
	var button := TextureButton.new()
	button.name = "SendTruckImageButton"
	button.tooltip_text = "Send truck"
	button.custom_minimum_size = Vector2(0, 116)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	var texture := _texture_from_png(TRUCK_BUTTON_PATH)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.texture_click_mask = _make_alpha_click_mask(TRUCK_BUTTON_PATH)
	button.pressed.connect(_on_send_truck_pressed)
	return button


func _make_alpha_click_mask(path: String) -> BitMap:
	var image := Image.load_from_file(path)
	if image == null:
		return null
	var mask := BitMap.new()
	mask.create_from_image_alpha(image, 0.1)
	return mask


func _texture_from_png(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		var imported_texture := load(path) as Texture2D
		if imported_texture:
			return imported_texture
	var image := Image.load_from_file(path)
	if image == null:
		return null
	return ImageTexture.create_from_image(image)


func _apply_panel_style(panel: PanelContainer, bg: Color, border: Color, radius: int, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	panel.add_theme_stylebox_override("panel", style)


func _style_labels(root: Node) -> void:
	for child in root.get_children():
		if child is Label:
			var label := child as Label
			if not label.has_theme_color_override("font_color"):
				label.add_theme_color_override("font_color", TEXT_DIM)
		_style_labels(child)


func _style_progress_bars(root: Node) -> void:
	for child in root.get_children():
		if child is ProgressBar:
			var bar := child as ProgressBar
			var bg := StyleBoxFlat.new()
			bg.bg_color = Color(SOFT_TEAL, 0.32)
			bg.set_corner_radius_all(2)
			var fill := StyleBoxFlat.new()
			fill.bg_color = CYAN
			fill.set_corner_radius_all(2)
			bar.add_theme_stylebox_override("background", bg)
			bar.add_theme_stylebox_override("fill", fill)
		_style_progress_bars(child)


func _style_buttons(root: Node) -> void:
	for child in root.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, TOUCH_TARGET)
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_stylebox_override("normal", _button_style(Color(WHITE, 0.96), PANEL_BORDER))
			button.add_theme_stylebox_override("hover", _button_style(OFF_WHITE, MINT_ACCENT))
			button.add_theme_stylebox_override("pressed", _button_style(Color(MINT_ACCENT, 0.72), MINT_ACCENT))
			button.add_theme_color_override("font_color", DEEP_TEAL)
			button.add_theme_color_override("font_hover_color", MID_TEAL)
			if not button.is_connected("pressed", _play_ui_click):
				button.pressed.connect(_play_ui_click)
		_style_buttons(child)


func _button_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_top = 6.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 6.0
	return style


func _refresh_shipping() -> void:
	if _shipping_status == null:
		return
	var count := GameManager.get_staged_part_count()
	_shipping_status.text = "TRUCK READY\n%d / %d PARTS" % [count, GameManager.get_truck_capacity()]
	_shipping_payout.text = "CUSTOMER PAYMENT $ %s" % _format_money(GameManager.get_staged_part_total())
	if _send_truck_button:
		_send_truck_button.disabled = count == 0
		_send_truck_button.modulate = Color(1.0, 1.0, 1.0, 1.0 if count > 0 else 0.42)


func _on_send_truck_pressed() -> void:
	var payout := GameManager.send_truck()
	if payout > 0:
		set_hint("Truck sent. Payment received: $%s." % _format_money(payout))
	else:
		set_hint("Load a finished part before sending the truck.")


func _toggle_shop() -> void:
	if _shop_panel == null:
		return
	_shop_panel.visible = not _shop_panel.visible
	if _shop_panel.visible:
		_layout_popup(_shop_panel, SHOP_POPUP_MAX_SIZE)
	_refresh_shop()


func _on_shop_action_pressed(device_key: String) -> void:
	if not GameManager.is_device_owned(device_key):
		if GameManager.purchase_device(device_key):
			set_hint("%s purchased." % _device_title(device_key))
		else:
			set_hint("Not enough money to purchase %s." % _device_title(device_key))
		return
	if GameManager.upgrade_device(device_key):
		set_hint("%s upgraded to level %d." % [_device_title(device_key), GameManager.get_device_level(device_key)])
	elif GameManager.get_device_level(device_key) >= GameManager.get_device_max_level(device_key):
		set_hint("%s is already at max level." % _device_title(device_key))
	elif not GameManager.can_upgrade_device_by_level(device_key):
		set_hint("%s requires player level %d for the next upgrade." % [
			_device_title(device_key),
			GameManager.get_device_upgrade_required_player_level(device_key),
		])
	else:
		set_hint("Not enough money to upgrade %s." % _device_title(device_key))


func _on_personnel_action_pressed(personnel_key: String) -> void:
	if GameManager.upgrade_personnel(personnel_key):
		set_hint("%s upgraded to level %d." % [_personnel_title(personnel_key), GameManager.get_personnel_level(personnel_key)])
	elif GameManager.get_personnel_level(personnel_key) >= GameManager.get_personnel_max_level(personnel_key):
		set_hint("%s is already fully trained." % _personnel_title(personnel_key))
	elif not GameManager.can_upgrade_personnel_by_level(personnel_key):
		set_hint("%s requires player level %d for the next phase." % [
			_personnel_title(personnel_key),
			GameManager.get_personnel_upgrade_required_player_level(personnel_key),
		])
	else:
		set_hint("Not enough money to train %s." % _personnel_title(personnel_key))


func _on_personnel_employ_pressed(personnel_key: String) -> void:
	if GameManager.is_personnel_employed(personnel_key):
		if GameManager.fire_personnel(personnel_key):
			set_hint("%s fired. Automation disabled." % _personnel_title(personnel_key))
		return
	if GameManager.employ_personnel(personnel_key):
		set_hint("%s employed. Automation enabled." % _personnel_title(personnel_key))
	elif GameManager.get_personnel_level(personnel_key) <= 0:
		set_hint("Train %s before employing them." % _personnel_title(personnel_key))
	else:
		set_hint("Not enough money to employ %s." % _personnel_title(personnel_key))


func _refresh_shop() -> void:
	for key in _shop_rows.keys():
		var row: Dictionary = _shop_rows[key]
		var meta := row.get("meta") as Label
		var button := row.get("button") as Button
		if meta == null or button == null:
			continue
		if str(row.get("type", "device")) == "personnel":
			var employ_button := row.get("employ_button") as Button
			_refresh_personnel_shop_row(key, meta, button, employ_button)
			continue
		var owned := GameManager.is_device_owned(key)
		var level := GameManager.get_device_level(key)
		if not owned:
			var purchase_cost := GameManager.get_device_purchase_cost(key)
			meta.text = "Not installed"
			button.text = "BUY $%s" % _format_money(purchase_cost)
			button.disabled = GameManager.player_money < purchase_cost
			continue
		var max_level := GameManager.get_device_max_level(key)
		if level >= max_level:
			meta.text = "Level %d / %d - flagship model" % [level, max_level]
			button.text = "MAX"
			button.disabled = true
		else:
			var upgrade_cost := GameManager.get_device_upgrade_cost(key)
			var required_level := GameManager.get_device_upgrade_required_player_level(key)
			meta.text = "Level %d / %d - %s - next $%s - requires player Lv %d" % [
				level,
				max_level,
				_device_capacity_text(key),
				_format_money(upgrade_cost),
				required_level,
			]
			button.text = "UPGRADE"
			button.disabled = GameManager.player_money < upgrade_cost or not GameManager.can_upgrade_device_by_level(key)


func _refresh_personnel_shop_row(personnel_key: String, meta: Label, train_button: Button, employ_button: Button) -> void:
	var level := GameManager.get_personnel_level(personnel_key)
	var max_level := GameManager.get_personnel_max_level(personnel_key)
	var catalog := GameManager.get_personnel_catalog()
	var data: Dictionary = catalog.get(personnel_key, {})
	var phase_text: Array = data.get("phase_text", [])
	var employed := GameManager.is_personnel_employed(personnel_key)
	var employment_text := "Employed" if employed else "Not employed"
	if level >= max_level:
		meta.text = "%s - level %d / %d - all automation phases trained" % [employment_text, level, max_level]
		train_button.text = "MAX"
		train_button.disabled = true
	else:
		var upgrade_cost := GameManager.get_personnel_upgrade_cost(personnel_key)
		var required_level := GameManager.get_personnel_upgrade_required_player_level(personnel_key)
		var next_text := str(phase_text[level]) if level < phase_text.size() else "Additional automation"
		meta.text = "%s - level %d / %d - training $%s - requires player Lv %d\n%s" % [
			employment_text,
			level,
			max_level,
			_format_money(upgrade_cost),
			required_level,
			next_text,
		]
		train_button.text = "TRAIN"
		train_button.disabled = GameManager.player_money < upgrade_cost or not GameManager.can_upgrade_personnel_by_level(personnel_key)
	if employ_button == null:
		return
	var employ_cost := GameManager.get_personnel_employ_cost(personnel_key)
	if employed:
		employ_button.text = "FIRE"
		employ_button.disabled = false
	else:
		employ_button.text = "EMPLOY $%s" % _format_money(employ_cost)
		employ_button.disabled = level <= 0 or GameManager.player_money < employ_cost


func _on_device_changed(_device_key: String) -> void:
	_refresh_shop()


func _on_personnel_changed(_personnel_key: String) -> void:
	_refresh_shop()


func _device_title(device_key: String) -> String:
	var catalog := GameManager.get_device_catalog()
	var data: Dictionary = catalog.get(device_key, {})
	return str(data.get("title", device_key.capitalize()))


func _personnel_title(personnel_key: String) -> String:
	var catalog := GameManager.get_personnel_catalog()
	var data: Dictionary = catalog.get(personnel_key, {})
	return str(data.get("title", personnel_key.capitalize()))


func _device_capacity_text(device_key: String) -> String:
	if device_key == "truck":
		return "capacity %d" % GameManager.get_truck_capacity()
	return "slots %d" % GameManager.get_station_capacity(device_key)


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
