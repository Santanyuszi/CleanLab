class_name CleanLabGlassPanel
extends PanelContainer

@export_enum("glass", "solid") var variant := "glass":
	set(value):
		variant = value
		_apply_style()


func _ready() -> void:
	_apply_style()


func _apply_style() -> void:
	if not is_inside_tree():
		return
	var style := CleanLabTheme.glass_panel() if variant == "glass" else CleanLabTheme.solid_panel()
	add_theme_stylebox_override("panel", style)
