class_name LabShell
extends Control
## Landscape dashboard shell (mockup layout): header, lab view, sidebar, bottom panels.

const CYAN := Color(0.0, 0.86, 0.9)
const PANEL_BG := Color(0.015, 0.035, 0.045, 0.86)
const PANEL_BG_SOFT := Color(0.035, 0.065, 0.075, 0.78)
const PANEL_BORDER := Color(0.12, 0.38, 0.44, 0.72)
const TEXT_DIM := Color(0.68, 0.75, 0.78)

@onready var _header: HeaderBar = %HeaderBar
@onready var _sidebar: StationSidebar = %StationSidebar
@onready var _sample_queue: SampleQueuePanel = %SampleQueuePanel
@onready var _microscope_dock: MicroscopeDock = %MicroscopeDock
@onready var _escalation: EscalationPanel = %EscalationPanel
@onready var _lab_viewport: SubViewport = %LabViewport

var _shipping_status: Label = null
var _shipping_payout: Label = null
var _send_truck_button: Button = null


func _ready() -> void:
	add_to_group("lab_shell")
	_apply_reference_skin()
	_add_current_tasks_panel()
	_add_shipping_panel()
	GameManager.economy_changed.connect(_refresh_header)
	GameManager.shipping_changed.connect(_refresh_shipping)
	GameManager.layer_changed.connect(_on_layer_changed)
	GameManager.delivery_completed.connect(_on_delivery)
	GameManager.problem_inspection_requested.connect(_on_problem_inspection)
	GameManager.problem_inspection_resolved.connect(_on_problem_resolved)
	_refresh_header()
	_refresh_shipping()
	_on_layer_changed(GameManager.game_layer)
	set_hint("Tap the sample to start extraction.")


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
	add_theme_color_override("font_color", Color(0.94, 0.96, 0.96))
	var background := get_node_or_null("Background") as ColorRect
	if background:
		background.color = Color(0.0, 0.012, 0.018)
	_apply_panel_style(_header, Color(0.01, 0.025, 0.035, 0.82), PANEL_BORDER, 0, 1)
	_apply_panel_style(_sidebar, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_sample_queue, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_microscope_dock, PANEL_BG, PANEL_BORDER, 8, 1)
	_apply_panel_style(_escalation, PANEL_BG, PANEL_BORDER, 8, 1)
	var viewport_panel := get_node_or_null("VBox/MiddleRow/LabViewportContainer") as PanelContainer
	if viewport_panel:
		_apply_panel_style(viewport_panel, Color(0.0, 0.015, 0.02, 0.65), Color(0.08, 0.32, 0.36, 0.55), 4, 1)
	var bottom_nav := get_node_or_null("VBox/BottomNav") as PanelContainer
	if bottom_nav:
		_apply_panel_style(bottom_nav, Color(0.0, 0.018, 0.024, 0.94), Color(0.08, 0.24, 0.28, 0.8), 0, 1)
	_style_nav_buttons(bottom_nav)
	_style_labels(self)
	_style_progress_bars(self)
	_style_buttons(self)
	var title := Label.new()
	title.name = "BrandTitle"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = "CLEANLAB\nTECHNICAL CLEANLINESS SIMULATOR"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.94, 0.98, 0.98))
	title.position = Vector2(20, 9)
	title.size = Vector2(260, 56)
	add_child(title)


func _add_current_tasks_panel() -> void:
	var middle := get_node_or_null("VBox/MiddleRow") as HBoxContainer
	if middle == null or middle.has_node("CurrentTasksPanel"):
		return
	var panel := PanelContainer.new()
	panel.name = "CurrentTasksPanel"
	panel.custom_minimum_size = Vector2(190, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_panel_style(panel, PANEL_BG, PANEL_BORDER, 8, 1)
	middle.add_child(panel)
	middle.move_child(panel, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	margin.add_child(list)

	var title := Label.new()
	title.text = "CURRENT TASKS"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color.WHITE)
	list.add_child(title)

	_add_task_row(list, "EV BATTERY", "2 / 3", "$40")
	_add_task_row(list, "INJECTOR", "1 / 2", "$30")
	_add_task_row(list, "SENSOR", "0 / 1", "$20")


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
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	var truck := _build_truck_visual()
	vbox.add_child(truck)

	_shipping_status = Label.new()
	_shipping_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shipping_status.add_theme_font_size_override("font_size", 16)
	_shipping_status.add_theme_color_override("font_color", Color.WHITE)
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


func _add_task_row(list: VBoxContainer, title: String, count: String, bonus: String) -> void:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	_apply_panel_style(row, PANEL_BG_SOFT, Color(0.08, 0.2, 0.24, 0.8), 6, 1)
	list.add_child(row)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 9)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	var icon := ColorRect.new()
	icon.custom_minimum_size = Vector2(34, 34)
	icon.color = Color(0.72, 0.9, 0.95, 0.55)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = title
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	var count_label := Label.new()
	count_label.text = count
	count_label.add_theme_font_size_override("font_size", 15)
	count_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(count_label)

	var bonus_label := Label.new()
	bonus_label.text = bonus
	bonus_label.add_theme_font_size_override("font_size", 9)
	bonus_label.add_theme_color_override("font_color", CYAN)
	hbox.add_child(bonus_label)


func _build_truck_visual() -> Control:
	var truck := Control.new()
	truck.custom_minimum_size = Vector2(0, 68)
	truck.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var trailer := ColorRect.new()
	trailer.position = Vector2(48, 14)
	trailer.size = Vector2(126, 34)
	trailer.color = Color(0.76, 0.84, 0.87, 0.96)
	trailer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	truck.add_child(trailer)

	var cab := ColorRect.new()
	cab.position = Vector2(18, 25)
	cab.size = Vector2(42, 23)
	cab.color = Color(0.58, 0.7, 0.74, 0.98)
	cab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	truck.add_child(cab)

	var windshield := ColorRect.new()
	windshield.position = Vector2(27, 29)
	windshield.size = Vector2(18, 10)
	windshield.color = Color(0.02, 0.08, 0.1, 0.9)
	windshield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	truck.add_child(windshield)

	for x in [42.0, 136.0]:
		var wheel := ColorRect.new()
		wheel.position = Vector2(x, 50.0)
		wheel.size = Vector2(22, 10)
		wheel.color = Color(0.02, 0.025, 0.03, 1)
		wheel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		truck.add_child(wheel)

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
			bg.bg_color = Color(0.08, 0.1, 0.11, 0.95)
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
			button.add_theme_stylebox_override("normal", _button_style(Color(0.02, 0.06, 0.07, 0.9), PANEL_BORDER))
			button.add_theme_stylebox_override("hover", _button_style(Color(0.02, 0.12, 0.14, 0.96), CYAN))
			button.add_theme_stylebox_override("pressed", _button_style(Color(0.0, 0.35, 0.4, 0.96), CYAN))
			button.add_theme_color_override("font_color", Color(0.86, 0.88, 0.88))
			button.add_theme_color_override("font_hover_color", CYAN)
		_style_buttons(child)


func _style_nav_buttons(bottom_nav: PanelContainer) -> void:
	var lab_tab := bottom_nav.get_node_or_null("NavHBox/LabTab") as Button
	if lab_tab:
		lab_tab.add_theme_stylebox_override("normal", _button_style(Color(0.0, 0.17, 0.19, 0.94), CYAN))
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
	_shipping_status.text = "TRUCK READY\n%d / 3 REPORTS" % count
	_shipping_payout.text = "PAYMENT $ %s" % _format_money(GameManager.get_staged_report_total())
	_send_truck_button.disabled = count == 0


func _on_send_truck_pressed() -> void:
	var payout := GameManager.send_truck()
	if payout > 0:
		set_hint("Truck sent. Payment received: $%s." % _format_money(payout))
	else:
		set_hint("Stage a report at Reports Out first.")


func _format_money(amount: int) -> String:
	var s := str(amount)
	if s.length() <= 3:
		return s
	return "%s,%s" % [s.substr(0, s.length() - 3), s.substr(s.length() - 3)]
