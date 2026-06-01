class_name EscalationPanel
extends PanelContainer

var _body: Label
var _investigate_button: Button
var _defer_button: Button


func _ready() -> void:
	_ensure_ui()
	GameManager.escalation_queue_changed.connect(_refresh)
	GameManager.economy_changed.connect(_refresh)
	_refresh()


func _ensure_ui() -> void:
	_body = get_node_or_null("%BodyLabel") as Label
	if _body != null:
		_investigate_button = get_node_or_null("%InvestigateButton") as Button
		_defer_button = get_node_or_null("%DeferButton") as Button
	else:
		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 12)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 12)
		margin.add_theme_constant_override("margin_bottom", 10)
		add_child(margin)
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		margin.add_child(vbox)
		var title := Label.new()
		title.text = "Escalation Desk"
		title.add_theme_font_size_override("font_size", 14)
		vbox.add_child(title)
		_body = Label.new()
		_body.name = "BodyLabel"
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(_body)
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 6)
		vbox.add_child(actions)
		_investigate_button = Button.new()
		_investigate_button.name = "InvestigateButton"
		_investigate_button.text = "Investigate"
		actions.add_child(_investigate_button)
		_defer_button = Button.new()
		_defer_button.name = "DeferButton"
		_defer_button.text = "Defer"
		actions.add_child(_defer_button)
	if _investigate_button != null and not _investigate_button.pressed.is_connected(_on_investigate_pressed):
		_investigate_button.pressed.connect(_on_investigate_pressed)
	if _defer_button != null and not _defer_button.pressed.is_connected(_on_defer_pressed):
		_defer_button.pressed.connect(_on_defer_pressed)


func _refresh() -> void:
	if _body == null:
		return
	var next_ticket := GameManager.get_next_escalation_ticket()
	if next_ticket.is_empty():
		_body.text = "No active escalations.\nRisk %.0f%%" % [GameManager.escalation_risk * 100.0]
		if _investigate_button:
			_investigate_button.disabled = true
		if _defer_button:
			_defer_button.disabled = true
		return
	var ticket_count := GameManager.get_escalation_tickets().size()
	var template := "%s\nSeverity %d · Risk %.0f%%\nOpen tickets: %d"
	_body.text = template % [
		str(next_ticket.get("title", "Investigation required")),
		int(next_ticket.get("severity", 1)),
		GameManager.escalation_risk * 100.0,
		ticket_count,
	]
	if _investigate_button:
		_investigate_button.disabled = false
	if _defer_button:
		_defer_button.disabled = false


func _on_investigate_pressed() -> void:
	var resolved := GameManager.resolve_next_escalation(true)
	if resolved.is_empty():
		_set_hint("No escalation tickets.")
		return
	_set_hint("Escalation resolved: %s" % str(resolved.get("title", "Ticket")))
	_refresh()


func _on_defer_pressed() -> void:
	var resolved := GameManager.resolve_next_escalation(false)
	if resolved.is_empty():
		_set_hint("No escalation tickets.")
		return
	_set_hint("Escalation deferred: %s" % str(resolved.get("title", "Ticket")))
	_refresh()


func _set_hint(text: String) -> void:
	var shell := get_tree().get_first_node_in_group("lab_shell")
	if shell != null and shell.has_method("set_hint"):
		shell.call("set_hint", text)
