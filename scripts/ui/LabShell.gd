class_name LabShell
extends Control
## Landscape dashboard shell (mockup layout): header, lab view, sidebar, bottom panels.

const CYAN := Color(0.0, 0.58, 0.52)
const PANEL_BG := Color(0.96, 0.99, 0.98, 0.92)
const PANEL_BG_SOFT := Color(0.92, 0.98, 0.96, 0.88)
const PANEL_BORDER := Color(0.46, 0.78, 0.72, 0.72)
const TEXT_DARK := Color(0.07, 0.16, 0.16)
const TEXT_DIM := Color(0.28, 0.42, 0.42)
const MINT_WASH := Color(0.84, 0.96, 0.92, 0.86)
const MUSIC_LOOP_PATH := "res://assets/audio/733259__jadis0x__simple-video-game-music-loop.wav"
const SHOP_DEVICE_IMAGES := {
	"extraction": "res://assets/shop/extraction_thumbnail.png",
	"drying": "res://assets/shop/drying_thumbnail.png",
	"microscope": "res://assets/shop/microscope_thumbnail.png",
	"truck": "res://assets/ui/ImageDataSet_CleanLab_Truck.png",
}

@onready var _header: HeaderBar = %HeaderBar
@onready var _sidebar: StationSidebar = %StationSidebar
@onready var _sample_queue: SampleQueuePanel = %SampleQueuePanel
@onready var _microscope_dock: MicroscopeDock = %MicroscopeDock
@onready var _lab_viewport: SubViewport = %LabViewport

var _shipping_status: Label = null
var _shipping_payout: Label = null
var _send_truck_button: Button = null
var _contracts_status: Label = null
var _active_contracts_list: VBoxContainer = null
var _contracts_popup: PanelContainer = null
var _contracts_sections: VBoxContainer = null
var _shop_panel: PanelContainer = null
var _shop_rows: Dictionary = {}
var _offer_refresh_accumulator: float = 0.0
var _music_player: AudioStreamPlayer = null
var _mute_button: Button = null
var _mute_icon: Control = null
var _music_muted: bool = false


func _ready() -> void:
	add_to_group("lab_shell")
	_apply_reference_skin()
	_add_music_loop()
	_add_mute_button()
	_add_shipping_panel()
	_add_contract_picker_popup()
	_add_device_shop_panel()
	GameManager.economy_changed.connect(_refresh_header)
	GameManager.economy_changed.connect(_refresh_contracts)
	GameManager.economy_changed.connect(_refresh_shop)
	GameManager.sample_queue_changed.connect(_refresh_header)
	GameManager.sample_queue_changed.connect(_refresh_contracts)
	GameManager.contract_offers_changed.connect(_refresh_contracts)
	GameManager.device_changed.connect(_on_device_changed)
	GameManager.device_changed.connect(func(_key: String) -> void: _refresh_shipping())
	GameManager.shipping_changed.connect(_refresh_shipping)
	GameManager.layer_changed.connect(_on_layer_changed)
	GameManager.delivery_completed.connect(_on_delivery)
	GameManager.problem_inspection_requested.connect(_on_problem_inspection)
	GameManager.problem_inspection_resolved.connect(_on_problem_resolved)
	_refresh_header()
	_refresh_contracts()
	_refresh_shipping()
	_refresh_shop()
	_on_layer_changed(GameManager.game_layer)
	set_hint("Tap the sample to start extraction.")


func _add_music_loop() -> void:
	if _music_player != null:
		return
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicLoop"
	_music_player.bus = "Master"
	_music_player.volume_db = -7.0
	var stream := load(MUSIC_LOOP_PATH)
	if stream is AudioStreamWAV:
		stream = (stream as AudioStreamWAV).duplicate()
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	add_child(_music_player)
	call_deferred("_start_music_loop")


func _start_music_loop() -> void:
	if _music_player and _music_player.stream:
		_music_player.play()


func _add_mute_button() -> void:
	if _mute_button != null:
		return
	var header_row := get_node_or_null("VBox/HeaderBar/Margin/HBox") as HBoxContainer
	if header_row == null:
		return
	_mute_button = Button.new()
	_mute_button.name = "MuteButton"
	_mute_button.tooltip_text = "Mute music"
	_mute_button.custom_minimum_size = Vector2(42, 42)
	_mute_button.pressed.connect(_toggle_music_mute)
	header_row.add_child(_mute_button)
	_style_buttons(_mute_button)

	_mute_icon = Control.new()
	_mute_icon.name = "SpeakerIcon"
	_mute_icon.custom_minimum_size = Vector2(24, 24)
	_mute_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mute_icon.draw.connect(_draw_mute_icon)
	_mute_button.add_child(_mute_icon)
	_center_mute_icon()
	_style_icon_button(_mute_button)


func _toggle_music_mute() -> void:
	_music_muted = not _music_muted
	if _music_player:
		_music_player.stream_paused = _music_muted
	if _mute_button:
		_mute_button.tooltip_text = "Unmute music" if _music_muted else "Mute music"
	if _mute_icon:
		_mute_icon.queue_redraw()


func _center_mute_icon() -> void:
	if _mute_button == null or _mute_icon == null:
		return
	_mute_icon.position = (_mute_button.custom_minimum_size - _mute_icon.custom_minimum_size) * 0.5


func _style_icon_button(button: Button) -> void:
	var transparent := _button_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))
	var hover := _button_style(Color(0.78, 0.94, 0.9, 0.38), Color(0, 0, 0, 0))
	var pressed := _button_style(Color(0.68, 0.9, 0.84, 0.5), Color(0, 0, 0, 0))
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", transparent)
	button.focus_mode = Control.FOCUS_NONE


func _draw_mute_icon() -> void:
	if _mute_icon == null:
		return
	var stroke := Color(0.0, 0.36, 0.33)
	var muted_stroke := Color(0.55, 0.64, 0.62)
	var color := muted_stroke if _music_muted else stroke
	var width := 2.2
	var body := PackedVector2Array([
		Vector2(4, 10),
		Vector2(8, 10),
		Vector2(14, 5),
		Vector2(14, 19),
		Vector2(8, 14),
		Vector2(4, 14),
	])
	_mute_icon.draw_colored_polygon(body, Color(color, 0.14))
	_mute_icon.draw_polyline(body, color, width, true)
	if _music_muted:
		_mute_icon.draw_line(Vector2(17, 8), Vector2(22, 16), color, width, true)
		_mute_icon.draw_line(Vector2(22, 8), Vector2(17, 16), color, width, true)
	else:
		_mute_icon.draw_arc(Vector2(14, 12), 5.0, -0.8, 0.8, 12, color, width, true)
		_mute_icon.draw_arc(Vector2(14, 12), 8.0, -0.75, 0.75, 16, color, width, true)


func _process(delta: float) -> void:
	_offer_refresh_accumulator += delta
	if _offer_refresh_accumulator < 1.0:
		return
	_offer_refresh_accumulator = 0.0
	GameManager.refresh_contract_offers(false)
	if _contracts_popup != null and _contracts_popup.visible:
		_refresh_contracts()


func get_lab_root() -> Node2D:
	return _lab_viewport.get_node("LaboratoryRoom") as Node2D


func set_hint(text: String) -> void:
	_sample_queue.set_status_line(text)


func _refresh_header() -> void:
	_header.refresh()


func _on_layer_changed(layer: GameManager.GameLayer) -> void:
	var show_dock := layer == GameManager.GameLayer.MICROSCOPY
	_microscope_dock.visible = show_dock
	_microscope_dock.set_active(show_dock)


func _on_delivery(payout: int) -> void:
	set_hint("Truck departed — +$%d. Next sample incoming." % payout)


func _on_problem_inspection(_part: Part, _claims: Array) -> void:
	set_hint("QC problem — verify particle in inspection overlay.")


func _on_problem_resolved(_part: Part, _passed: bool) -> void:
	set_hint("QC resolved. Collect report and ship to truck.")


func _apply_reference_skin() -> void:
	add_theme_color_override("font_color", TEXT_DARK)
	var background := get_node_or_null("Background") as ColorRect
	if background:
		background.color = Color(0.94, 0.985, 0.965)
	_apply_panel_style(_header, Color(0.98, 1.0, 0.99, 0.94), PANEL_BORDER, 0, 1)
	_apply_panel_style(_sidebar, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_sample_queue, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_microscope_dock, PANEL_BG, PANEL_BORDER, 8, 1)
	var viewport_panel := get_node_or_null("VBox/MiddleRow/LabViewportContainer") as PanelContainer
	if viewport_panel:
		_apply_panel_style(viewport_panel, Color.WHITE, Color(0.92, 0.96, 0.94, 1.0), 4, 1)
	var subviewport_container := get_node_or_null("VBox/MiddleRow/LabViewportContainer/SubViewportContainer") as SubViewportContainer
	if subviewport_container:
		subviewport_container.self_modulate = Color.WHITE
	var lab_viewport := get_node_or_null("VBox/MiddleRow/LabViewportContainer/SubViewportContainer/LabViewport") as SubViewport
	if lab_viewport:
		lab_viewport.transparent_bg = true
	var bottom_nav := get_node_or_null("VBox/BottomNav") as PanelContainer
	if bottom_nav:
		_apply_panel_style(bottom_nav, Color(0.9, 0.98, 0.95, 0.94), PANEL_BORDER, 0, 1)
		_style_nav_buttons(bottom_nav)
	_style_labels(self)
	_style_progress_bars(self)
	_style_buttons(self)
	var title := Label.new()
	title.name = "BrandTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "CLEANLAB\nTECHNICAL CLEANLINESS SIMULATOR"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", TEXT_DARK)
	title.position = Vector2(20, 9)
	title.size = Vector2(260, 56)
	add_child(title)


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

	var truck := _build_truck_visual()
	vbox.add_child(truck)

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

	_send_truck_button = Button.new()
	_send_truck_button.text = "SEND TRUCK"
	_send_truck_button.custom_minimum_size = Vector2(0, 42)
	_send_truck_button.pressed.connect(_on_send_truck_pressed)
	vbox.add_child(_send_truck_button)
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
	add_button.text = "+"
	add_button.custom_minimum_size = Vector2(42, 38)
	add_button.add_theme_font_size_override("font_size", 22)
	add_button.pressed.connect(_toggle_contract_picker)
	header.add_child(add_button)

	_contracts_status = Label.new()
	_contracts_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_contracts_status.add_theme_font_size_override("font_size", 13)
	_contracts_status.add_theme_color_override("font_color", TEXT_DIM)
	vbox.add_child(_contracts_status)

	var hint := Label.new()
	hint.text = "Check timed offers and accept work when the margin is worth the buffer space."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.0, 0.45, 0.4, 0.86))
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
	_contracts_popup.position = Vector2(250, 96)
	_contracts_popup.size = Vector2(980, 590)
	_contracts_popup.z_index = 35
	_apply_panel_style(_contracts_popup, Color(0.965, 0.995, 0.985, 0.98), PANEL_BORDER, 12, 1)
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
	close.custom_minimum_size = Vector2(96, 40)
	close.pressed.connect(_toggle_contract_picker)
	header.add_child(close)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_contracts_sections = VBoxContainer.new()
	_contracts_sections.add_theme_constant_override("separation", 16)
	scroll.add_child(_contracts_sections)
	_style_buttons(_contracts_popup)


func _add_device_shop_panel() -> void:
	if has_node("DeviceShopPanel"):
		return
	_shop_panel = PanelContainer.new()
	_shop_panel.name = "DeviceShopPanel"
	_shop_panel.visible = false
	_shop_panel.position = Vector2(520, 128)
	_shop_panel.size = Vector2(680, 520)
	_shop_panel.z_index = 30
	_apply_panel_style(_shop_panel, Color(0.965, 0.995, 0.985, 0.98), PANEL_BORDER, 16, 1)
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
	close.custom_minimum_size = Vector2(96, 40)
	close.pressed.connect(_toggle_shop)
	header.add_child(close)

	var catalog := GameManager.get_device_catalog()
	for key in ["extraction", "drying", "microscope", "truck"]:
		var row := _build_shop_row(key, catalog.get(key, {}))
		vbox.add_child(row)

	var shop_button := get_node_or_null("VBox/BottomNav/NavHBox/EscalationsTab") as Button
	if shop_button:
		shop_button.pressed.connect(_toggle_shop)
	_style_buttons(_shop_panel)


func _toggle_contract_picker() -> void:
	if _contracts_popup == null:
		return
	_contracts_popup.visible = not _contracts_popup.visible
	_refresh_contracts()


func _refresh_contracts() -> void:
	var tier := GameManager.get_contract_tier()
	if _contracts_status:
		_contracts_status.text = "Tier %d market\nManufacturing buffer: %d / %d\nReputation: %.0f%%" % [
			tier,
			GameManager.samples_in_lab,
			GameManager.get_manufacturing_buffer_capacity(),
			GameManager.lab_reputation,
		]
	_refresh_active_contracts()
	if _contracts_sections == null:
		return
	for child in _contracts_sections.get_children():
		child.queue_free()
	var catalog := GameManager.get_contract_offers()
	if catalog.is_empty():
		var empty := Label.new()
		empty.text = "No active offers. New offers will arrive shortly."
		empty.add_theme_color_override("font_color", TEXT_DIM)
		_contracts_sections.add_child(empty)
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
	_style_buttons(_contracts_sections)


func _refresh_active_contracts() -> void:
	if _active_contracts_list == null:
		return
	for child in _active_contracts_list.get_children():
		child.queue_free()
	if GameManager.sample_queue.is_empty():
		var empty := Label.new()
		empty.text = "No active contracts"
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.42, 0.55, 0.54))
		_active_contracts_list.add_child(empty)
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
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.12, 0.34, 0.32))
		row.add_child(label)

		var cancel := Button.new()
		cancel.text = "CANCEL"
		cancel.custom_minimum_size = Vector2(76, 28)
		cancel.disabled = bool(entry.get("broken", false))
		cancel.pressed.connect(_on_cancel_contract_pressed.bind(str(entry.get("name", ""))))
		row.add_child(cancel)
	_style_buttons(_active_contracts_list)


func _build_contract_section(tier: int) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	section.add_child(_build_contract_section_label(tier))

	var grid := GridContainer.new()
	grid.name = "Cards"
	grid.columns = 3
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
	card.custom_minimum_size = Vector2(300, 180)
	_apply_panel_style(card, Color(0.985, 1.0, 0.99, 0.96), PANEL_BORDER, 8, 1)

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

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	vbox.add_child(body)

	var thumbnail := TextureRect.new()
	thumbnail.custom_minimum_size = Vector2(92, 72)
	thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var thumbnail_path := str(contract.get("thumbnail", ""))
	if not thumbnail_path.is_empty():
		thumbnail.texture = load(thumbnail_path)
	body.add_child(thumbnail)

	var description := Label.new()
	description.text = str(contract.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 12)
	description.add_theme_color_override("font_color", TEXT_DIM)
	body.add_child(description)

	var sell := int(contract.get("sell_price", 0))
	var cost := int(contract.get("manufacture_cost", 0))
	var batch_size := int(contract.get("batch_size", 1))
	var seconds_left := GameManager.get_offer_seconds_left(contract)
	var economics := Label.new()
	economics.text = "Batch %d   Sell $%s   Cost $%s\nMargin $%s   Reputation %.0f%%   %ds left" % [
		batch_size,
		_format_money(sell),
		_format_money(cost),
		_format_money(int(contract.get("margin", sell - cost))),
		float(contract.get("satisfaction_required", 0.0)),
		seconds_left,
	]
	economics.add_theme_font_size_override("font_size", 12)
	economics.add_theme_color_override("font_color", Color(0.0, 0.42, 0.38))
	vbox.add_child(economics)

	var button := Button.new()
	button.text = "ACCEPT"
	button.custom_minimum_size = Vector2(0, 36)
	button.disabled = GameManager.player_money < cost * batch_size or GameManager.get_manufacturing_free_slots() < batch_size or seconds_left <= 0
	button.pressed.connect(_on_contract_selected.bind(contract))
	vbox.add_child(button)
	return card


func _on_contract_selected(contract: Dictionary) -> void:
	var cost := int(contract.get("manufacture_cost", 0))
	var batch_size := int(contract.get("batch_size", 1))
	if GameManager.get_manufacturing_free_slots() < batch_size:
		set_hint("Manufacturing buffer is full.")
		return
	var accepted_offer := GameManager.accept_contract_offer(str(contract.get("offer_id", "")))
	if accepted_offer.is_empty():
		set_hint("That offer expired.")
		return
	if not GameManager.pay_manufacture_cost(cost * batch_size):
		set_hint("Not enough money for manufacturing cost.")
		GameManager.refresh_contract_offers(true)
		return
	var lab := get_lab_root()
	var spawned := 0
	if lab and lab.has_method("spawn_contract_batch"):
		spawned = int(lab.spawn_contract_batch(accepted_offer))
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
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 148)
	_apply_panel_style(row, Color(0.985, 1.0, 0.99, 0.96), PANEL_BORDER, 10, 1)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(170, 112)
	_apply_panel_style(preview_panel, Color(0.93, 0.985, 0.965, 0.72), Color(0.68, 0.86, 0.8, 0.7), 8, 1)
	hbox.add_child(preview_panel)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(170, 112)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture = load(str(SHOP_DEVICE_IMAGES.get(device_key, "")))
	if device_key == "truck":
		preview.flip_h = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_panel.add_child(preview)

	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(copy)

	var title := Label.new()
	title.text = str(data.get("title", device_key.capitalize()))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", TEXT_DARK)
	copy.add_child(title)

	var meta := Label.new()
	meta.name = "Meta"
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", TEXT_DIM)
	copy.add_child(meta)

	var button := Button.new()
	button.name = "ActionButton"
	button.custom_minimum_size = Vector2(150, 56)
	button.pressed.connect(_on_shop_action_pressed.bind(device_key))
	hbox.add_child(button)

	_shop_rows[device_key] = {
		"meta": meta,
		"button": button,
	}
	return row


func _build_truck_visual() -> Control:
	var truck := TextureRect.new()
	truck.custom_minimum_size = Vector2(0, 76)
	truck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	truck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	truck.texture = load("res://assets/ui/ImageDataSet_CleanLab_Truck.png")
	truck.flip_h = true
	truck.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return truck


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
			bg.bg_color = Color(0.82, 0.92, 0.9, 0.95)
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
			button.add_theme_stylebox_override("normal", _button_style(Color(0.95, 0.995, 0.98, 0.96), PANEL_BORDER))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.84, 0.97, 0.93, 0.98), CYAN))
			button.add_theme_stylebox_override("pressed", _button_style(Color(0.68, 0.9, 0.84, 0.98), CYAN))
			button.add_theme_color_override("font_color", Color(0.0, 0.34, 0.31))
			button.add_theme_color_override("font_hover_color", Color(0.0, 0.48, 0.44))
		_style_buttons(child)


func _style_nav_buttons(bottom_nav: PanelContainer) -> void:
	var lab_tab := bottom_nav.get_node_or_null("NavHBox/LabTab") as Button
	if lab_tab:
		lab_tab.add_theme_stylebox_override("normal", _button_style(Color(0.75, 0.94, 0.88, 0.96), CYAN))
		lab_tab.add_theme_color_override("font_color", CYAN)


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
	var count := GameManager.get_staged_report_count()
	_shipping_status.text = "TRUCK READY\n%d / %d REPORTS" % [count, GameManager.get_truck_capacity()]
	_shipping_payout.text = "PAYMENT $ %s" % _format_money(GameManager.get_staged_report_total())
	_send_truck_button.disabled = count == 0


func _on_send_truck_pressed() -> void:
	var payout := GameManager.send_truck()
	if payout > 0:
		set_hint("Truck sent. Payment received: $%s." % _format_money(payout))
	else:
		set_hint("Stage a report at Reports Out first.")


func _toggle_shop() -> void:
	if _shop_panel == null:
		return
	_shop_panel.visible = not _shop_panel.visible
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


func _refresh_shop() -> void:
	for key in _shop_rows.keys():
		var row: Dictionary = _shop_rows[key]
		var meta := row.get("meta") as Label
		var button := row.get("button") as Button
		if meta == null or button == null:
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


func _on_device_changed(_device_key: String) -> void:
	_refresh_shop()


func _device_title(device_key: String) -> String:
	var catalog := GameManager.get_device_catalog()
	var data: Dictionary = catalog.get(device_key, {})
	return str(data.get("title", device_key.capitalize()))


func _device_capacity_text(device_key: String) -> String:
	if device_key == "truck":
		return "capacity %d" % GameManager.get_truck_capacity()
	return "slots %d" % GameManager.get_station_capacity(device_key)


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
